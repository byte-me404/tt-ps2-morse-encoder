`timescale 1ns / 1ns

`include "ps2_data_input.v"
`include "ps2_controller.v"
`include "morse_code_encoder.v"
`include "tone_generator.v"


module tb_custom_tests;

    reg         clk = 1'b0;
    reg         rst = 1'b1;
    
    wire        ps2_clk;
    wire        ps2_data;
    reg 		ps2_clk_tmp  = 1'b0;
    reg			ps2_data_tmp = 1'b0;
    
    wire [7:0] ps2_received_data;
    wire       ps2_received_data_strb;
    
    wire	   dit_out;
    wire       dah_out;
    wire       morse_code_out;
    
    
    // DUT
    ps2_controller ps2_controller_DUT (
        // Inputs
        .clk(clk),
        .rst(rst),
        
        // Bidirectionals
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        
        // Outputs
        .ps2_received_data(ps2_received_data),
        .ps2_received_data_strb(ps2_received_data_strb)
    );

    morse_code_encoder morse_code_encoder_DUT (
        // Inputs
        .clk(clk),
        .rst(rst),
        .ps2_received_data(ps2_received_data),
        .ps2_received_data_strb(ps2_received_data_strb),
        
        // Outputs
        .dit_out(dit_out),
        .dah_out(dah_out)
    );

    tone_generator tone_generator_DUT (
        // Inputs
        .clk(clk),
        .rst(rst),
        .dit(dit_out),
        .dah(dah_out),
        
        // Outputs
        .tone_out(morse_code_out)
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
