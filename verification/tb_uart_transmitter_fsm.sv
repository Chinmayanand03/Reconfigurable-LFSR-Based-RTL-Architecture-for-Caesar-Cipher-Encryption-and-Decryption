`timescale 1ns/1ps

module tb_uart_transmitter_fsm;

    localparam integer CLKS_PER_BIT = 434;

    logic       clk;
    logic       reset;
    logic [7:0] data_in;
    logic       data_valid;

    logic       tx;
    logic       busy;
    logic       done;

    integer error_count;
    integer check_count;
    integer timeout_count;

    // ============================================================
    // DUT
    // ============================================================

    uart_transmitter_fsm #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk        (clk),
        .reset      (reset),
        .data_in    (data_in),
        .data_valid (data_valid),
        .tx         (tx),
        .busy       (busy),
        .done       (done)
    );

    // ============================================================
    // CLOCK
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
        $dumpvars(0, tb_uart_transmitter_fsm);
    end

    // ============================================================
    // CHECK
    // ============================================================

    task automatic check_bit(
        input logic expected,
        input string name
    );
        begin

            check_count = check_count + 1;

            if (tx === expected) begin
                $display(
                    "PASS: %s = %b",
                    name,
                    tx
                );
            end
            else begin
                $display(
                    "FAIL: %s Expected=%b Got=%b",
                    name,
                    expected,
                    tx
                );

                error_count = error_count + 1;
            end

        end
    endtask

    // ============================================================
    // WAIT FOR DONE
    // ============================================================

    task automatic wait_for_done;

        begin

            timeout_count = 0;

            while ((done !== 1'b1) &&
                   (timeout_count < (CLKS_PER_BIT * 2))) begin

                @(posedge clk);
                #1;

                timeout_count = timeout_count + 1;

            end

            if (done !== 1'b1) begin

                $display("FAIL: DONE timeout");

                error_count = error_count + 1;

            end
            else begin

                $display("PASS: DONE = 1");

            end

        end

    endtask

    // ============================================================
    // TRANSMIT AND VERIFY ONE BYTE
    // ============================================================

    task automatic test_byte(
        input logic [7:0] test_data
    );

        integer i;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("TRANSMITTING DATA = 0x%02h", test_data);
            $display("----------------------------------------------");

            // ----------------------------------------------------
            // Apply data before rising edge
            // ----------------------------------------------------

            @(negedge clk);

            data_in    = test_data;
            data_valid = 1'b1;

            @(posedge clk);
            #1;

            data_valid = 1'b0;

            // ----------------------------------------------------
            // START BIT
            // ----------------------------------------------------

            if (tx !== 1'b0) begin

                $display(
                    "FAIL: START Expected=0 Got=%b",
                    tx
                );

                error_count = error_count + 1;

            end
            else begin

                $display("PASS: START = 0");

            end

            check_count = check_count + 1;

            // ----------------------------------------------------
            // Verify BUSY
            // ----------------------------------------------------

            if (busy !== 1'b1) begin

                $display(
                    "FAIL: BUSY Expected=1 Got=%b",
                    busy
                );

                error_count = error_count + 1;

            end
            else begin

                $display("PASS: BUSY = 1");

            end

            check_count = check_count + 1;

            // ----------------------------------------------------
            // Move to middle of START bit
            //
            // We are currently at the beginning of START.
            // ----------------------------------------------------

            repeat (CLKS_PER_BIT / 2)
                @(posedge clk);

            #1;

            // ----------------------------------------------------
            // Move to middle of DATA[0]
            // ----------------------------------------------------

            repeat (CLKS_PER_BIT / 2)
                @(posedge clk);

            #1;

            check_bit(
                test_data[0],
                "DATA[0]"
            );

            // ----------------------------------------------------
            // DATA[1] ... DATA[7]
            //
            // We are currently at the middle of DATA[0].
            // One full bit period moves to the middle of next bit.
            // ----------------------------------------------------

            for (i = 1; i < 8; i = i + 1) begin

                repeat (CLKS_PER_BIT)
                    @(posedge clk);

                #1;

                check_bit(
                    test_data[i],
                    $sformatf("DATA[%0d]", i)
                );

            end

            // ----------------------------------------------------
            // STOP BIT
            // ----------------------------------------------------

            repeat (CLKS_PER_BIT)
                @(posedge clk);

            #1;

            check_bit(
                1'b1,
                "STOP"
            );

            // ----------------------------------------------------
            // Wait for DONE
            // ----------------------------------------------------

            wait_for_done;

            // ----------------------------------------------------
            // BUSY should be low
            // ----------------------------------------------------

            if (busy !== 1'b0) begin

                $display(
                    "FAIL: BUSY after frame Expected=0 Got=%b",
                    busy
                );

                error_count = error_count + 1;

            end
            else begin

                $display("PASS: BUSY = 0");

            end

            check_count = check_count + 1;

            // ----------------------------------------------------
            // TX should return to idle-high
            // ----------------------------------------------------

            if (tx !== 1'b1) begin

                $display(
                    "FAIL: TX idle Expected=1 Got=%b",
                    tx
                );

                error_count = error_count + 1;

            end
            else begin

                $display("PASS: TX idle = 1");

            end

            check_count = check_count + 1;

            // ----------------------------------------------------
            // Wait until DONE returns low
            // ----------------------------------------------------

            @(posedge clk);
            #1;

            if (done !== 1'b0) begin

                $display(
                    "FAIL: DONE did not return low"
                );

                error_count = error_count + 1;

            end
            else begin

                $display("PASS: DONE returned to 0");

            end

            check_count = check_count + 1;

        end

    endtask

    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        reset      = 1'b1;
        data_in    = 8'h00;
        data_valid = 1'b0;

        error_count = 0;
        check_count = 0;

        $display("");
        $display("==============================================");
        $display("       UART TRANSMITTER VERIFICATION");
        $display("==============================================");

        // ========================================================
        // RESET
        // ========================================================

        repeat (3) begin

            @(posedge clk);
            #1;

            if (tx !== 1'b1) begin
                $display("FAIL: TX during reset");
                error_count = error_count + 1;
            end

            if (busy !== 1'b0) begin
                $display("FAIL: BUSY during reset");
                error_count = error_count + 1;
            end

            if (done !== 1'b0) begin
                $display("FAIL: DONE during reset");
                error_count = error_count + 1;
            end

        end

        if (error_count == 0)
            $display("PASS: Reset");

        // ========================================================
        // RELEASE RESET
        // ========================================================

        reset = 1'b0;

        @(posedge clk);
        #1;

        // ========================================================
        // TEST 1
        //
        // 0xA5 = 1010_0101
        //
        // UART LSB first:
        //
        // START  0
        // DATA   1 0 1 0 0 1 0 1
        // STOP   1
        // ========================================================

        test_byte(8'hA5);

        // ========================================================
        // TEST 2
        //
        // 0x3C = 0011_1100
        //
        // UART LSB first:
        //
        // START  0
        // DATA   0 0 1 1 1 1 0 0
        // STOP   1
        // ========================================================

        test_byte(8'h3C);

        // ========================================================
        // FINAL RESULT
        // ========================================================

        $display("");
        $display("==============================================");
        $display("Total checks : %0d", check_count);
        $display("Total errors : %0d", error_count);

        if (error_count == 0)
            $display("UART TRANSMITTER VERIFICATION: PASS");
        else
            $display("UART TRANSMITTER VERIFICATION: FAIL");

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule