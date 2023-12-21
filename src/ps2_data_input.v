`default_nettype none
`ifndef __PS2_DATA_INPUT__
`define __PS2_DATA_INPUT__


module ps2_data_input (
    // Inputs
    input            clk,
    input            rst,
    input            start_receiving_data,
    input            ps2_clk_posedge,
    input            ps2_data,

    // Outputs
    output reg [7:0] ps2_received_data,
    output reg       ps2_received_data_strb
);


    // FSM-States
    localparam PS2_STATE_0_IDLE      = 3'h0,
               PS2_STATE_1_DATA_IN   = 3'h1,
               PS2_STATE_2_PARITY_IN = 3'h2,
               PS2_STATE_3_STOP_IN   = 3'h3;

    // Internal Registers
    reg [3:0] data_count;
    reg [7:0] data_shift_reg;
    reg [2:0] next_ps2_receiver_state;
    reg [2:0] ps2_receiver_state;


    always @(posedge clk) begin
        if (rst)
            ps2_receiver_state <= PS2_STATE_0_IDLE;
        else
            ps2_receiver_state <= next_ps2_receiver_state;
    end


    always @(*) begin
        next_ps2_receiver_state = PS2_STATE_0_IDLE;
        case (ps2_receiver_state)
            PS2_STATE_0_IDLE:
                begin
                    if (start_receiving_data && !ps2_received_data_strb)
                        next_ps2_receiver_state = PS2_STATE_1_DATA_IN;
                    else
                        next_ps2_receiver_state = PS2_STATE_0_IDLE;
                end
            PS2_STATE_1_DATA_IN:
                begin
                    if ((data_count == 4'h7) && ps2_clk_posedge)
                        next_ps2_receiver_state = PS2_STATE_2_PARITY_IN;
                    else
                        next_ps2_receiver_state = PS2_STATE_1_DATA_IN;
                end
            PS2_STATE_2_PARITY_IN:
                begin
                    if (ps2_clk_posedge)
                        next_ps2_receiver_state = PS2_STATE_3_STOP_IN;
                    else
                        next_ps2_receiver_state = PS2_STATE_2_PARITY_IN;
                end
            PS2_STATE_3_STOP_IN:
                begin
                    if (ps2_clk_posedge)
                        next_ps2_receiver_state = PS2_STATE_0_IDLE;
                    else
                        next_ps2_receiver_state = PS2_STATE_3_STOP_IN;
                end
            default:
                begin
                    next_ps2_receiver_state = PS2_STATE_0_IDLE;
                end
        endcase
    end


    always @(posedge clk) begin
        if (rst) 
            data_count <= 4'h0;
        else if ((ps2_receiver_state == PS2_STATE_1_DATA_IN) && ps2_clk_posedge)
            data_count <= data_count + 4'h1;
        else if (ps2_receiver_state != PS2_STATE_1_DATA_IN)
            data_count <= 4'h0;
    end


    always @(posedge clk) begin
        if (rst)
            data_shift_reg <= 8'h00;
        else if ((ps2_receiver_state == PS2_STATE_1_DATA_IN) && ps2_clk_posedge)
            data_shift_reg <= {ps2_data, data_shift_reg[7:1]};
    end


    always @(posedge clk) begin
        if (rst)
            ps2_received_data <= 8'h00;
        else if (ps2_receiver_state == PS2_STATE_3_STOP_IN)
            ps2_received_data <= data_shift_reg;
    end


    always @(posedge clk) begin
        if (rst)
            ps2_received_data_strb <= 1'b0;
        else if ((ps2_receiver_state == PS2_STATE_3_STOP_IN) && ps2_clk_posedge)
            ps2_received_data_strb <= 1'b1;
        else
            ps2_received_data_strb <= 1'b0;
    end
endmodule

`endif
`default_nettype wire

