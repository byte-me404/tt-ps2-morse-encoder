`timescale 1ns / 1ns

`include "ps2_data_input.v"
`include "ps2_controller.v"
`include "data_control.v"


module tb_ps2_controller;

    reg        clk = 1'b0;
    reg        rst = 1'b1;
    
    wire        ps2_clk;
    wire        ps2_data;
    reg 		ps2_clk_tmp  = 1'b0;
    reg			ps2_data_tmp = 1'b0;
    
    wire [7:0] test_received_data;
    wire       test_received_data_strb;
    
    wire	   test_dit_out;
    wire       test_dah_out;
    wire       test_morse_code_out;
    
    parameter  BUFFER_LENGTH = 10;

    
    // DUT
    ps2_controller ps2_controller_DUT (
        // Inputs
        .clk(clk),
        .rst(rst),
        
        // Bidirectionals
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        
        // Outputs
        .ps2_received_data(test_received_data),
        .ps2_received_data_strb(test_received_data_strb)
    );

    data_control #(BUFFER_LENGTH) data_control_DUT (
        // Inputs
        .clk(clk),
        .rst(rst),
        .ps2_received_data(test_received_data),
        .ps2_received_data_strb(test_received_data_strb),
        
        // Outputs
        .dit_out(test_dit_out),
        .dah_out(test_dah_out),
        .morse_code_out(test_morse_code_out)
    );

    /* verilator lint_off STMTDLY */
    always #10 clk = ~clk;                      // System-Clock 50MHz
    always #40000 ps2_clk_tmp = ~ps2_clk_tmp;   // Simulated PS/2 Clock 12kHz
    /* verilator lint_on STMTDLY */
    
    assign ps2_controller_DUT.ps2_clk = ps2_clk_tmp;
    assign ps2_controller_DUT.ps2_data = ps2_data_tmp;
    
    initial begin
        $dumpfile("tb_ps2_controller.vcd");
        $dumpvars;
        
        /* verilator lint_off STMTDLY */
        #50 rst = 1'b0;
        
        // h1C (A) from Device to Host
        #619900 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h29 (Space) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h32 (B) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h1C (A) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h21 (Break-Code) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h21 (C) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h1C (A) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h29 (Space) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h32 (B) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h1C (A) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h1C (A) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h29 (Space) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h32 (B) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h1C (A) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h21 (C) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h1C (A) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h29 (Space) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h32 (B) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h1C (A) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h5A (Enter) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        
        
        
        // h1C (A) from Device to Host
        #60000000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h32 (B) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h21 (C) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h21 (F4) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        // h29 (Space) from Device to Host
        #640000 ps2_data_tmp  = 1'b0;   // Start-Bit
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b1;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;
        #80000  ps2_data_tmp  = 1'b0;    // Parity-Bit
        #80000  ps2_data_tmp  = 1'b1;
        
        #40000000 $finish;
        /* verilator lint_on STMTDLY */
    end
endmodule
