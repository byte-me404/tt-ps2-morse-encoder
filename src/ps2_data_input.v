`default_nettype none


module ps2_data_input (
    // Inputs
    input        clk,
    input        rst,
    input        start_receiving_data,
    input        ps2_clk_posedge,
    input        ps2_data,

    // Outputs
    output [7:0] ps2_received_data,
    output       ps2_received_data_strb
);

    // Internal registers
    reg [3:0] data_count;
    reg [3:0] next_data_count;
    reg [7:0] data_shift_reg;
    reg [7:0] next_data_shift_reg;
    reg [7:0] received_data;
    reg [7:0] next_received_data;
    reg [2:0] receiver_state;
    reg [2:0] next_receiver_state;
    reg       received_data_strb;
    reg       next_received_data_strb;

    // FSM-States
    localparam PS2_STATE_0_IDLE      = 3'h0,
               PS2_STATE_1_DATA_IN   = 3'h1,
               PS2_STATE_2_PARITY_IN = 3'h2,
               PS2_STATE_3_STOP_IN   = 3'h3;

    // Register process
    always @(posedge clk) begin
        if (rst) begin
            receiver_state     <= PS2_STATE_0_IDLE;
            data_count         <= 4'h0;
            data_shift_reg     <= 8'h00;
            received_data      <= 8'h00;
            received_data_strb <= 1'b0;
        end else begin
            receiver_state     <= next_receiver_state;
            data_count         <= next_data_count;
            data_shift_reg     <= next_data_shift_reg;
            received_data      <= next_received_data;
            received_data_strb <= next_received_data_strb;
        end
    end

    // Sequential logic
    always @(*) begin
        // Default assignment
        next_receiver_state     = PS2_STATE_0_IDLE;
        next_data_count         = data_count;
        next_data_shift_reg     = data_shift_reg;
        next_received_data      = received_data;
        next_received_data_strb = received_data_strb;

        // FSM
        case (receiver_state)
            PS2_STATE_0_IDLE:
                begin
                    if (start_receiving_data && !received_data_strb)
                        next_receiver_state = PS2_STATE_1_DATA_IN;
                    else
                        next_receiver_state = PS2_STATE_0_IDLE;
                end
            PS2_STATE_1_DATA_IN:
                begin
                    if (ps2_clk_posedge) begin
                        if (data_count == 4'h7) begin
                            next_data_count = 4'h0;
                            next_receiver_state = PS2_STATE_2_PARITY_IN;
                        end else
                            next_data_count = data_count + 4'h1;
                            next_data_shift_reg = {ps2_data, data_shift_reg[7:1]};
                    end else
                        next_receiver_state = PS2_STATE_1_DATA_IN;
                end
            PS2_STATE_2_PARITY_IN:
                begin
                    if (ps2_clk_posedge)
                        next_receiver_state = PS2_STATE_3_STOP_IN;
                    else
                        next_receiver_state = PS2_STATE_2_PARITY_IN;
                end
            PS2_STATE_3_STOP_IN:
                begin
                    if (ps2_clk_posedge) begin
                        next_receiver_state = PS2_STATE_0_IDLE;
                        next_received_data_strb = 1'b1;
                    end else begin
                        next_receiver_state = PS2_STATE_3_STOP_IN;
                        next_received_data_strb = 1'b0;
                    end
                    next_received_data = data_shift_reg;
                end
            default:
                begin
                    next_receiver_state = PS2_STATE_0_IDLE;
                end
        endcase
    end

    // Combinatoric logic
    assign ps2_received_data      = received_data;
    assign ps2_received_data_strb = received_data_strb;
    
endmodule
