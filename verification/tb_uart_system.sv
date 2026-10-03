`timescale 1ns/1ps

module tb_uart_system;

    localparam integer CLK_FREQ_HZ  = 1_000_000;
    localparam integer BAUD_RATE    = 100_000;
    localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;

    logic clk;
    logic reset;

    logic uart_rx;
    logic uart_tx;

    logic crypto_busy;
    logic crypto_valid;
    logic [7:0] crypto_result;

    integer check_count;
    integer error_count;

    logic [7:0] received_byte;

    // ============================================================
    // DUT
    // ============================================================

    top_system_integration #(
        .CLK_FREQ_HZ  (CLK_FREQ_HZ),
        .BAUD_RATE    (BAUD_RATE),
        .CLKS_PER_BIT (CLKS_PER_BIT)
    ) dut (
        .clk           (clk),
        .reset         (reset),
        .uart_rx       (uart_rx),
        .uart_tx       (uart_tx),
        .crypto_busy   (crypto_busy),
        .crypto_valid  (crypto_valid),
        .crypto_result (crypto_result)
    );

    // ============================================================
    // CLOCK
    // 1 MHz clock = 10 ns period
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // VCD
    // ============================================================

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_uart_system);
    end

    // ============================================================
    // UART SEND BYTE
    // 8N1, LSB first
    // ============================================================

    task automatic uart_send_byte(input logic [7:0] value);
        integer b;

        begin
            // START bit
            uart_rx = 1'b0;

            repeat (CLKS_PER_BIT)
                @(posedge clk);

            // DATA bits
            for (b = 0; b < 8; b = b + 1) begin
                uart_rx = value[b];

                repeat (CLKS_PER_BIT)
                    @(posedge clk);
            end

            // STOP bit
            uart_rx = 1'b1;

            repeat (CLKS_PER_BIT)
                @(posedge clk);
        end
    endtask

    // ============================================================
    // SEND COMPLETE CRYPTO COMMAND
    //
    // Byte 0 : A5
    // Byte 1 : mode
    // Byte 2 : shift
    // Byte 3 : seed[11:8]
    // Byte 4 : seed[7:0]
    // Byte 5 : data
    // ============================================================

    task automatic send_command(
        input logic        mode,
        input logic [4:0]  shift,
        input logic [11:0] seed,
        input logic [7:0]  data
    );

        begin
            uart_send_byte(8'hA5);
            uart_send_byte({7'd0, mode});
            uart_send_byte({3'd0, shift});
            uart_send_byte({4'd0, seed[11:8]});
            uart_send_byte(seed[7:0]);
            uart_send_byte(data);
        end

    endtask

    // ============================================================
    // RECEIVE BYTE FROM DUT UART TX
    // ============================================================

    task automatic uart_receive_byte(
        output logic [7:0] value
    );

        integer b;

        begin

            value = 8'h00;

            // Wait for START bit
            @(negedge uart_tx);

            // Move to middle of START bit
            repeat (CLKS_PER_BIT / 2)
                @(posedge clk);

            check_count = check_count + 1;

            if (uart_tx === 1'b0) begin
                $display("PASS: UART TX START bit = 0");
            end
            else begin
                $display("FAIL: UART TX START bit");
                error_count = error_count + 1;
            end

            // Move to center of each DATA bit
            for (b = 0; b < 8; b = b + 1) begin

                repeat (CLKS_PER_BIT)
                    @(posedge clk);

                value[b] = uart_tx;

            end

            // STOP bit
            repeat (CLKS_PER_BIT)
                @(posedge clk);

            check_count = check_count + 1;

            if (uart_tx === 1'b1) begin
                $display("PASS: UART TX STOP bit = 1");
            end
            else begin
                $display("FAIL: UART TX STOP bit");
                error_count = error_count + 1;
            end

        end

    endtask

    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        check_count = 0;
        error_count = 0;

        uart_rx = 1'b1;
        reset   = 1'b1;

        $display("");
        $display("==============================================");
        $display("       TOP SYSTEM INTEGRATION VERIFICATION");
        $display("==============================================");

        // Reset
        repeat (5)
            @(posedge clk);

        check_count = check_count + 1;

        if (crypto_busy === 1'b0) begin
            $display("PASS: Crypto busy = 0 after reset");
        end
        else begin
            $display("FAIL: Crypto busy during reset");
            error_count = error_count + 1;
        end

        reset = 1'b0;

        repeat (5)
            @(posedge clk);

        // ========================================================
        // TEST 1
        //
        // Encrypt:
        // Data  = A
        // Shift = 3
        // Seed  = 001
        //
        // LFSR key = 001 % 26 = 1
        // Effective key = 3 + 1 = 4
        // A + 4 = E
        // ========================================================

        $display("");
        $display("----------------------------------------------");
        $display("TEST 1: UART ENCRYPTION");
        $display("DATA = A");
        $display("SHIFT = 3");
        $display("SEED = 001");
        $display("EXPECTED RESULT = E");
        $display("----------------------------------------------");

        // Start TX receiver before sending command
        fork

            begin
                send_command(
                    1'b0,
                    5'd3,
                    12'h001,
                    8'h41
                );
            end

            begin
                uart_receive_byte(received_byte);
            end

        join

        // Check crypto result
        check_count = check_count + 1;

        if (crypto_result === 8'h45) begin
            $display(
                "PASS: Crypto result = %c (0x%02h)",
                crypto_result,
                crypto_result
            );
        end
        else begin
            $display(
                "FAIL: Crypto result expected E (45), got %c (0x%02h)",
                crypto_result,
                crypto_result
            );

            error_count = error_count + 1;
        end

        // Check UART response
        check_count = check_count + 1;

        if (received_byte === 8'h45) begin
            $display(
                "PASS: UART response = %c (0x%02h)",
                received_byte,
                received_byte
            );
        end
        else begin
            $display(
                "FAIL: UART response expected E (45), got %c (0x%02h)",
                received_byte,
                received_byte
            );

            error_count = error_count + 1;
        end

        // Allow system to return idle
        repeat (100)
            @(posedge clk);

        // ========================================================
        // TEST 2
        //
        // Decrypt:
        // Data  = E
        // Shift = 3
        // Seed  = 001
        //
        // Effective key = 4
        // E - 4 = A
        // ========================================================

        $display("");
        $display("----------------------------------------------");
        $display("TEST 2: UART DECRYPTION");
        $display("DATA = E");
        $display("SHIFT = 3");
        $display("SEED = 001");
        $display("EXPECTED RESULT = A");
        $display("----------------------------------------------");

        fork

            begin
                send_command(
                    1'b1,
                    5'd3,
                    12'h001,
                    8'h45
                );
            end

            begin
                uart_receive_byte(received_byte);
            end

        join

        // Check crypto result
        check_count = check_count + 1;

        if (crypto_result === 8'h41) begin
            $display(
                "PASS: Crypto result = %c (0x%02h)",
                crypto_result,
                crypto_result
            );
        end
        else begin
            $display(
                "FAIL: Crypto result expected A (41), got %c (0x%02h)",
                crypto_result,
                crypto_result
            );

            error_count = error_count + 1;
        end

        // Check UART response
        check_count = check_count + 1;

        if (received_byte === 8'h41) begin
            $display(
                "PASS: UART response = %c (0x%02h)",
                received_byte,
                received_byte
            );
        end
        else begin
            $display(
                "FAIL: UART response expected A (41), got %c (0x%02h)",
                received_byte,
                received_byte
            );

            error_count = error_count + 1;
        end

        // ========================================================
        // FINAL RESULT
        // ========================================================

        $display("");
        $display("==============================================");
        $display("Total checks : %0d", check_count);
        $display("Total errors : %0d", error_count);

        if (error_count == 0)
            $display("TOP SYSTEM INTEGRATION VERIFICATION: PASS");
        else
            $display("TOP SYSTEM INTEGRATION VERIFICATION: FAIL");

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule