/* 
    Copyright 2024 Daniel Baumgartner

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE−2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

/*
 * Module: tb_custom_tests
 * Description:
        Custom testbench.
*/

`timescale 1ns / 1ns

// Include other modules
`include "ps2_controller.v"
`include "morse_code_encoder.v"
`include "tone_generator.v"

module tb_custom_tests;

    // Internal registers
    reg         clk = 1'b0;
    reg         rst = 1'b1;
    reg 		ps2_clk_tmp  = 1'b0;
    reg			ps2_data_tmp = 1'b1;    

    // Internal wires
    wire        ps2_clk;
    wire        ps2_data;
    wire [7:0] ps2_received_data;
    wire       ps2_received_data_strb;
    wire	   dit_out;
    wire       dah_out;
    wire       morse_code_out;
    wire       morse_tone_out;

    // Connect modules
    ps2_controller ps2_controller_DUT (
        // Inputs
        .clk(clk),
        .rst(rst),
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
        .dah_out(dah_out),
        .morse_code_out(morse_code_out)
    );

    tone_generator tone_generator_DUT (
        // Inputs
        .clk(clk),
        .rst(rst),
        .dit(dit_out),
        .dah(dah_out),

        // Outputs
        .tone_out(morse_tone_out)
    );

    /* verilator lint_off STMTDLY */
    always #10 clk = ~clk;                      // System-Clock 50 MHz
    always #40000 ps2_clk_tmp = ~ps2_clk_tmp;   // Simulated PS/2 clock 12kHz
    /* verilator lint_on STMTDLY */

    // Assign PS/2 clock and data
    assign ps2_controller_DUT.ps2_clk = ps2_clk_tmp;
    assign ps2_controller_DUT.ps2_data = ps2_data_tmp;

    initial begin
        $dumpfile("tb_ps2_controller.vcd");
        $dumpvars;

        /* verilator lint_off STMTDLY */
        #50 rst = 1'b0;

        // Simulate PS/2 data
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

        // hF0 (Break-Code) from Device to Host
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

        // h0C (F4) from Device to Host
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
