/*
    Module name: tb_counter
    Description: A testbench for the counter module
    (using default bit size of 4)
*/

`timescale 1ns/1ps


// PLAN OF ACTION: - set up all the correct inputs/outputs for the test bench : COMPLETE
//                   (including the memory. Ask Dhruv about 'text file to memory') : COMPLETE
//                 - set up the proper timing blocks, testing that a state change occurs exactly when we want it to for both HSYNC and VSYNC signal : COMPLETE
//                 - Make sure that data is only ever sent when both signals are in the active state : COMPLETE
//                 - If this true for an idle high data output, then change values in memory and see if the output is what we want : CURRENT TASK
//                 - could experience some time delay or reading information too early, in this case, 
//                   see what can be changed with the way we do the x-y coordinate math to account for timing error
//                 - after the timing errors have been resolved, the VGA should be use-ready





module tb_VGA_out(); 

    /////////////////////
    // Testbench Setup //
    /////////////////////

    // Loop variable
    integer i;
    integer j;
     
    // Define local parameters
 //   localparam CLK_PERIOD = 40; // 25 MHz 
    localparam CLK_PERIOD = 39.72194638; // 25 MHz 
    localparam RESET_ACTIVE = 0;
    localparam RESET_INACTIVE = 1;

    // Testbench Signals
    integer tb_test_num;
    string tb_test_name; 
    
    // DUT Inputs
    logic tb_clk;
    logic tb_nrst;
    logic [31:0] tb_SRAM_data_in;
    logic tb_SRAM_busy;

    // DUT Outputs
    logic [31:0] tb_word_address_dest;
    logic [3:0] tb_byte_select;
    logic [1:0] tb_VGA_state;
    logic tb_h_out;
    logic tb_v_out;
    logic tb_pixel_data;
    logic tb_data_en;
    logic [9:0] tb_h_count;
    logic [8:0] tb_v_count;
    logic [1:0] tb_h_state;
    logic [1:0] tb_v_state;

    // Expected values for checks
    logic tb_data_en_exp; 
    logic tb_pixel_data_exp; 
    logic tb_h_out_exp;
    logic tb_v_out_exp;
    logic [1:0] tb_VGA_state_exp;
    logic [31:0] tb_word_address_dest_exp;
    logic [9:0] tb_h_count_exp;
    logic [8:0] tb_v_count_exp;
    logic [1:0] tb_h_state_exp;
    logic [1:0] tb_v_state_exp;

    // Signal Dump
    initial begin
        $dumpfile ("dump.vcd");
        $dumpvars;
    end

    // 384 32-bit registers
    logic [31:0] memory [0:383];

    initial begin
        for (i = 0; i < 384; i = i + 1) begin
            if ((i & 32'b10) == 0) begin
                memory[i] = 32'h02468ACF;
            end else begin
                memory[i] = 32'hFCA86420;
            end
        end
    end


/*
    // Initialize the memory using $readmemb
    initial begin
        $readmemb("{memory_init.txt}\n", memory);
    end
        // How it will be used -->           pixel_data <= memory[mem_index][hbit];
*/

    ////////////////////////
    // Testbenching tasks //
    ////////////////////////

    // Quick reset for 2 clock cycles
    task reset_dut;
    begin
        @(negedge tb_clk); // synchronize to negedge edge so there are not hold or setup time violations
        
        // Activate reset
        tb_nrst = RESET_ACTIVE;

        // Wait 2 clock cycles
        @(negedge tb_clk);
        @(negedge tb_clk);

        // Deactivate reset
        tb_nrst = RESET_INACTIVE; 
    end
    endtask


    
    // Check output values against expected values
    task check_outputs;
        input logic tb_pixel_data_exp; 
        input logic [1:0] tb_VGA_state_exp; 
        input logic [9:0] tb_h_count_exp;
        input logic [8:0] tb_v_count_exp;
        input logic [1:0] tb_h_state_exp;
        input logic [1:0] tb_v_state_exp;
    begin
        @(negedge tb_clk);  // Check away from the clock edge!
        if(tb_pixel_data_exp == tb_pixel_data)
            $info("Correct pixel data value.");  
        else
            $error("Incorrect pixel data value. Actual: %0d, Expected: %0d.", tb_pixel_data, tb_pixel_data_exp);
        
        if(tb_VGA_state_exp == tb_VGA_state)
            $info("Correct VGA State value.");
        else
            $error("Incorrect VGA State value. Actual: %0d, Expected: %0d.", tb_VGA_state, tb_VGA_state_exp);

        if(tb_h_count_exp == tb_h_count)
            $info("Correct H Count value.");  
        else
            $error("Incorrect H Count value. Actual: %0d, Expected: %0d.", tb_h_count, tb_h_count_exp);

        if(tb_v_count_exp == tb_v_count)
            $info("Correct V Count value.");  
        else
            $error("Incorrect V Count value. Actual: %0d, Expected: %0d.", tb_v_count, tb_v_count_exp);

        if(tb_h_state_exp == tb_h_state)
            $info("Correct H State value.");  
        else
            $error("Incorrect H State value. Actual: %0d, Expected: %0d.", tb_h_state, tb_h_state_exp);

        if(tb_v_state_exp == tb_v_state)
            $info("Correct V State value.");  
        else
            $error("Incorrect V State value. Actual: %0d, Expected: %0d.", tb_v_state, tb_v_state_exp);

    end
    endtask 

    //////////
    // DUT //
    //////////

    // DUT Instance
    VGA_out DUT (
    .SRAM_data_in(tb_SRAM_data_in),
    .SRAM_busy(tb_SRAM_busy),
    .clk(tb_clk), 
    .nrst(tb_nrst),
    .data_en(tb_data_en), // Can be used for the read 
    .h_out(tb_h_out), 
    .v_out(tb_v_out), 
    .pixel_data(tb_pixel_data),
    .word_address_dest(tb_word_address_dest),
    .byte_select(tb_byte_select),
    .VGA_state(tb_VGA_state),
    .h_count(tb_h_count),
    .v_count(tb_v_count),
    .h_state(tb_h_state),
    .v_state(tb_v_state)
    );

    // Connecting wires to external memory 
    assign tb_SRAM_data_in = memory[tb_word_address_dest[8:0]];

    // Clock generation block
    always begin
        tb_clk = 0; // set clock initially to be 0 so that they are no time violations at the rising edge 
        #(CLK_PERIOD / 2);
        tb_clk = 1;
        #(CLK_PERIOD / 2);
    end

    initial begin

        // Initialize all test inputs
        tb_test_num = -1;  // We haven't started testing yet
        tb_test_name = "Test Bench Initialization";
        tb_nrst = RESET_INACTIVE;
        tb_SRAM_busy = 0;
        // Wait some time before starting first test case
        #(0.5);

        ////////////////////////////
        // Test 0: Power on reset //
        ////////////////////////////

        // NOTE: Do not use reset task during reset test case 
        tb_test_num+=1;
        tb_test_name = "Power on Reset";
        // Set inputs to non-reset values
        tb_SRAM_busy = 0;

        // Activate Reset
        tb_nrst = RESET_ACTIVE;

        #(CLK_PERIOD * 2); // Wait 2 clock periods before proceeding
        
        // Check outputs are reset
        tb_h_count_exp = 0; 
        tb_v_count_exp = 0;
        tb_pixel_data_exp = 0;
        tb_VGA_state_exp = 0;
        check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);

        // Deactivate Reset
        tb_nrst = RESET_INACTIVE;

        // Check outputs again
        tb_h_count_exp = 1; 
        tb_v_count_exp = 0;
        tb_pixel_data_exp = 0;
        tb_VGA_state_exp = 0;
        check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);

        //////////////////////////////////////////////////
        // Test 1: Test H State Change after SYNC count //
        //////////////////////////////////////////////////

        tb_test_num += 1; 
        tb_test_name = "New Test Case";
        reset_dut();



        //TESTING FOR H SYNC STATE
        for (i=0; i<96; i++) begin

            @(posedge tb_clk);
            tb_h_count_exp = i[9:0];
            check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);

        end

        @(posedge tb_clk);
        tb_h_count_exp = 0;
        check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);

        //TESTING FOR H FRONTPORCH STATE
        for (i=0; i<48; i++) begin

            @(posedge tb_clk);
            tb_h_count_exp = i[9:0];
            check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);

        end

        @(posedge tb_clk);
        tb_h_count_exp = 0;
        check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);

        //TESTING FOR H ACTIVE STATE
        for (i=0; i<640; i++) begin

            @(posedge tb_clk);
            tb_h_count_exp = i[9:0];
            check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);

        end

        @(posedge tb_clk);
        tb_h_count_exp = 0;
        check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);

        //TESTING FOR H BACKPORCH STATE
        for (i=0; i<16; i++) begin

            @(posedge tb_clk);
            tb_h_count_exp = i[9:0];
            check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);

        end

        @(posedge tb_clk);
        tb_h_count_exp = 0;
        tb_h_count_exp = 1;
        check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);


        //////////////////////////////////////////////////
        // Test 2: Test V State Change after SYNC count //
        //////////////////////////////////////////////////

        

        // TESTING FOR V SYNC STATE
        for (j=1; j<2; j++) begin
            for (i=0; i<800; i++) begin @(posedge tb_clk); end // Clock cycles to produce a horizontal line
            tb_v_count_exp = j[8:0];
            check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);
        end

        @(posedge tb_clk);
        tb_v_count_exp = 0;
        check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);

        // TESTING FOR V FRONTPORCH STATE
        for (j=0; j<33; j++) begin
            for (i=0; i<800; i++) begin @(posedge tb_clk); end // Clock cycles to produce a horizontal line
            tb_v_count_exp = j[8:0];
            check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);
        end

        @(posedge tb_clk);
        tb_v_count_exp = 0;
        check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);

        
        //////////////////////////////////////////////////
        // Test 3: Test for accurate pixel data output  //
        //////////////////////////////////////////////////


        // TESTING FOR V ACTIVE STATE
        for (j=1; j<480; j++) begin
            for (i=0; i<800; i++) begin @(posedge tb_clk); end // Clock cycles to produce a horizontal line
            tb_v_count_exp = j[8:0];
                if (i<144) begin
                    tb_pixel_data_exp = 0;
                end else if (i<784) begin
                    tb_pixel_data_exp = 1;
                end else begin
                    tb_pixel_data_exp = 0;
                end
            check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);
        end
        

        @(posedge tb_clk);
        tb_v_count_exp = 0;
        check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);

        // TESTING FOR V BACKPORCH STATE
        for (j=1; j<10; j++) begin
            for (i=0; i<800; i++) begin @(posedge tb_clk); end // Clock cycles to produce a horizontal line
            tb_v_count_exp = j[8:0];
            check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);
        end

        @(posedge tb_clk);
        tb_v_count_exp = 0;
        check_outputs(tb_pixel_data_exp, tb_VGA_state_exp, tb_h_count_exp, tb_v_count_exp, tb_h_state_exp, tb_v_state_exp);


        for (i=0; i<512000; i++) begin @(posedge tb_clk); end // Clock cycles to produce a horizontal line

        $finish;
    end


endmodule
