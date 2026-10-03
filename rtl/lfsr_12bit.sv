`timescale 1ns/1ps

module lfsr_12bit (
    input  logic        clk,
    input  logic        reset,
    input  logic        seed_load,
    input  logic [11:0] seed,
    input  logic        enable,
    output logic [11:0] state
);

    logic feedback;

    // 12-bit Fibonacci LFSR
    // Polynomial: x^12 + x^6 + x^4 + x + 1
    // Taps: 11, 5, 3, 0

    assign feedback = state[11] ^
                      state[5]  ^
                      state[3]  ^
                      state[0];

    always_ff @(posedge clk) begin

        if (reset) begin
            state <= 12'h001;
        end

        else if (seed_load) begin
            // Prevent the LFSR from entering the all-zero state
            if (seed == 12'h000)
                state <= 12'h001;
            else
                state <= seed;
        end

        else if (enable) begin
            state <= {state[10:0], feedback};
        end

    end

endmodule
