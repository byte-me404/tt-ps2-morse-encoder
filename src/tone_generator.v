`default_nettype none


module tone_generator (
    // Inputs
    input  clk,
    input  rst,
    input  dit,
    input  dah,

    // Output
    output tone_out
);

    // Local Parameters
    localparam SIZE_COUNTER = 17;
    localparam MAX_COUNT    = 17'h14585;     // 600Hz with 50MHz Clock

    // Internal Registers
    reg [SIZE_COUNTER-1:0] counter;
    reg [SIZE_COUNTER-1:0] next_counter;

    reg tone_output;
    reg next_tone_output;
    

    always @(posedge clk) begin
        if (rst) begin
            counter     <= {SIZE_COUNTER{1'b0}};
            tone_output <= 1'b0;
        end else begin
            counter     <= next_counter;
            tone_output <= next_tone_output;
        end
    end


    always @(*) begin
        if (dit || dah) begin
            if (counter == MAX_COUNT) begin
                next_tone_output = ~tone_output;
                next_counter = {SIZE_COUNTER{1'b0}};
            end else begin
                next_counter = counter + {{(SIZE_COUNTER-1){1'b0}}, 1'b1};
                next_tone_output = tone_output;
            end
        end else begin
            next_counter     = {SIZE_COUNTER{1'b0}};
            next_tone_output = 1'b0;
        end
    end
    
    assign tone_out = tone_output;
    
endmodule
