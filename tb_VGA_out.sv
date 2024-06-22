/*
    Module name: tb_counter
    Description: A testbench for the counter module
    (using default bit size of 4)
*/

`timescale 1ns/1ps


// PLAN OF ACTION: - set up all the correct inputs/outputs for the test bench : COMPLETE
//                   (including the memory. Ask Dhruv about 'text file to memory') : 
//                 - set up the proper timing blocks, testing that a state change occurs exactly when we want it to for both HSYNC and VSYNC signal
//                 - Make sure that data is only ever sent when both signals are in the active state
//                 - If this true for an idle high data output, then change values in memory and see if the output is what we want
//                 - could experience some time delay or reading information too early, in this case, 
//                   see what can be changed with the way we do the x-y coordinate math to account for timing error
//                 - after the timing errors have been resolved, the VGA should be use-ready





module tb_VGA_out(); 

    /////////////////////
    // Testbench Setup //
    /////////////////////

    // Loop variable
    integer i;
     
    // Define local parameters
    localparam CLK_PERIOD = 40; // 25 MHz 
    localparam RESET_ACTIVE = 0;
    localparam RESET_INACTIVE = 1;

    // Testbench Signals
    integer tb_test_num;
    string tb_test_name; 
    
    // DUT Inputs
    logic tb_clk;
    logic tb_nrst;
    logic tb_SRAM_data_in;
    logic tb_SRAM_busy;

    // DUT Outputs
    logic tb_word_address_dest;
    logic tb_byte_select;
    logic tb_VGA_state;
    logic tb_h_out;
    logic tb_v_out;
    logic tb_pixel_data;
    logic tb_data_en;

    // Expected values for checks
    logic tb_data_en_exp; 
    logic tb_pixel_data_exp; 
    logic tb_h_out_exp;
    logic tb_v_out_exp;
    logic tb_VGA_state_exp;
    logic tb_word_address_dest_exp;

    // Signal Dump
    initial begin
        $dumpfile ("dump.vcd");
        $dumpvars;
    end

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
        input logic exp_count; 
        input logic exp_at_max; 
    begin
        @(negedge tb_clk);  // Check away from the clock edge!
        if(exp_count == tb_count)
            $info("Correct tb_count value.");  
        else
            $error("Incorrect tb_count value. Actual: %0d, Expected: %0d.", tb_count, exp_count);
        
        if(exp_at_max == tb_at_max)
            $info("Correct tb_at_max value.");
        else
            $error("Incorrect tb_at_max value. Actual: %0d, Expected: %0d.", tb_at_max, exp_at_max);

    end
    endtask 

    //////////
    // DUT //
    //////////

    // DUT Instance
    VGA_out DUT (
    .SRAM_data_in(),
    .SRAM_busy(),
    .clk(), .nrst(),
    .data_en(), // Can be used for the read 
    .h_out(), .v_out(), .pixel_data(),
    .word_address_dest(),
    .byte_select(),
    .VGA_state()
    );

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
        tb_enable = 0;
        tb_clear = 0;
        tb_wrap = 0;
        tb_max = 0;
        // Wait some time before starting first test case
        #(0.5);

        ////////////////////////////
        // Test 0: Power on reset //
        ////////////////////////////

        // NOTE: Do not use reset task during reset test case 
        tb_test_num+=1;
        tb_test_name = "Power on Reset";
        // Set inputs to non-reset values
        tb_enable = 1;
        tb_clear = 0;
        tb_wrap = 1;
        tb_max = '1;

        // Activate Reset
        tb_nrst = RESET_ACTIVE;

        #(CLK_PERIOD * 2); // Wait 2 clock periods before proceeding
        
        // Check outputs are reset
        tb_count_exp = 0; 
        tb_at_max_exp = 0;
        check_outputs(tb_count_exp, tb_at_max_exp);

        // Deactivate Reset
        tb_nrst = RESET_INACTIVE;

        // Check outputs again
        tb_count_exp = 1;  // because enable is high
        tb_at_max_exp = 0;
        check_outputs(tb_count_exp, tb_at_max_exp);

        //////////////////////////////////////
        // Test 1: Test Continuous Counting //
        //////////////////////////////////////

        tb_test_num += 1; 
        tb_test_name = "New Test Case";
        reset_dut();

        // Set inputs
        tb_wrap = 1'b1; 
        tb_enable = 1'b1;


        for (i=0; i<20; i++) begin

            @(posedge tb_clk);
            check_outputs(tb_count_exp, tb_at_max_exp);

        end

        @(negedge tb_clk);
        tb_clear = 1;
        @(negedge tb_clk);
        tb_clear = 0;
        check_outputs(tb_count_exp, tb_at_max_exp);
        tb_wrap = 0;

        for (i=0; i<20; i++) begin

            if ((i < 10) & (i > 5)) begin
                tb_enable = 0;
                @(posedge tb_clk);
                check_outputs(tb_count_exp, tb_at_max_exp);
            end
            else begin
                tb_enable = 1;
                @(posedge tb_clk);
                check_outputs(tb_count_exp, tb_at_max_exp);
            end

        end

        $finish;
    end


endmodule
