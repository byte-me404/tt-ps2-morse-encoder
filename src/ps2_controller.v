`default_nettype none


module ps2_controller (
    // Inputs
    input        clk,
    input        rst,
    input        ps2_clk,
    input        ps2_data,

    // Outputs
    output [7:0] ps2_received_data,
    output       ps2_received_data_strb
);


    // FSM-States
    localparam PS2_STATE_0_IDLE    = 1'b0,
               PS2_STATE_1_DATA_IN = 1'b1;

    // Internal Wires
    wire ps2_clk_posedge;
    wire start_receiving_data;

    // Internal Registers
    reg  ps2_clk_reg;
    reg  ps2_data_reg;
    reg  last_ps2_clk;
    reg	 ps2_state;
    reg	 next_ps2_state;


    always @(posedge clk) begin
        if (rst)
            ps2_state <= PS2_STATE_0_IDLE;
        else
            ps2_state <= next_ps2_state;
    end


    always @(*) begin
        next_ps2_state = PS2_STATE_0_IDLE;
        case (ps2_state)
            PS2_STATE_0_IDLE:
                begin
                    if (!ps2_data_reg && ps2_clk_posedge)
                        next_ps2_state = PS2_STATE_1_DATA_IN;
                    else
                        next_ps2_state = PS2_STATE_0_IDLE;
                end
            PS2_STATE_1_DATA_IN:
                begin
                    if (ps2_received_data_strb)
                        next_ps2_state = PS2_STATE_0_IDLE;
                    else
                        next_ps2_state = PS2_STATE_1_DATA_IN;
                end
            default:
                    next_ps2_state = PS2_STATE_0_IDLE;
        endcase
    end


    always @(posedge clk) begin
        if (rst)
            begin
                last_ps2_clk <= 1'b1;
                ps2_clk_reg  <= 1'b1;
                ps2_data_reg <= 1'b1;
            end
        else
            begin
                last_ps2_clk <= ps2_clk_reg;
                ps2_clk_reg  <= ps2_clk;
                ps2_data_reg <= ps2_data;
            end
    end



    // Combinational logic
    assign ps2_clk_posedge      = (ps2_clk_reg && !last_ps2_clk) ? 1'b1 : 1'b0;
    assign start_receiving_data = (ps2_state == PS2_STATE_1_DATA_IN);


    ps2_data_input ps2_data_in (
        // Inputs
        .clk                    (clk),
        .rst                    (rst),
        .start_receiving_data   (start_receiving_data),
        .ps2_clk_posedge        (ps2_clk_posedge),
        .ps2_data               (ps2_data_reg),

        // Outputs
        .ps2_received_data      (ps2_received_data),
        .ps2_received_data_strb (ps2_received_data_strb)
    );
endmodule

