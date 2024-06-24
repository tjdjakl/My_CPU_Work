`default_nettype none
// Empty top module

module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);

  // Your code goes here...

  logic strobeZ;
  synckey skeyZ (
    .rst(reset),
    .clk(hz100),
    .in(pb[19]),
    .strobe(strobeZ)
  );
  assign left[7] = strobeZ;
  
  logic strobe0;
  synckey skey0 (
    .rst(reset),
    .clk(hz100),
    .in(pb[0]),
    .strobe(strobe0)
  );
  assign left[0] = strobe0;

  logic strobe1;
  synckey skey1 (
    .rst(reset),
    .clk(hz100),
    .in(pb[1]),
    .strobe(strobe1)
  );
  assign left[1] = strobe1;

  logic [7:0] data_out;
  logic data_ready;
  logic [8:0] working_data;
  logic [3:0] bits_received;
  logic receiving;
  UART_Receiver #(.BAUD_RATE(100), .CLOCK_FREQ(100)) UART(
    .nRst(~reset),
    .clk(strobeZ),
    .enable(1'b1),
    .Rx(strobe1),
    .data_out(data_out),
    .data_ready(data_ready),
    
    .working_data(working_data),
    .bits_received(bits_received),
    .receiving(receiving)
  );

  assign right[7:0] = data_out;
  assign red = receiving;
  ssdec ssdec0 (
    .in({3'b0, working_data[0]}),
    .enable(bits_received > 0),
    .out(ss0)
  );
  ssdec ssdec1 (
    .in({3'b0, working_data[1]}),
    .enable(bits_received > 1),
    .out(ss1)
  );
  ssdec ssdec2 (
    .in({3'b0, working_data[2]}),
    .enable(bits_received > 2),
    .out(ss2)
  );
  ssdec ssdec3 (
    .in({3'b0, working_data[3]}),
    .enable(bits_received > 3),
    .out(ss3)
  );
  ssdec ssdec4 (
    .in({3'b0, working_data[4]}),
    .enable(bits_received > 4),
    .out(ss4)
  );
  ssdec ssdec5 (
    .in({3'b0, working_data[5]}),
    .enable(bits_received > 5),
    .out(ss5)
  );
  ssdec ssdec6 (
    .in({3'b0, working_data[6]}),
    .enable(bits_received > 6),
    .out(ss6)
  );


  
  
endmodule

// Add more modules down here...

module ssdec (
  input logic [3:0] in,
  input logic enable,
  output logic [7:0] out
);

  always_comb begin

    case(enable)

    1'b0 : begin out = 8'b00000000; end
    1'b1 : begin
      case(in)
        4'b0000 : begin out = 8'b00111111; end //0
        4'b0001 : begin out = 8'b00000110; end //1
        4'b0010 : begin out = 8'b01011011; end //2
        4'b0011 : begin out = 8'b01001111; end //3

        4'b0100 : begin out = 8'b01100110; end //4
        4'b0101 : begin out = 8'b01101101; end //5
        4'b0110 : begin out = 8'b01111101; end //6
        4'b0111 : begin out = 8'b00000111; end //7

        4'b1000 : begin out = 8'b01111111; end //8
        4'b1001 : begin out = 8'b01100111; end //9
        4'b1010 : begin out = 8'b01110111; end //A
        4'b1011 : begin out = 8'b01111100; end //B
        
        4'b1100 : begin out = 8'b00111001; end //C
        4'b1101 : begin out = 8'b01011110; end //D
        4'b1110 : begin out = 8'b01111001; end //E
        4'b1111 : begin out = 8'b01110001; end //F

      endcase
    end

    endcase

  end

endmodule

module synckey ( //one button only
  input logic clk, rst,
  
  input logic in,
  output logic strobe
);

  logic middle;

  always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
      middle <= 0;
    end
    else begin
      middle <= in;
    end
  end

  always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
      strobe <= 0;
    end
    else begin
      strobe <= middle;
    end
  end

endmodule



typedef enum logic { 
  RESET = 1'b0,
  COUNTING = 1'b1
} BAUD_counter_state_t;


//////////////////////////////////
//  ADD PARITY BIT LOGIC LATER  //
//////////////////////////////////

module UART_Receiver #(
  parameter BAUD_RATE = 9600,
  parameter CLOCK_FREQ = 50000000,
  parameter CYCLES_PER_BIT = CLOCK_FREQ / BAUD_RATE //number of clock cycles per UART bit
) (
  input logic nRst, clk, enable, Rx,
  output logic [7:0] data_out,
  output logic data_ready, //flag is set to false only if data is being loaded into it

  output logic [8:0] working_data, //NOTE TO SELF: move back inside module    // This needs to be 9 bits long now to include 8 data bits + parity bit
  output logic [3:0] bits_received, //NOTE TO SELF: move back inside module   // 
  output logic receiving, //NOTE TO SELF: move back inside module


  //SET HERE FOR TESTBENCH SAKE//////////////////////////////////
  output logic [15:0] BAUD_counter, //NOTE TO SELF: figure out if this is an appropriate bus size
  output logic parity_error
);

  //
  //
  //  parity_error <= (^rx_shift[8:1]) != rx_shift[9]; // Parity error is high if the XOR of data_out
  //  parity error will affect data_ready and not allow data to be sent
  //  
  //
  
  //logic [6:0] working_data;
  //logic receiving;
  //logic [2:0] bits_received;
  // logic push_working_data;
  BAUD_counter_state_t BAUD_counter_state;
  //logic [15:0] BAUD_counter, //NOTE TO SELF: figure out if this is an appropriate bus size
  //logic parity_error                          ADDED TO TOPSET OUTPUT FOR TESTBENCH SAKE, REMOVE COMMENT TOGGLE WHEN ACTUAL IS UPON US

  

  always_ff @( posedge clk, negedge nRst ) begin //BAUD counter
    if (~nRst) begin
      BAUD_counter <= 0;
    end else begin
      if(BAUD_counter_state == RESET | BAUD_counter == CYCLES_PER_BIT) begin //NOTE TO SELF: this may have an extra cycle per bit, but it should be fine i think
        BAUD_counter <= 0;
      end else begin
        BAUD_counter <= BAUD_counter+1;
      end
    end
  end

  assign parity_error = ((^working_data[7:0]) != working_data[8]); // May not work idk, we will see when we try and run it. However, this is the accurate logic info for parity error

  always_ff @( posedge clk, negedge nRst ) begin //data loader
    if (~nRst) begin //reset
      data_out <= 8'b0;
      working_data <= 9'b0;
      receiving <= 1'b0;
      bits_received <= 4'b0;
      data_ready <= 1'b0;
      BAUD_counter_state <= RESET;

    end else begin

      if(enable) begin

        if (receiving) begin
          BAUD_counter_state <= COUNTING; 
          
          if(BAUD_counter == CYCLES_PER_BIT) begin //wait till clock cycle sync up with BAUD rate 

            if (bits_received == 4'd10) begin //last bit received, send data out
              
              if (~parity_error) begin
                data_out <= working_data[7:0]; // CHANGED TO THIS IN ORDER TO SEND OUT OUR 8 BITS OF USABLE DATA
                working_data <= working_data;  // I HAVE MY CONCERNS ON WHETHER OR NOT THIS IS PLAUSIBLE, CONSIDERING DATA_OUT IS ALSO BEING SET TO WORKING_DATA
                                       // I suggest leaving it as is and letting the reset state have its way with the working data
                receiving <= 1'b0;
                bits_received <= 4'b0;
                data_ready <= 1'b1; // Flags that data is ready to transfer
                BAUD_counter_state <= RESET; 

              end else begin
                data_out <= data_out; // CHANGED TO THIS IN ORDER TO SEND OUT OUR 8 BITS OF USABLE DATA
                working_data <= 9'b0;
                receiving <= 1'b0;
                bits_received <= 4'b0;
                data_ready <= 1'b0;
                BAUD_counter_state <= RESET; 
              end


            end else begin //not enough bits received 
              
              data_out <= data_out;
              working_data <= {Rx, working_data[8:1]};
              receiving <= 1'b1;
              bits_received <= (bits_received + 1);
              data_ready <= 1'b0;
              BAUD_counter_state <= COUNTING;
            end

          end else if ((BAUD_counter == (CYCLES_PER_BIT/2)) & (bits_received == 0))begin
            data_out <= data_out;
            working_data <= working_data;
            receiving <= 1'b1;
            bits_received <= bits_received + 1;
            data_ready <= 1'b0;
            BAUD_counter_state <= RESET;
          end

        end else begin //not receiving any information

          if(Rx == 1'b0) begin //start bit received

            data_out <= data_out;
            working_data <= 9'b0;
            receiving <= 1'b1;
            bits_received <= 4'b0;
            data_ready <= 1'b0;
            BAUD_counter_state <= COUNTING;

          end else begin //no start bit, keep waiting
            
            data_out <= data_out;
            working_data <= 9'b0;
            receiving <= 1'b0;
            bits_received <= 4'b0;
            data_ready <= 1'b0;
            BAUD_counter_state <= RESET;

          end

        end
        
      end else begin //if disabled, reset all values
        data_out <= 8'b0; // MAYBE WANT TO KEEP DATA OUT AS IS, THAT WAY THE REGISTER INFORMATION ISNT CHANGED BEFORE A NEW INPUT IS GIVEN
        working_data <= 9'b0;
        receiving <= 1'b0;
        bits_received <= 4'b0;
        data_ready <= 1'b0;
        BAUD_counter_state <= RESET;
      end

    end
  end

endmodule