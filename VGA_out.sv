//
//      VGA Output Module, outputs to VGA and send information to monitor
//



// [1:0]CURRENT CLIENT ----- FROM IO CONTROLLER DICTATING WHO HAS ACCESS TO WISHBONE AT A GIVEN TIME. CPU[0]/VGA[1]/UART[2]
// ADD IN AN OVERALL ENABLE WHEN THE VGA CLIENT IS SELECTED 

module VGA_out(
    input logic [31:0] SRAM_data_in,
    input logic SRAM_busy,
    input logic clk, nrst,
    output logic data_en, // Can be used for the read 
    output logic h_out, v_out, pixel_data,
    output logic [11:0] word_address_dest,
    output logic [3:0] byte_select,
    output logic [1:0] VGA_state // 0 = inactive, 1 = about to be active, 2 = active
);
    logic [8:0] word_address_offset;
    logic change_state_h, change_state_v, v_count_toggle;
    logic [9:0] h_count, h_next_count;
    logic [8:0] v_count, v_next_count;
    logic [8:0] h_offset;
    logic [8:0] v_offset;
    logic [4:0] x_coord;
    

    // Enum for H_STATES
    typedef enum logic [1:0] {
            h_sync = 2'b00,
            h_backporch =  2'b01,
            h_active = 2'b10,
            h_frontporch = 2'b11
    } h_mode; 

    // Enum for STATES
    typedef enum logic [1:0] {
            v_sync = 2'b00,
            v_backporch =  2'b01,
            v_active = 2'b10,
            v_frontporch = 2'b11
    } v_mode; 



    // Changes the VGA_State signal to notify 'Request Handler' the current active state of the VGA
    always_comb begin
        if (v_current_state == v_active) begin
            VGA_state = 2'b10;
        end else if ((v_current_state == v_backporch) & (v_count == 9'd32)) begin
            VGA_state = 2'b01;
        end else begin
            VGA_state = 2'b00;
        end
    end






    h_mode h_current_state, h_next_state;
    // HSYNC Counter
    always_ff @(posedge clk, negedge nrst) begin
        if (~nrst) begin
            h_current_state <= h_sync;
            h_count <= 0;
        end else begin
            h_current_state <= h_next_state;
            h_count <= h_next_count;
        end

    end

        v_mode v_current_state, v_next_state;
    // VSYNC Counter
    always_ff @(posedge clk, negedge nrst) begin
        if (~nrst) begin
            v_current_state <= v_sync;
            v_count <= 0;
        end else begin
            v_current_state <= v_next_state;
            v_count <= v_next_count;
        end
    end


    // HSYNC State Machine
    always_comb begin
        h_next_count = h_count;
        case (h_current_state) 
            h_sync: begin
                v_count_toggle = 0;
                if (h_count < 96) begin
                    h_next_count = h_next_count + 1'b1;
                    h_out = 0;
                    h_next_state = h_sync;
                end else begin
                    h_next_count = 0;
                    h_out = 1;
                    h_next_state = h_backporch;
                end
            end
            

            h_backporch: begin
                h_out = 1;
                v_count_toggle = 0;
                if (h_count < 48) begin
                    h_next_count = h_next_count + 1'b1;
                    h_next_state = h_backporch;
                end else begin
                    h_next_count = 0;
                    h_next_state = h_active;
                end
            end

            h_active: begin
                h_out = 1;
                v_count_toggle = 0;
                if (h_count < 640) begin
                    h_next_count = h_next_count + 1'b1;
                    h_next_state = h_active;
                end else begin
                    h_next_count = 0;
                    h_next_state = h_frontporch;
                end

            end

            h_frontporch: begin
                h_out = 1;
                if (h_count < 16) begin
                    h_next_count = h_next_count + 1'b1;
                    h_next_state = h_frontporch;
                    v_count_toggle = 0;
                end else begin
                    h_next_count = 0;
                    h_next_state = h_sync;
                    v_count_toggle = 1;
                end
            end
        endcase
    end



    // VSYNC State Machine
    always_comb begin
        v_next_count = v_count;
        if (v_count_toggle) begin
            v_next_count = v_next_count + 1'b1;
        end
        case (v_current_state) 
            h_sync: begin
                if (v_count < 2) begin
                    v_out = 0;
                    v_next_state = v_sync;
                end else begin
                    v_next_count = 0;
                    v_out = 1;
                    v_next_state = v_backporch;
                end
            end
            

            h_backporch: begin
                v_out = 1;
                if (v_count < 33) begin
                    v_next_state = v_backporch;
                end else begin
                    v_next_count = 0;
                    v_next_state = v_active;
                end
            end

            h_active: begin
                v_out = 1;
                if (v_count < 480) begin
                    v_next_state = v_active;
                end else begin
                    v_next_count = 0;
                    v_next_state = v_frontporch;
                end

            end

            h_frontporch: begin
                v_out = 1;
                if (v_count < 10) begin
                    v_next_state = v_frontporch;
                end else begin
                    v_next_count = 0;
                    v_next_state = v_sync;
                end
            end
        endcase
    end


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // WE CAN WORRY ABOUT HOW WE ARE GOING TO WORK WITH OUR TIMING TO MAKE SURE THAT OUR DATA BIT COMES WHEN WE WANT IT TO //
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    // IF BOTH STATES ARE ACTIVE AND THE COUNT IS WITHIN OUR DISPLAY DIMENSIONS, DATA TRANSACTION IS ENABLED
    always_comb begin
        if ((h_current_state == h_active) & (v_current_state == v_active) & (h_count < 128) & (v_count < 96)) begin
            data_en = 1;
        end else begin
            data_en = 0;
        end 
    end

    // BYTE SELECT TOGGLES ALL BYTES IF DATA TRANSACTION IS ENABLED, OTHERWISE IT NEVER REQUESTS ANY BITS  
    assign byte_select = {data_en, data_en, data_en, data_en};

    
    
    always_comb begin
        h_offset = {2'b00, h_count[6:0] / 7'd32};  // sets h offset to hcount / 32
        v_offset = 7'd4 * v_count[6:0];            // sets v offset to vcount * 4
        word_address_offset = h_offset + v_offset; // sets word offset to the total of h and v offsets
    end
    
    

//////IMPORTANT////////IMPORTANT/////IMPORTANT////WARNING/////WARNING/////////
//                                                                          //
//     //sets up the destination address in SRAM that we want to read from  //
//    always_comb begin                                                     //
//        word_address_dest = /*ADDRESS BASE*/ + word_address_offset;       //
//   end                                                                    //
//                                                                          //
//////IMPORTANT////////IMPORTANT/////IMPORTANT////WARNING/////WARNING/////////


    // setting up X coordinate logic for reading from our SRAM Bytes
    // the first 5 bits just loop after every multiple of 32
    assign x_coord = h_count[4:0];


    // Correct Pixel data only sends if enable and ~busy flag are toggled
    always_comb begin
        if (~SRAM_busy & data_en) begin
            pixel_data = SRAM_data_in[x_coord];
        end else begin
            pixel_data = 0;
        end
    end



endmodule