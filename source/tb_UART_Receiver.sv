/*
    Module name: tb_counter
    Description: A testbench for the counter module
    (using default bit size of 4)
*/

`timescale 1ns/1ps


// PLAN OF ACTION: - set up all the correct inputs/outputs for the test bench : 
//                 - Get the timing windows set up properly to get each new bit : 
//                 - Test Set up multiple Tests. One with all 1's, one with all 0's, one with start and finish 0 with rest 1, and one vice versa : 






module tb_UART_Reciever(); 

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
    logic tb_Rx;

    // DUT Outputs
    logic [8:0] tb_working_data;
    logic [3:0] tb_bits_received;
    logic tb_receiving;
    logic [7:0] tb_data_out;
    logic tb_data_ready;    
    logic [15:0] tb_BAUD_counter; //NOTE TO SELF: figure out if this is an appropriate bus size
    logic tb_parity_error;

    // Expected values for checks
    logic [8:0] tb_working_data_exp;
    logic [3:0] tb_bits_received_exp;
    logic tb_receiving_exp;
    logic [7:0] tb_data_out_exp;
    logic tb_data_ready_exp;    

    // Signal Dump
    initial begin
        $dumpfile ("dump.vcd");
        $dumpvars;
    end


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
        input logic [8:0] tb_working_data_exp;
        input logic [3:0] tb_bits_received_exp;
        input logic tb_receiving_exp;
        input logic [7:0] tb_data_out_exp;
        input logic tb_data_ready_exp;   
    begin
        @(negedge tb_clk);  // Check away from the clock edge!
        if(tb_working_data_exp == tb_working_data)
            $info("Correct WORKING DATA value.");  
        else
            $error("Incorrect WORKING DATA value. Actual: %0d, Expected: %0d.", tb_working_data, tb_working_data_exp);
        
        if(tb_bits_received_exp == tb_bits_received)
            $info("Correct BITS RECEIVED value.");
        else
            $error("Incorrect BITS RECEIVED value. Actual: %0d, Expected: %0d.", tb_bits_received, tb_bits_received_exp);

        if(tb_receiving_exp == tb_receiving)
            $info("Correct RECEIVING value.");
        else
            $error("Incorrect RECEIVING value. Actual: %0d, Expected: %0d.", tb_receiving, tb_receiving_exp);

        if(tb_data_out_exp == tb_data_out)
            $info("Correct DATA OUT value.");
        else
            $error("Incorrect DATA OUT value. Actual: %0d, Expected: %0d.", tb_data_out, tb_data_out_exp);

        if(tb_data_ready_exp == tb_data_ready)
            $info("Correct DATA READY value.");
        else
            $error("Incorrect DATA READY value. Actual: %0d, Expected: %0d.", tb_data_ready, tb_data_ready_exp);

    end
    endtask 

    //////////
    // DUT //
    //////////

    // DUT Instance
    UART_Receiver #(.BAUD_RATE(9600), .CLOCK_FREQ(50000000)) UART(
    .nRst(tb_nrst),
    .clk(tb_clk),
    .enable(1'b1),
    .Rx(tb_Rx),
    .data_out(tb_data_out),
    .data_ready(tb_data_ready),
    
    .working_data(tb_working_data),
    .bits_received(tb_bits_received),
    .receiving(tb_receiving),
    .BAUD_counter(tb_BAUD_counter), //NOTE TO SELF: figure out if this is an appropriate bus size
    .parity_error(tb_parity_error)
  );
//

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
        tb_Rx = 1;
        // Wait some time before starting first test case
        #(0.5);

        ////////////////////////////
        // Test 0: Power on reset //
        ////////////////////////////

        // NOTE: Do not use reset task during reset test case 
        tb_test_num+=1;
        tb_test_name = "Power on Reset";
        // Set inputs to non-reset values

        // Activate Reset
        tb_nrst = RESET_ACTIVE;

        #(CLK_PERIOD * 2); // Wait 2 clock periods before proceeding
        
        // Check outputs are reset


        check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);

        // Deactivate Reset
        tb_nrst = RESET_INACTIVE;

        // Check outputs again


        check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);

        //////////////////////////////////////////////////
        //       Test 1: Test recieving all 1's         //
        //////////////////////////////////////////////////

        tb_test_num += 1; 
        tb_test_name = "New Test Case";
        reset_dut();



        //TESTING FOR NO RECEIVE FLAG
        for (i=0; i<9600; i++) begin

            @(posedge tb_clk);
            tb_receiving_exp = 0;
            check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);

        end

        tb_Rx = 0;

        @(posedge tb_clk);
        tb_receiving_exp = 1;
        check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);

        //TESTING FOR RECIEIVING CORRECT BITS, start bit
        for (i=0; i<2604; i++) begin
            @(posedge tb_clk);
            tb_Rx = 0;
            check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);
        end


        //TESTING FOR RECIEIVING CORRECT BITS, 1 bit shifted in
        for (i=0; i<5208; i++) begin
            @(posedge tb_clk);
            if (i==2604) begin
                tb_Rx = 1;
            end
            check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);
        end

        //TESTING FOR RECIEIVING CORRECT BITS, 2 bit shifted in
        for (i=0; i<5208; i++) begin
            @(posedge tb_clk);
            if (i==2604) begin
                tb_Rx = 0;
            end
            check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);
        end

        //TESTING FOR RECIEIVING CORRECT BITS, 3 bit shifted in
        for (i=0; i<5208; i++) begin
            @(posedge tb_clk);
            if (i==2604) begin
                tb_Rx = 0;
            end
            check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);
        end

        //TESTING FOR RECIEIVING CORRECT BITS, 4 bit shifted in
        for (i=0; i<5208; i++) begin
            @(posedge tb_clk);
            if (i==2604) begin
                tb_Rx = 0;
            end
            check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);
        end

        //TESTING FOR RECIEIVING CORRECT BITS, 5 bit shifted in
        for (i=0; i<5208; i++) begin
            @(posedge tb_clk);
            if (i==2604) begin
                tb_Rx = 1;
            end
            check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);
        end

        //TESTING FOR RECIEIVING CORRECT BITS, 6 bit shifted in
        for (i=0; i<5208; i++) begin
            @(posedge tb_clk);
            if (i==2604) begin
                tb_Rx = 1;
            end
            check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);
        end

        //TESTING FOR RECIEIVING CORRECT BITS, 7 bit shifted in
        for (i=0; i<5208; i++) begin
            @(posedge tb_clk);
            if (i==2604) begin
                tb_Rx = 0;
            end
            check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);
        end

        //TESTING FOR RECIEIVING CORRECT BITS, 8 bit shifted in
        for (i=0; i<5208; i++) begin
            @(posedge tb_clk);
            if (i==2604) begin
                tb_Rx = 1;
            end
            check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);
        end

        //TESTING FOR RECIEIVING CORRECT BITS, parity bit shifted in
        for (i=0; i<5208; i++) begin
            @(posedge tb_clk);
            if (i==2604) begin
                tb_Rx = 0;
            end
            check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);
        end

        // Returning Rx to IDLE state
        for (i=0; i<5208; i++) begin
            @(posedge tb_clk);
            if (i==2604) begin
                tb_Rx = 1;
            end
            check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);
        end


        //TESTING FOR RETURN TO IDLE STATE
        for (i=0; i<9600; i++) begin

            @(posedge tb_clk);
            tb_receiving_exp = 0;
            check_outputs(tb_working_data_exp, tb_bits_received_exp, tb_receiving_exp, tb_data_out_exp, tb_data_ready_exp);

        end


        //////////////////////////////////////////////////
        // Test 2: Test V State Change after SYNC count //
        //////////////////////////////////////////////////

        
        
        //////////////////////////////////////////////////
        // Test 3: Test for accurate pixel data output  //
        //////////////////////////////////////////////////




        $finish;
    end


endmodule
