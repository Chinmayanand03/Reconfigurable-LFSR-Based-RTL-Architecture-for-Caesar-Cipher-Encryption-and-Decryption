`timescale 1ns/1ps

module tb_caesar_encrypt;

    // ============================================================
    // Testbench signals
    // ============================================================

    logic [7:0] data_in;
    logic [4:0] shift_key;
    logic       enable;
    logic [7:0] data_out;

    integer error_count;
    integer test_count;

    // ============================================================
    // DUT
    // ============================================================

    caesar_encrypt dut (
        .data_in   (data_in),
        .shift_key (shift_key),
        .enable    (enable),
        .data_out  (data_out)
    );

    // ============================================================
    // VCD waveform dump
    // ============================================================

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_caesar_encrypt);
    end

    // ============================================================
    // Test task
    // ============================================================

    task automatic check_case(
        input logic [7:0] test_data,
        input logic [4:0] test_shift,
        input logic       test_enable,
        input logic [7:0] expected_data
    );

        begin

            data_in   = test_data;
            shift_key = test_shift;
            enable    = test_enable;

            #1;

            test_count = test_count + 1;

            if (data_out !== expected_data) begin

                $display(
                    "FAIL: Input=%02h Shift=%0d Enable=%b Expected=%02h Got=%02h",
                    test_data,
                    test_shift,
                    test_enable,
                    expected_data,
                    data_out
                );

                error_count = error_count + 1;

            end
            else begin

                $display(
                    "PASS: Input=%02h Shift=%0d Enable=%b Output=%02h",
                    test_data,
                    test_shift,
                    test_enable,
                    data_out
                );

            end

        end

    endtask

    // ============================================================
    // Main test sequence
    // ============================================================

    initial begin

        error_count = 0;
        test_count  = 0;

        data_in   = 8'h00;
        shift_key = 5'd0;
        enable    = 1'b0;

        $display("");
        $display("==============================================");
        $display("       CAESAR ENCRYPTION VERIFICATION");
        $display("==============================================");


        // --------------------------------------------------------
        // TEST 1: Enable disabled
        // Input must remain unchanged
        // --------------------------------------------------------

        check_case(
            8'h41,
            5'd3,
            1'b0,
            8'h41
        );

        // --------------------------------------------------------
        // TEST 2: Uppercase normal shift
        // A + 3 = D
        // --------------------------------------------------------

        check_case(8'h41, 5'd3, 1'b1, 8'h44);

        // --------------------------------------------------------
        // TEST 3: Uppercase middle character
        // C + 5 = H
        // --------------------------------------------------------

        check_case(8'h43, 5'd5, 1'b1, 8'h48);

        // --------------------------------------------------------
        // TEST 4: Uppercase wrap-around
        // Z + 1 = A
        // --------------------------------------------------------

        check_case(8'h5A, 5'd1, 1'b1, 8'h41);

        // --------------------------------------------------------
        // TEST 5: Uppercase shift 25
        // A + 25 = Z
        // --------------------------------------------------------

        check_case(8'h41, 5'd25, 1'b1, 8'h5A);

        // --------------------------------------------------------
        // TEST 6: Lowercase normal shift
        // a + 3 = d
        // --------------------------------------------------------

        check_case(8'h61, 5'd3, 1'b1, 8'h64);

        // --------------------------------------------------------
        // TEST 7: Lowercase wrap-around
        // z + 1 = a
        // --------------------------------------------------------

        check_case(8'h7A, 5'd1, 1'b1, 8'h61);

        // --------------------------------------------------------
        // TEST 8: Lowercase shift 25
        // a + 25 = z
        // --------------------------------------------------------

        check_case(8'h61, 5'd25, 1'b1, 8'h7A);

        // --------------------------------------------------------
        // TEST 9: Shift = 0
        // Character must remain unchanged
        // --------------------------------------------------------

        check_case(8'h4D, 5'd0, 1'b1, 8'h4D);

        // --------------------------------------------------------
        // TEST 10: Maximum 5-bit shift
        // Z + 31 = E
        // --------------------------------------------------------

        check_case(8'h5A, 5'd31, 1'b1, 8'h45);

        // --------------------------------------------------------
        // TEST 11: Lowercase maximum shift
        // z + 31 = e
        // --------------------------------------------------------

        check_case(8'h7A, 5'd31, 1'b1, 8'h65);

        // --------------------------------------------------------
        // TEST 12: Space must remain unchanged
        // --------------------------------------------------------

        check_case(8'h20, 5'd5, 1'b1, 8'h20);

        // --------------------------------------------------------
        // TEST 13: Number must remain unchanged
        // --------------------------------------------------------

        check_case(8'h35, 5'd10, 1'b1, 8'h35);

        // --------------------------------------------------------
        // TEST 14: Punctuation must remain unchanged
        // --------------------------------------------------------

        check_case(8'h21, 5'd10, 1'b1, 8'h21);

        // --------------------------------------------------------
        // TEST 15: Boundary uppercase
        // Y + 2 = A
        // --------------------------------------------------------

        check_case(8'h59, 5'd2, 1'b1, 8'h41);

        // --------------------------------------------------------
        // TEST 16: Boundary lowercase
        // y + 2 = a
        // --------------------------------------------------------

        check_case(8'h79, 5'd2, 1'b1, 8'h61);

        $display("");
        $display("==============================================");
        $display("Total tests : %0d", test_count);
        $display("Total errors: %0d", error_count);

        if (error_count == 0)
            $display("CAESAR ENCRYPTION VERIFICATION: PASS");
        else
            $display("CAESAR ENCRYPTION VERIFICATION: FAIL");

        $display("==============================================");
        $display("");
        $finish;

    end

endmodule
