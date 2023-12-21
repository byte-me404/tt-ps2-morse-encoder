`default_nettype none
`ifndef __DATA_CONTROLLER__
`define __DATA_CONTROLLER__


module data_control #(parameter BUFFER_LENGTH = 16) (
    // Inputs
    input       clk,
    input       rst,
    input [7:0] ps2_received_data,
    input       ps2_received_data_strb,

    // Output
    output      morse_code_out
);

    localparam SIZE_DATA_COUNTER   = $clog2(BUFFER_LENGTH);
    localparam SIZE_TIMING_COUNTER = $clog2(10000000);  //50000000

    localparam [SIZE_TIMING_COUNTER-1:0] DIT_TIME             = 40000;  // 4000000
    localparam [SIZE_TIMING_COUNTER-1:0] DAH_TIME             = 80000;  // 12000000
    localparam [SIZE_TIMING_COUNTER-1:0] BETWEEN_DIT_DAH_TIME = 10000;  // 4000000
    localparam [SIZE_TIMING_COUNTER-1:0] BETWEEN_CHAR_TIME    = 40000;  // 12000000
    localparam [SIZE_TIMING_COUNTER-1:0] SPACE_TIME           = 80000;  // 28000000
    
    localparam BREAK_CODE = 8'hf0;
    localparam ENTER      = 8'h5A;
    localparam SPACE      = 8'h29;
    localparam F1_KEY     = 8'h05;
    localparam F2_KEY     = 8'h0C;
    

    // Internal Registers
    reg [(BUFFER_LENGTH*8)-1:0] data_shift_reg;
    reg [(BUFFER_LENGTH*8)-1:0] next_data_shift_reg;
    
    reg [(BUFFER_LENGTH*8)-1:0] tmp_data_shift_reg;
    reg [(BUFFER_LENGTH*8)-1:0] next_tmp_data_shift_reg;

    reg [SIZE_DATA_COUNTER-1:0] data_counter;
    reg [SIZE_DATA_COUNTER-1:0] next_data_counter;

    reg [SIZE_TIMING_COUNTER-1:0] timing_counter;
    reg [SIZE_TIMING_COUNTER-1:0] next_timing_counter;

    reg operation_mode;            // 0 - Output when Enter, 1 - Ouput when Space
    reg next_operation_mode;

    reg morse_code_output;
    reg next_morse_code_output;

    reg [2:0] next_data_handler_state;
    reg [2:0] data_handler_state;

    reg [7:0] next_scancode;
    reg [7:0] scancode;

    // FSM-States
    localparam DATA_STATE_0_IDLE    = 3'h0,
               DATA_STATE_1_DATA_IN = 3'h1,
               DATA_STATE_2_BREAK_CODE = 3'h2,
               DATA_STATE_3_BUFFER_DATA = 3'h3,
               DATA_STATE_4_DATA_OUT = 3'h4;

    localparam DEFAULT_SCANCODE = 8'h00;


    always @(posedge clk) begin
        if (rst) begin
            data_shift_reg      <= {BUFFER_LENGTH*8{1'b0}};
            tmp_data_shift_reg  <= {BUFFER_LENGTH*8{1'b0}};
            data_counter        <= {SIZE_DATA_COUNTER{1'b1}};
            timing_counter      <= {SIZE_TIMING_COUNTER{1'b0}};
            operation_mode      <= 1'b0;
            morse_code_output   <= 1'b0;
            
            data_handler_state  <= DATA_STATE_0_IDLE;
            scancode            <= DEFAULT_SCANCODE;
        end else begin
            data_shift_reg      <= next_data_shift_reg;
            tmp_data_shift_reg  <= next_tmp_data_shift_reg;
            data_counter        <= next_data_counter;
            timing_counter      <= next_timing_counter;
            operation_mode      <= next_operation_mode;
            morse_code_output   <= next_morse_code_output;
            
            data_handler_state  <= next_data_handler_state;
            scancode            <= next_scancode;
        end
    end


    always @(data_shift_reg, tmp_data_shift_reg, data_counter, timing_counter, operation_mode, morse_code_output, data_handler_state, scancode, ps2_received_data, ps2_received_data_strb) begin
        next_data_shift_reg     <= data_shift_reg;
        next_tmp_data_shift_reg <= tmp_data_shift_reg;
        next_data_counter       <= data_counter;
        next_timing_counter     <= timing_counter;
        next_operation_mode     <= operation_mode;
        next_morse_code_output  <= morse_code_output;
    
        next_data_handler_state <= DATA_STATE_0_IDLE;
        next_scancode           <= DEFAULT_SCANCODE;
        
        case (data_handler_state)
            DATA_STATE_0_IDLE:
                begin
                    if (ps2_received_data_strb)
                        next_data_handler_state <= DATA_STATE_1_DATA_IN;
                    else
                        next_data_handler_state <= DATA_STATE_0_IDLE;
                end
            DATA_STATE_1_DATA_IN:
                begin
                    if (ps2_received_data == BREAK_CODE)
                        next_data_handler_state <= DATA_STATE_2_BREAK_CODE;
                    else
                        next_data_handler_state <= DATA_STATE_3_BUFFER_DATA;
                end
            DATA_STATE_2_BREAK_CODE:
                begin
                    if (ps2_received_data_strb)
                        next_data_handler_state <= DATA_STATE_0_IDLE;
                    else
                        next_data_handler_state <= DATA_STATE_2_BREAK_CODE;
                end
            DATA_STATE_3_BUFFER_DATA:
                begin
                    if ((ps2_received_data == SPACE && operation_mode == 1'b1) || ps2_received_data == ENTER)
                        next_data_handler_state <= DATA_STATE_4_DATA_OUT;
                    else begin
                        if (ps2_received_data > 8'h15 && ps2_received_data < 8'h49) begin
                            if (ps2_received_data != 8'h1f &&
                                ps2_received_data != 8'h27 &&
                                (ps2_received_data != 8'h29 || operation_mode != 1'b1) &&
                                ps2_received_data != 8'h2f &&
                                ps2_received_data != 8'h41) begin
                                next_data_shift_reg <= {data_shift_reg[(BUFFER_LENGTH*8)-1-8:0], ps2_received_data};
                            end
                        end else if (ps2_received_data == F1_KEY)    // F1-Key
                            next_operation_mode <= 1'b0;
                        else if (ps2_received_data == F2_KEY)        // F4-Key
                            next_operation_mode <= 1'b1;
                        next_data_handler_state <= DATA_STATE_0_IDLE;
                    end
                end
            DATA_STATE_4_DATA_OUT:
                begin         
                    
                    if (timing_counter == {SIZE_TIMING_COUNTER{1'b1}})
                        next_timing_counter <= {SIZE_TIMING_COUNTER{1'b0}};
                    else
                        next_timing_counter <= timing_counter + {{(SIZE_TIMING_COUNTER-1){1'b0}}, 1'b1};

                    if (data_counter == {SIZE_DATA_COUNTER{1'b0}}) begin
                        next_data_counter <= {SIZE_DATA_COUNTER{1'b1}};
                        next_data_shift_reg <= {BUFFER_LENGTH*8{1'b0}};
                        next_data_handler_state <= DATA_STATE_0_IDLE;
                    end else
                        next_data_handler_state <= DATA_STATE_4_DATA_OUT;
                        
                        
                    case(scancode)
                        DEFAULT_SCANCODE:
                            begin
                                next_timing_counter <= {SIZE_TIMING_COUNTER{1'b0}};
                                next_data_counter <= data_counter - {{(SIZE_DATA_COUNTER-1){1'b0}}, 1'b1};
                                
                                next_tmp_data_shift_reg <= data_shift_reg >> (data_counter - 2 - {{(SIZE_DATA_COUNTER-1){1'b0}}, 1'b1}) * 8;
                                next_scancode <= tmp_data_shift_reg[7:0];
                            end
                        8'h1C:    // A
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1C;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1C;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1C;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME + DAH_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1C;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h32:    // B
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h32;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h32;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h32;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h32;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h32;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h32;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h32;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h32;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h21:    // C
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h21;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h21;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h21;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h21;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h21;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h21;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h21;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h21;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h23:    // D
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h23;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h23;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h23;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h23;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h23;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h23;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h24:    // E
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h24;
                                end else if (timing_counter < DAH_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h24;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h2B:    // F
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2B;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2B;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2B;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2B;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2B;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2B;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2B;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2B;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h34:    // G
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h34;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h34;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h34;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h34;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h34;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h34;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h33:    // H
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h33;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h33;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h33;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h33;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h33;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h33;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 4 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h33;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 4 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h33;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h43:    // I
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h43;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h43;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h43;
                                end else if (timing_counter < 1 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h43;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h3B:    // J
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3B;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3B;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3B;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3B;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3B;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3B;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3B;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3B;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h42:    // K
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h42;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h42;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h42;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h42;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h42;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h42;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h4B:    // L
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h4B;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h4B;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h4B;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h4B;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h4B;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h4B;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h4B;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h4B;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h3A:    // M
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3A;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3A;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3A;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3A;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h31:    // N
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h31;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h31;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h31;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h31;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h44:    // O
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h44;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h44;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h44;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h44;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h44;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h44;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h4D:    // P
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h4D;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h4D;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h4D;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h4D;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h4D;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h4D;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h4D;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h4D;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h15:    // Q
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h15;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h15;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h15;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h15;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h15;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h15;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h15;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h15;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h2D:    // R
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2D;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2D;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2D;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2D;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2D;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2D;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h1B:    // S
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1B;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1B;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1B;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1B;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1B;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1B;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h2C:    // T
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2C;
                                end else if (timing_counter < DAH_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2C;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h3C:    // U
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3C;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3C;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3C;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3C;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3C;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3C;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h2A:    // V
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2A;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2A;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2A;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2A;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2A;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2A;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2A;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2A;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h1D:    // W
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1D;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1D;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1D;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1D;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1D;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1D;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h22:    // X
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h22;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h22;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h22;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h22;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h22;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h22;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h22;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h22;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h35:    // Y
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h35;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h35;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h35;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h35;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h35;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h35;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h35;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h35;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h1A:    // Z
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1A;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1A;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1A;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1A;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1A;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1A;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1A;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1A;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h45:    // 0
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h45;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h45;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h45;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h45;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h45;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h45;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h45;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h45;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 5 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h45;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 5 * DAH_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h45;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h16:    // 1
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h16;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h16;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h16;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h16;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h16;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h16;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h16;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h16;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h16;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h16;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h1E:    // 2
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1E;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1E;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1E;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1E;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1E;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1E;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1E;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1E;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h1E;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h1E;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h26:    // 3
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h26;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h26;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h26;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h26;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h26;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h26;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h26;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h26;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h26;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h26;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h25:    // 4
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h25;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h25;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h25;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h25;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h25;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h25;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 4 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h25;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h25;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 4 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h25;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 4 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h25;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h2E:    // 5
                            begin
                                if (timing_counter < DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2E;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2E;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2E;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2E;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2E;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2E;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 4 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2E;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2E;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 5 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h2E;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 5 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h2E;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h36:    // 6
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h36;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h36;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h36;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h36;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h36;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h36;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h36;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h36;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 4 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h36;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 4 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h36;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h3D:    // 7
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3D;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3D;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3D;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3D;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3D;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3D;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 *DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3D;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3D;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 3 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3D;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3D;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h3E:    // 8
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3E;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3E;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3E;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3E;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3E;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3E;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3E;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3E;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + 2 * DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h3E;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h3E;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h46:    // 9
                            begin
                                if (timing_counter < DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h46;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h46;
                                end else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h46;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h46;
                                end else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h46;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h46;
                                end else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h46;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h46;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME + DIT_TIME) begin
                                    next_morse_code_output <= 1'b1;
                                    next_scancode <= 8'h46;
                                end else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h46;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        8'h29:    // Space
                            begin
                                if (timing_counter < SPACE_TIME) begin
                                    next_morse_code_output <= 1'b0;
                                    next_scancode <= 8'h29;
                                end else
                                    next_scancode <= DEFAULT_SCANCODE;
                            end
                        default:
                            begin
                                next_scancode <= DEFAULT_SCANCODE;
                            end
                    endcase
                end
            default:
                begin
                    next_data_handler_state <= DATA_STATE_0_IDLE;
                end
        endcase
    end
    
    assign morse_code_out = morse_code_output;
    
endmodule

`endif
`default_nettype wire
                      
