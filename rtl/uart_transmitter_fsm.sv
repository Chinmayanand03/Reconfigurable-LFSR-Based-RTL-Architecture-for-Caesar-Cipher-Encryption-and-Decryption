`timescale 1ns/1ps

module uart_transmitter_fsm #(
    parameter integer CLKS_PER_BIT = 434
) (
    input  logic       clk,
    input  logic       reset,

    input  logic [7:0] data_in,
    input  logic       data_valid,

    output logic       tx,
    output logic       busy,
    output logic       done
);

    typedef enum logic [1:0] {
        TX_IDLE  = 2'b00,
        TX_START = 2'b01,
        TX_DATA  = 2'b10,
        TX_STOP  = 2'b11
    } tx_state_t;

    tx_state_t state;

    logic [7:0] data_reg;
    logic [2:0] bit_index;

    integer clk_count;

    always_ff @(posedge clk) begin

        if (reset) begin
            state     <= TX_IDLE;
            data_reg  <= 8'h00;
            bit_index <= 3'd0;
            clk_count <= 0;

            tx        <= 1'b1;
            busy      <= 1'b0;
            done      <= 1'b0;
        end

        else begin

            // DONE is a one-clock pulse
            done <= 1'b0;

            case (state)

                // ------------------------------------------------
                // IDLE
                // ------------------------------------------------
                TX_IDLE: begin

                    tx        <= 1'b1;
                    busy      <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 3'd0;

                    if (data_valid) begin

                        data_reg  <= data_in;

                        // UART START bit
                        tx        <= 1'b0;

                        busy      <= 1'b1;
                        clk_count <= 0;

                        state     <= TX_START;
                    end
                end


                // ------------------------------------------------
                // START BIT
                // ------------------------------------------------
                TX_START: begin

                    if (clk_count == CLKS_PER_BIT - 1) begin

                        clk_count <= 0;
                        bit_index <= 3'd0;

                        // First data bit, LSB first
                        tx <= data_reg[0];

                        state <= TX_DATA;

                    end
                    else begin

                        clk_count <= clk_count + 1;
                    end
                end


                // ------------------------------------------------
                // DATA BITS
                // ------------------------------------------------
                TX_DATA: begin

                    if (clk_count == CLKS_PER_BIT - 1) begin

                        clk_count <= 0;

                        if (bit_index == 3'd7) begin

                            // All 8 data bits transmitted.
                            // Move to STOP bit.
                            tx <= 1'b1;

                            state <= TX_STOP;

                        end
                        else begin

                            bit_index <= bit_index + 1'b1;

                            // Next data bit
                            tx <= data_reg[bit_index + 1'b1];

                        end

                    end
                    else begin

                        clk_count <= clk_count + 1;
                    end
                end


                // ------------------------------------------------
                // STOP BIT
                // ------------------------------------------------
                TX_STOP: begin

                    if (clk_count == CLKS_PER_BIT - 1) begin

                        clk_count <= 0;

                        tx   <= 1'b1;
                        busy <= 1'b0;
                        done <= 1'b1;

                        state <= TX_IDLE;

                    end
                    else begin

                        clk_count <= clk_count + 1;

                    end
                end


                default: begin

                    state     <= TX_IDLE;
                    tx        <= 1'b1;
                    busy      <= 1'b0;
                    done      <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 3'd0;

                end

            endcase
        end
    end

endmodule
