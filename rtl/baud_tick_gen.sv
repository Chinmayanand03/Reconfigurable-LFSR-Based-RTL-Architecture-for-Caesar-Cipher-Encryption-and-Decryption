`timescale 1ns/1ps

module baud_tick_gen #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer BAUD_RATE   = 115_200
) (
    input  logic clk,
    input  logic reset,
    output logic tick
);

    localparam integer DIVISOR = CLK_FREQ_HZ / BAUD_RATE;
    localparam integer COUNT_W = (DIVISOR <= 1) ? 1 : $clog2(DIVISOR);

    logic [COUNT_W-1:0] count;

    always_ff @(posedge clk) begin
        if (reset) begin
            count <= '0;
            tick  <= 1'b0;
        end
        else if (DIVISOR <= 1) begin
            count <= '0;
            tick  <= 1'b1;
        end
        else if (count == DIVISOR-1) begin
            count <= '0;
            tick  <= 1'b1;
        end
        else begin
            count <= count + 1'b1;
            tick  <= 1'b0;
        end
    end

endmodule
