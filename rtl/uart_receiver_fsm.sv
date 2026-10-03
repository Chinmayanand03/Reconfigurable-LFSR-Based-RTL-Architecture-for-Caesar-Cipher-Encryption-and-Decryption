module uart_receiver_fsm #(
    parameter integer CLKS_PER_BIT = 434
) (
    input  logic       clk,
    input  logic       reset,
    input  logic       rx,
    output logic [7:0] data_out,
    output logic       data_valid
);

    typedef enum logic [2:0] {RX_IDLE, RX_START, RX_DATA, RX_STOP} rx_state_t;
    rx_state_t state;

    integer count;
    logic [2:0] bit_index;
    logic [7:0] data_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            state      <= RX_IDLE;
            count      <= 0;
            bit_index  <= 3'd0;
            data_reg   <= 8'h00;
            data_out   <= 8'h00;
            data_valid <= 1'b0;
        end else begin
            data_valid <= 1'b0;

            case (state)
                RX_IDLE: begin
                    count <= 0;
                    if (!rx)
                        state <= RX_START;
                end

                RX_START: begin
                    if (count == (CLKS_PER_BIT/2)-1) begin
                        count <= 0;
                        if (!rx) begin
                            bit_index <= 3'd0;
                            state <= RX_DATA;
                        end else begin
                            state <= RX_IDLE;
                        end
                    end else begin
                        count <= count + 1;
                    end
                end

                RX_DATA: begin
                    if (count == CLKS_PER_BIT-1) begin
                        count <= 0;
                        data_reg[bit_index] <= rx;
                        if (bit_index == 3'd7)
                            state <= RX_STOP;
                        else
                            bit_index <= bit_index + 1'b1;
                    end else begin
                        count <= count + 1;
                    end
                end

                RX_STOP: begin
                    if (count == CLKS_PER_BIT-1) begin
                        count <= 0;
                        data_out <= data_reg;
                        data_valid <= 1'b1;
                        state <= RX_IDLE;
                    end else begin
                        count <= count + 1;
                    end
                end

                default: state <= RX_IDLE;
            endcase
        end
    end

endmodule
