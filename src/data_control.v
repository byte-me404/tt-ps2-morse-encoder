`default_nettype none


module data_control #(parameter BUFFER_LENGTH = 8) (
    // Inputs
    input       clk,
    input       rst,
    input [7:0] ps2_received_data,
    input       ps2_received_data_strb,

    // Output
    output      dit_out,
    output      dah_out,
    output      morse_code_out
);

    localparam SIZE_DATA_COUNTER   = $clog2(BUFFER_LENGTH);
    localparam SIZE_TIMING_COUNTER = $clog2(50000000);                      //50000000	10000000

    localparam [SIZE_TIMING_COUNTER-1:0] DIT_TIME             = 4000000;    // 4000000	40000
    localparam [SIZE_TIMING_COUNTER-1:0] DAH_TIME             = 12000000;   // 12000000	80000
    localparam [SIZE_TIMING_COUNTER-1:0] BETWEEN_DIT_DAH_TIME = 4000000;  	// 4000000	10000
    localparam [SIZE_TIMING_COUNTER-1:0] BETWEEN_CHAR_TIME    = 12000000;   // 12000000	40000
    localparam [SIZE_TIMING_COUNTER-1:0] SPACE_TIME           = 28000000;   // 28000000	80000
    
    localparam BREAK_CODE = 8'hf0;
    localparam ENTER      = 8'h5A;
    localparam SPACE      = 8'h29;
    localparam F1_KEY     = 8'h05;
    localparam F2_KEY     = 8'h0C;
    

    // Internal Registers
    reg [(BUFFER_LENGTH*8)-1:0]   data_shift_reg;
    reg [(BUFFER_LENGTH*8)-1:0]   next_data_shift_reg;
    
    reg [(BUFFER_LENGTH*8)-1:0]   tmp_data_shift_reg;
    reg [(BUFFER_LENGTH*8)-1:0]   next_tmp_data_shift_reg;

    reg [SIZE_DATA_COUNTER-1:0]   data_counter;
    reg [SIZE_DATA_COUNTER-1:0]   next_data_counter;

    reg [SIZE_TIMING_COUNTER-1:0] timing_counter;
    reg [SIZE_TIMING_COUNTER-1:0] next_timing_counter;

    reg operation_mode;            // 0 - Output when Enter, 1 - Ouput when Space
    reg next_operation_mode;

    reg dit;
    reg next_dit;
    reg dah;
    reg next_dah;

    reg [2:0] next_data_handler_state;
    reg [2:0] data_handler_state;

    reg [7:0] next_scancode;
    reg [7:0] scancode;

    // FSM-States
    localparam DATA_STATE_0_IDLE        = 3'h0,
               DATA_STATE_1_DATA_IN     = 3'h1,
               DATA_STATE_2_BREAK_CODE  = 3'h2,
               DATA_STATE_3_BUFFER_DATA = 3'h3,
               DATA_STATE_4_DATA_OUT    = 3'h4;

    localparam DEFAULT_SCANCODE         = 8'h00;


    always @(posedge clk) begin
        if (rst) begin
            data_shift_reg      <= {BUFFER_LENGTH*8{1'b0}};
            tmp_data_shift_reg  <= {BUFFER_LENGTH*8{1'b0}};

            data_counter        <= {SIZE_DATA_COUNTER{1'b1}};
            timing_counter      <= {SIZE_TIMING_COUNTER{1'b0}};

            operation_mode      <= 1'b0;

            dit                 <= 1'b0;
            dah                 <= 1'b0;
            
            data_handler_state  <= DATA_STATE_0_IDLE;
            scancode            <= DEFAULT_SCANCODE;
        end else begin
            data_shift_reg      <= next_data_shift_reg;
            tmp_data_shift_reg  <= next_tmp_data_shift_reg;

            data_counter        <= next_data_counter;
            timing_counter      <= next_timing_counter;

            operation_mode      <= next_operation_mode;
            
            dit                 <= next_dit;
            dah                 <= next_dah;

            data_handler_state  <= next_data_handler_state;
            scancode            <= next_scancode;
        end
    end


    always @(*) begin
        next_data_shift_reg     = data_shift_reg;
        next_tmp_data_shift_reg = tmp_data_shift_reg;

        next_data_counter       = data_counter;
        next_timing_counter     = timing_counter;

        next_operation_mode     = operation_mode;

        next_dit                = dit;
        next_dah                = dah;
    
        next_data_handler_state = DATA_STATE_0_IDLE;
        next_scancode           = DEFAULT_SCANCODE;
        
        case (data_handler_state)
            DATA_STATE_0_IDLE:
                begin
                    if (ps2_received_data_strb)
                        next_data_handler_state = DATA_STATE_1_DATA_IN;
                    else
                        next_data_handler_state = DATA_STATE_0_IDLE;
                end
            DATA_STATE_1_DATA_IN:
                begin
                    if (ps2_received_data == BREAK_CODE)
                        next_data_handler_state = DATA_STATE_2_BREAK_CODE;
                    else
                        next_data_handler_state = DATA_STATE_3_BUFFER_DATA;
                end
            DATA_STATE_2_BREAK_CODE:
                begin
                    if (ps2_received_data_strb)
                        next_data_handler_state = DATA_STATE_0_IDLE;
                    else
                        next_data_handler_state = DATA_STATE_2_BREAK_CODE;
                end
            DATA_STATE_3_BUFFER_DATA:
                begin
                    if ((ps2_received_data == SPACE && operation_mode == 1'b1) || ps2_received_data == ENTER)
                        next_data_handler_state = DATA_STATE_4_DATA_OUT;
                    else begin
                        if (ps2_received_data > 8'h15 && ps2_received_data < 8'h49) begin
                            if (ps2_received_data != 8'h1f &&
                                ps2_received_data != 8'h27 &&
                                (ps2_received_data != 8'h29 || operation_mode != 1'b1) &&
                                ps2_received_data != 8'h2f &&
                                ps2_received_data != 8'h41) begin
                                next_data_shift_reg = {data_shift_reg[(BUFFER_LENGTH*8)-1-8:0], ps2_received_data};
                            end
                        end else if (ps2_received_data == F1_KEY)    // F1-Key
                            next_operation_mode = 1'b0;
                        else if (ps2_received_data == F2_KEY)        // F4-Key
                            next_operation_mode = 1'b1;
                        next_data_handler_state = DATA_STATE_0_IDLE;
                    end
                end
            DATA_STATE_4_DATA_OUT:
                begin
                    if (timing_counter == {SIZE_TIMING_COUNTER{1'b1}})
                        next_timing_counter = {SIZE_TIMING_COUNTER{1'b0}};
                    else
                        next_timing_counter = timing_counter + {{(SIZE_TIMING_COUNTER-1){1'b0}}, 1'b1};
                    
                    if (scancode != DEFAULT_SCANCODE)
                        next_data_handler_state = DATA_STATE_4_DATA_OUT;
                    
                    
                    case(scancode)
                        DEFAULT_SCANCODE:
                            begin
                                if (data_counter == {SIZE_DATA_COUNTER{1'b0}}) begin
                                    next_data_counter = {SIZE_DATA_COUNTER{1'b1}};
                                    next_data_shift_reg = {BUFFER_LENGTH*8{1'b0}};
                                    next_data_handler_state = DATA_STATE_0_IDLE;
                                end else begin
                                    next_data_counter = data_counter - {{(SIZE_DATA_COUNTER-1){1'b0}}, 1'b1};
                                    next_data_handler_state = DATA_STATE_4_DATA_OUT;
                                end
                                
                                next_timing_counter = {SIZE_TIMING_COUNTER{1'b0}};
                                
                                next_tmp_data_shift_reg = data_shift_reg >> (data_counter - 1 - {{(SIZE_DATA_COUNTER-1){1'b0}}, 1'b1}) * 8;
                                next_scancode = tmp_data_shift_reg[7:0];
                            end
                        8'h1C:    // A
                            begin
                                next_scancode = 8'h1C;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME + DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME + DAH_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h32:    // B
                            begin
                                next_scancode = 8'h32;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h21:    // C
                            begin
                                next_scancode = 8'h21;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h23:    // D
                            begin
                                next_scancode = 8'h23;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h24:    // E
                            begin
                                next_scancode = 8'h24;
                                if (timing_counter < DAH_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < DAH_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h2B:    // F
                            begin
                                next_scancode = 8'h2B;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h34:    // G
                            begin
                                next_scancode = 8'h34;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h33:    // H
                            begin
                                next_scancode = 8'h33;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 4 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 4 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h43:    // I
                            begin
                                next_scancode = 8'h43;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 1 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h3B:    // J
                            begin
                                next_scancode = 8'h3B;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h42:    // K
                            begin
                                next_scancode = 8'h42;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h4B:    // L
                            begin
                                next_scancode = 8'h4B;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h3A:    // M
                            begin
                                next_scancode = 8'h3A;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h31:    // N
                            begin
                                next_scancode = 8'h31;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h44:    // O
                            begin
                                next_scancode = 8'h44;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + 2 * DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h4D:    // P
                            begin
                                next_scancode = 8'h4D;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h15:    // Q
                            begin
                                next_scancode = 8'h15;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h2D:    // R
                            begin
                                next_scancode = 8'h2D;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h1B:    // S
                            begin
                                next_scancode = 8'h1B;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h2C:    // T
                            begin
                                next_scancode = 8'h2C;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < DAH_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h3C:    // U
                            begin
                                next_scancode = 8'h3C;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h2A:    // V
                            begin
                                next_scancode = 8'h2A;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h1D:    // W
                            begin
                                next_scancode = 8'h1D;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h22:    // X
                            begin
                                next_scancode = 8'h22;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h35:    // Y
                            begin
                                next_scancode = 8'h35;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h1A:    // Z
                            begin
                                next_scancode = 8'h1A;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h45:    // 0
                            begin
                                next_scancode = 8'h45;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 5 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 5 * DAH_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h16:    // 1
                            begin
                                next_scancode = 8'h16;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME + DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h1E:    // 2
                            begin
                                next_scancode = 8'h1E;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + 2 * DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h26:    // 3
                            begin
                                next_scancode = 8'h26;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 3 * DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h25:    // 4
                            begin
                                next_scancode = 8'h25;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 4 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 4 * DIT_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 4 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dah = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h2E:    // 5
                            begin
                                next_scancode = 8'h2E;
                                if (timing_counter < DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 4 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 5 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 5 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h36:    // 6
                            begin
                                next_scancode = 8'h36;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 4 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + DAH_TIME + 4 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h3D:    // 7
                            begin
                                next_scancode = 8'h3D;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 *DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 3 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME + 3 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h3E:    // 8
                            begin
                                next_scancode = 8'h3E;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + DIT_TIME)
                                    next_dit = 1'b0;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + 2 * DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME + 2 * DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h46:    // 9
                            begin
                                next_scancode = 8'h46;
                                if (timing_counter < DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 2 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 2 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME)
                                    next_dah = 1'b1;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 3 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 3 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME)
                                    next_dah = 1'b0;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME + DIT_TIME)
                                    next_dit = 1'b1;
                                else if (timing_counter < 4 * BETWEEN_DIT_DAH_TIME + 4 * DAH_TIME + DIT_TIME + BETWEEN_CHAR_TIME)
                                    next_dit = 1'b0;
                                else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        8'h29:    // Space
                            begin
                                next_scancode = 8'h29;
                                if (timing_counter < SPACE_TIME) begin
                                    next_dit = 1'b0;
                                    next_dah = 1'b0;
                                end else
                                    next_scancode = DEFAULT_SCANCODE;
                            end
                        default:
                            begin
                                next_scancode = DEFAULT_SCANCODE;
                            end
                    endcase
                end
            default:
                begin
                    next_data_handler_state = DATA_STATE_0_IDLE;
                end
        endcase
    end
    
    assign dit_out        = dit;
    assign dah_out        = dah;
    assign morse_code_out = dit | dah;
    
endmodule
