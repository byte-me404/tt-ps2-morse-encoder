`default_nettype none


module tt_um_ps2_morse_decoder #( parameter MAX_COUNT = 24'd10_000_000 ) (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire reset =! rst_n;
	wire [7:0] test_received_data;
    wire       test_received_data_strb;
    
    
    // DUT
    ps2_controller ps2_controller_DUT (
        // Inputs
        .clk(clk),
        .rst(reset),
        
        // Bidirectionals
        .ps2_clk(uio_in[0]),
        .ps2_data(uio_in[0]),
        
        // Outputs
        .ps2_received_data(test_received_data),
        .ps2_received_data_strb(test_received_data_strb)
    );

    data_control #(BUFFER_LENGTH) data_control_DUT (
        // Inputs
        .clk(clk),
        .rst(reset),
        .ps2_received_data(test_received_data),
        .ps2_received_data_strb(test_received_data_strb),
        
        // Outputs
        .morse_code_out(uo_out[0])
    );
endmodule
