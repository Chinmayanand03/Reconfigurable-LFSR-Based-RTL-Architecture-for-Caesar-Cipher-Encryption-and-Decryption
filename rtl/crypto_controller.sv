`timescale 1ns/1ps

module crypto_controller (
    input  logic clk,
    input  logic reset,
    input  logic start,

    output logic busy,
    output logic execute,
    output logic valid,
    output logic lfsr_enable
);

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        EXECUTE = 2'b01,
        DONE    = 2'b10
    } state_t;

    state_t state, next_state;

    // ------------------------------------------------------------
    // State register
    // ------------------------------------------------------------

    always_ff @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ------------------------------------------------------------
    // Next-state logic
    // ------------------------------------------------------------

    always_comb begin

        next_state = state;

        case (state)

            IDLE: begin
                if (start)
                    next_state = EXECUTE;
            end

            EXECUTE: begin
                next_state = DONE;
            end

            DONE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end

        endcase

    end

    // ------------------------------------------------------------
    // Output logic
    // ------------------------------------------------------------

    always_comb begin

        busy        = 1'b0;
        execute     = 1'b0;
        valid       = 1'b0;
        lfsr_enable = 1'b0;

        case (state)

            IDLE: begin
                busy        = 1'b0;
                execute     = 1'b0;
                valid       = 1'b0;
                lfsr_enable = 1'b0;
            end

            EXECUTE: begin
                busy        = 1'b1;
                execute     = 1'b1;
                valid       = 1'b0;
                lfsr_enable = 1'b0;
            end

            DONE: begin
                busy        = 1'b0;
                execute     = 1'b0;
                valid       = 1'b1;
                lfsr_enable = 1'b1;
            end

            default: begin
                busy        = 1'b0;
                execute     = 1'b0;
                valid       = 1'b0;
                lfsr_enable = 1'b0;
            end

        endcase

    end

endmodule
