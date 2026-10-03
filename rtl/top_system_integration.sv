module top_system_integration #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer BAUD_RATE   = 115_200,
    parameter integer CLKS_PER_BIT = (CLK_FREQ_HZ / BAUD_RATE)
) (
    input  logic clk,
    input  logic reset,
    input  logic uart_rx,
    output logic uart_tx,
    output logic crypto_busy,
    output logic crypto_valid,
    output logic [7:0] crypto_result
);

    // UART command frame:
    // Byte 0: 8'hA5       header
    // Byte 1: mode        0 = encrypt, 1 = decrypt
    // Byte 2: shift       0..25 in bits [4:0]
    // Byte 3: seed[11:8] in bits [3:0]
    // Byte 4: seed[7:0]
    // Byte 5: data        ASCII plaintext/ciphertext
    // UART response: one result byte.

    logic [7:0] rx_data;
    logic rx_valid;

    logic [7:0] tx_data;
    logic tx_valid;
    logic tx_busy;

    logic [2:0] rx_index;
    logic frame_active;

    logic mode_reg;
    logic [4:0] shift_reg;
    logic [11:0] seed_reg;
    logic [7:0] data_reg;

    logic crypto_start;
    logic seed_load;

    logic [11:0] lfsr_state;

    baud_tick_gen #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE  (BAUD_RATE)
    ) u_baud_tick_gen (
        .clk  (clk),
        .reset(reset),
        .tick ()
    );

    uart_receiver_fsm #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_rx (
        .clk       (clk),
        .reset     (reset),
        .rx        (uart_rx),
        .data_out  (rx_data),
        .data_valid(rx_valid)
    );

    uart_transmitter_fsm #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_tx (
        .clk        (clk),
        .reset      (reset),
        .data_in    (tx_data),
        .data_valid (tx_valid),
        .tx         (uart_tx),
        .busy       (tx_busy),
        .done       ()
    );

    crypto_core u_crypto (
        .clk       (clk),
        .reset     (reset),
        .seed_load (seed_load),
        .seed      (seed_reg),
        .shift_key (shift_reg),
        .mode      (mode_reg),
        .start     (crypto_start),
        .data_in   (data_reg),
        .data_out  (crypto_result),
        .busy      (crypto_busy),
        .valid     (crypto_valid),
        .lfsr_state(lfsr_state)
    );

    always_ff @(posedge clk) begin
        if (reset) begin
            rx_index    <= 3'd0;
            frame_active <= 1'b0;
            mode_reg    <= 1'b0;
            shift_reg   <= 5'd0;
            seed_reg    <= 12'h001;
            data_reg    <= 8'h00;
            crypto_start <= 1'b0;
            seed_load    <= 1'b0;
        end else begin
            crypto_start <= 1'b0;
            seed_load    <= 1'b0;

            if (rx_valid) begin
                if (!frame_active) begin
                    if (rx_data == 8'hA5) begin
                        frame_active <= 1'b1;
                        rx_index <= 3'd1;
                    end
                end else begin
                    case (rx_index)
                        3'd1: begin
                            mode_reg <= rx_data[0];
                            rx_index <= 3'd2;
                        end

                        3'd2: begin
                            shift_reg <= rx_data[4:0];
                            rx_index <= 3'd3;
                        end

                        3'd3: begin
                            seed_reg[11:8] <= rx_data[3:0];
                            rx_index <= 3'd4;
                        end

                        3'd4: begin
                            seed_reg[7:0] <= rx_data;
                            rx_index <= 3'd5;
                        end

                        3'd5: begin
                            data_reg <= rx_data;
                            seed_load <= 1'b1;
                            crypto_start <= 1'b1;
                            frame_active <= 1'b0;
                            rx_index <= 3'd0;
                        end

                        default: begin
                            frame_active <= 1'b0;
                            rx_index <= 3'd0;
                        end
                    endcase
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            tx_data  <= 8'h00;
            tx_valid <= 1'b0;
        end else begin
            tx_valid <= 1'b0;
            if (crypto_valid && !tx_busy) begin
                tx_data  <= crypto_result;
                tx_valid <= 1'b1;
            end
        end
    end

endmodule
