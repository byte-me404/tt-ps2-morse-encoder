`default_nettype none


module tt_um_ps2_morse_encoder_top (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire       reset =! rst_n;
	wire [7:0] ps2_received_data;
    wire       ps2_received_data_strb;
    

    assign uo_out[1] = 1'b0;
    assign uo_out[2] = 1'b0;
    assign uo_out[4] = 1'b0;
    assign uo_out[5] = 1'b0;

    assign uio_oe[7:0]  = 8'b11111111;
    assign uio_out[7:0] = 8'b11111111;
    
    // DUT
    ps2_controller ps2_controller (
        // Inputs
        .clk(clk),
        .rst(reset),
        
        // Bidirectionals
        .ps2_clk(ui_in[0]),
        .ps2_data(ui_in[1]),
        
        // Outputs
        .ps2_received_data(ps2_received_data),
        .ps2_received_data_strb(ps2_received_data_strb)
    );

    morse_code_encoder morse_code_encoder (
        // Inputs
        .clk(clk),
        .rst(reset),
        .ps2_received_data(ps2_received_data),
        .ps2_received_data_strb(ps2_received_data_strb),
        
        // Outputs
        .dit_out(uo_out[0]),
        .dah_out(uo_out[3]),
        .morse_code_out(uo_out[6])
    );

    tone_generator tone_generator (
        // Inputs
        .clk(clk),
        .rst(reset),
        .dit(uo_out[0]),
        .dah(uo_out[3]),
        
        // Outputs
        .tone_out(uo_out[7])
    );
endmodule
