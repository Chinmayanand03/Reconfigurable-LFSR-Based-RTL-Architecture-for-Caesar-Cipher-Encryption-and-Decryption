`timescale 1ns/1ps

module tb_crypto_core;

    // ============================================================
    // DUT SIGNALS
    // ============================================================

    logic        clk;
    logic        reset;

    logic        seed_load;
    logic [11:0] seed;

    logic [4:0]  shift_key;
    logic        mode;
    logic        start;
    logic [7:0]  data_in;

    logic [7:0]  data_out;
    logic        busy;
    logic        valid;
    logic [11:0] lfsr_state;

    // Runtime configuration
    logic        config_valid;
    logic [4:0]  config_shift;
    logic [11:0] config_seed;

    // Security monitor
    logic        security_alert;
    logic        invalid_config;

    // ============================================================
    // TESTBENCH COUNTERS
    // ============================================================

    integer pass_count;
    integer error_count;

    integer enc_count;
    integer dec_count;

    integer shift_zero;
    integer shift_low;
    integer shift_medium;
    integer shift_high;
    integer shift_invalid;

    integer seed_small;
    integer seed_medium;
    integer seed_large;

    integer data_upper;
    integer data_lower;
    integer data_space;
    integer data_digit;
    integer data_special;

    integer enc_upper;
    integer enc_lower;
    integer enc_space;
    integer enc_digit;
    integer enc_special;

    integer dec_upper;
    integer dec_lower;
    integer dec_space;
    integer dec_digit;
    integer dec_special;

    integer assertion_errors;

    // ============================================================
    // DUT
    // ============================================================

    crypto_core dut (
        .clk            (clk),
        .reset          (reset),

        .seed_load      (seed_load),
        .seed           (seed),

        .shift_key      (shift_key),
        .mode           (mode),
        .start          (start),
        .data_in        (data_in),

        .data_out       (data_out),
        .busy           (busy),
        .valid          (valid),
        .lfsr_state     (lfsr_state),

        .config_valid   (config_valid),
        .config_shift   (config_shift),
        .config_seed    (config_seed),

        .security_alert (security_alert),
        .invalid_config (invalid_config)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // VCD WAVEFORM
    // ============================================================

    initial begin
        $dumpfile("crypto_core.vcd");
        $dumpvars(0, tb_crypto_core);
    end

    // ============================================================
    // RESET
    // ============================================================

    task automatic do_reset;
        begin
            reset          = 1'b1;

            seed_load      = 1'b0;
            seed           = 12'h001;

            shift_key      = 5'd0;
            mode           = 1'b0;
            start          = 1'b0;
            data_in        = 8'h00;

            config_valid   = 1'b0;
            config_shift   = 5'd0;
            config_seed    = 12'h001;

            repeat (2) @(posedge clk);

            reset = 1'b0;

            @(posedge clk);
            #1;
        end
    endtask

    // ============================================================
    // COVERAGE UPDATE
    // ============================================================

    task automatic update_coverage;
        input logic        mode_i;
        input logic [7:0]  data_i;
        input logic [4:0]  shift_i;
        input logic [11:0] seed_i;

        begin

            // MODE
            if (mode_i == 1'b0)
                enc_count = enc_count + 1;
            else
                dec_count = dec_count + 1;

            // SHIFT
            if (shift_i == 0)
                shift_zero = shift_zero + 1;
            else if (shift_i <= 8)
                shift_low = shift_low + 1;
            else if (shift_i <= 17)
                shift_medium = shift_medium + 1;
            else if (shift_i <= 25)
                shift_high = shift_high + 1;
            else
                shift_invalid = shift_invalid + 1;

            // SEED
            if (seed_i >= 12'd1 && seed_i <= 12'd255)
                seed_small = seed_small + 1;
            else if (seed_i <= 12'd2047)
                seed_medium = seed_medium + 1;
            else if (seed_i <= 12'd4095)
                seed_large = seed_large + 1;

            // DATA
            if (data_i >= 8'h41 && data_i <= 8'h5A) begin
                data_upper = data_upper + 1;

                if (mode_i == 1'b0)
                    enc_upper = enc_upper + 1;
                else
                    dec_upper = dec_upper + 1;
            end

            else if (data_i >= 8'h61 && data_i <= 8'h7A) begin
                data_lower = data_lower + 1;

                if (mode_i == 1'b0)
                    enc_lower = enc_lower + 1;
                else
                    dec_lower = dec_lower + 1;
            end

            else if (data_i == 8'h20) begin
                data_space = data_space + 1;

                if (mode_i == 1'b0)
                    enc_space = enc_space + 1;
                else
                    dec_space = dec_space + 1;
            end

            else if (data_i >= 8'h30 && data_i <= 8'h39) begin
                data_digit = data_digit + 1;

                if (mode_i == 1'b0)
                    enc_digit = enc_digit + 1;
                else
                    dec_digit = dec_digit + 1;
            end

            else begin
                data_special = data_special + 1;

                if (mode_i == 1'b0)
                    enc_special = enc_special + 1;
                else
                    dec_special = dec_special + 1;
            end

        end
    endtask

    // ============================================================
    // NORMAL CRYPTO TEST
    // ============================================================

    task automatic run_test;
        input logic        mode_i;
        input logic [7:0]  data_i;
        input logic [4:0]  shift_i;
        input logic [11:0] seed_i;
        input logic [7:0]  expected_i;

        begin

            // ----------------------------------------------------
            // Put test values on waveform
            // ----------------------------------------------------

            mode        = mode_i;
            data_in     = data_i;
            shift_key   = shift_i;

            seed        = seed_i;
            seed_load   = 1'b1;

            // Runtime configuration
            config_shift = shift_i;
            config_seed  = seed_i;
            config_valid = 1'b1;

            // ----------------------------------------------------
            // Apply configuration
            // ----------------------------------------------------

            @(posedge clk);
            #1;

            seed_load    = 1'b0;
            config_valid = 1'b0;

            // ----------------------------------------------------
            // Start crypto operation
            // ----------------------------------------------------

            start = 1'b1;

            @(posedge clk);
            #1;

            start = 1'b0;

            // ----------------------------------------------------
            // Wait for completion
            // ----------------------------------------------------

            @(posedge clk);
            #1;

            // ----------------------------------------------------
            // Check result
            // ----------------------------------------------------

            if (valid !== 1'b1) begin

                $display(
                    "ERROR: VALID not asserted Mode=%s Data=%02h",
                    (mode_i == 1'b0) ? "ENC" : "DEC",
                    data_i
                );

                error_count = error_count + 1;

            end

            if (data_out === expected_i) begin

                $display(
                    "PASS: Mode=%s Data=%02h Shift=%0d Seed=%03h Result=%02h",
                    (mode_i == 1'b0) ? "ENC" : "DEC",
                    data_i,
                    shift_i,
                    seed_i,
                    data_out
                );

                pass_count = pass_count + 1;

            end
            else begin

                $display(
                    "FAIL: Mode=%s Data=%02h Expected=%02h Actual=%02h",
                    (mode_i == 1'b0) ? "ENC" : "DEC",
                    data_i,
                    expected_i,
                    data_out
                );

                error_count = error_count + 1;

            end

            update_coverage(
                mode_i,
                data_i,
                shift_i,
                seed_i
            );

        end
    endtask

    // ============================================================
    // INITIALIZATION
    // ============================================================

    initial begin

        pass_count       = 0;
        error_count      = 0;

        enc_count        = 0;
        dec_count        = 0;

        shift_zero       = 0;
        shift_low        = 0;
        shift_medium     = 0;
        shift_high       = 0;
        shift_invalid    = 0;

        seed_small       = 0;
        seed_medium      = 0;
        seed_large       = 0;

        data_upper       = 0;
        data_lower       = 0;
        data_space       = 0;
        data_digit       = 0;
        data_special     = 0;

        enc_upper        = 0;
        enc_lower        = 0;
        enc_space        = 0;
        enc_digit        = 0;
        enc_special      = 0;

        dec_upper        = 0;
        dec_lower        = 0;
        dec_space        = 0;
        dec_digit        = 0;
        dec_special      = 0;

        assertion_errors = 0;

        do_reset();

        // ========================================================
        // HEADER
        // ========================================================

        $display("");
        $display("==============================================");
        $display("       CRYPTO CORE VERIFICATION");
        $display("==============================================");

        // ========================================================
        // DIRECTED TESTS
        // ========================================================

        $display("");
        $display("---- DIRECTED TESTS ----");

        run_test(1'b0, 8'h41,  0, 12'h001, 8'h42);
        run_test(1'b0, 8'h5A,  3, 12'h100, 8'h59);
        run_test(1'b0, 8'h61,  8, 12'h500, 8'h6F);
        run_test(1'b0, 8'h7A, 17, 12'h900, 8'h67);
        run_test(1'b0, 8'h20, 25, 12'hFFF, 8'h20);
        run_test(1'b0, 8'h35, 26, 12'h200, 8'h35);
        run_test(1'b0, 8'h21, 31, 12'h050, 8'h21);

        run_test(1'b1, 8'h41,  0, 12'h001, 8'h5A);
        run_test(1'b1, 8'h5A,  5, 12'h100, 8'h59);
        run_test(1'b1, 8'h61,  9, 12'h500, 8'h6C);
        run_test(1'b1, 8'h7A, 18, 12'h900, 8'h72);
        run_test(1'b1, 8'h20, 25, 12'hFFF, 8'h20);
        run_test(1'b1, 8'h35, 26, 12'h200, 8'h35);
        run_test(1'b1, 8'h21, 31, 12'h050, 8'h21);

        // ========================================================
        // RANDOMIZED / STRESS TESTS
        // ========================================================

        $display("");
        $display("---- RANDOMIZED TESTS ----");

        run_test(1'b0, 8'hC4,  2, 12'h69F, 8'hC4);
        run_test(1'b1, 8'hE4, 28, 12'hCE2, 8'hE4);
        run_test(1'b0, 8'hB6, 23, 12'h72F, 8'hB6);
        run_test(1'b1, 8'h53,  1, 12'h081, 8'h53);
        run_test(1'b0, 8'hC5,  2, 12'hEC4, 8'hC5);
        run_test(1'b1, 8'h35, 22, 12'h73D, 8'h35);
        run_test(1'b0, 8'hFD, 27, 12'hB88, 8'hFD);
        run_test(1'b1, 8'h58, 28, 12'hB91, 8'h59);
        run_test(1'b0, 8'h1E, 30, 12'h288, 8'h1E);
        run_test(1'b1, 8'hEE, 22, 12'h62C, 8'hEE);
        run_test(1'b0, 8'h63, 29, 12'hAE3, 8'h6B);
        run_test(1'b1, 8'h22,  1, 12'h608, 8'h22);
        run_test(1'b0, 8'h63, 15, 12'hACA, 8'h78);
        run_test(1'b1, 8'hCE, 17, 12'h1CC, 8'hCE);
        run_test(1'b0, 8'h9E, 14, 12'h9EB, 8'h9E);
        run_test(1'b1, 8'hA8, 27, 12'h1B8, 8'hA8);
        run_test(1'b0, 8'h94,  6, 12'h1B3, 8'h94);
        run_test(1'b1, 8'h1F,  3, 12'h335, 8'h1F);
        run_test(1'b0, 8'h1F,  5, 12'hAB6, 8'h1F);
        run_test(1'b1, 8'h33, 28, 12'h45F, 8'h33);
        run_test(1'b0, 8'hF3, 13, 12'hD23, 8'hF3);
        run_test(1'b1, 8'hCA,  7, 12'hC9F, 8'hCA);
        run_test(1'b0, 8'h24,  9, 12'hE25, 8'h24);
        run_test(1'b1, 8'h6D, 24, 12'h12A, 8'h63);
        run_test(1'b0, 8'hEA, 20, 12'h6D7, 8'hEA);
        run_test(1'b1, 8'h54, 29, 12'hE3D, 8'h4C);
        run_test(1'b0, 8'hB3, 21, 12'hD63, 8'hB3);
        run_test(1'b1, 8'h2E,  5, 12'h25E, 8'h2E);
        run_test(1'b0, 8'hD7, 22, 12'h8B7, 8'hD7);
        run_test(1'b1, 8'hAF, 29, 12'h924, 8'hAF);
        run_test(1'b0, 8'h3F, 10, 12'h347, 8'h3F);
        run_test(1'b1, 8'h77, 11, 12'h00A, 8'h62);

        // ========================================================
        // RUNTIME CONFIGURATION TEST
        // ========================================================

        $display("");
        $display("---- RUNTIME CONFIGURATION TEST ----");

        mode        = 1'b0;
        data_in     = 8'h41;

        config_shift = 5'd7;
        config_seed  = 12'h345;
        config_valid = 1'b1;

        @(posedge clk);
        #1;

        config_valid = 1'b0;

        // Check internal runtime registers
        if ((dut.runtime_shift === 5'd7) &&
            (dut.runtime_seed  === 12'h345) &&
            (lfsr_state        === 12'h345)) begin

            $display("PASS: Runtime configuration applied");
            $display("      Runtime Shift=%0d Seed=%03h",
                     dut.runtime_shift,
                     dut.runtime_seed);

            pass_count = pass_count + 1;

        end
        else begin

            $display("FAIL: Runtime configuration not applied");

            error_count = error_count + 1;

        end

        // ========================================================
        // SECURITY MONITOR TEST
        // ========================================================

        $display("");
        $display("---- SECURITY MONITOR TESTS ----");

        // Invalid shift
        config_shift = 5'd31;
        config_seed  = 12'h123;
        config_valid = 1'b1;

        @(posedge clk);
        #1;

        if ((invalid_config === 1'b1) &&
            (security_alert === 1'b1)) begin

            $display("PASS: Invalid configuration detected");

            pass_count = pass_count + 1;

        end
        else begin

            $display("FAIL: Invalid configuration NOT detected");

            error_count = error_count + 1;

        end

        config_valid = 1'b0;

        @(posedge clk);
        #1;

        // Zero seed
        config_shift = 5'd5;
        config_seed  = 12'h000;
        config_valid = 1'b1;

        @(posedge clk);
        #1;

        if (security_alert === 1'b1) begin

            $display("PASS: Zero-seed security condition detected");

            pass_count = pass_count + 1;

        end
        else begin

            $display("FAIL: Zero-seed security condition NOT detected");

            error_count = error_count + 1;

        end

        config_valid = 1'b0;

        // ========================================================
        // BUSY CONFIGURATION TEST
        // ========================================================

        $display("");
        $display("---- BUSY CONFIGURATION TEST ----");

        // First load a valid configuration
        config_shift = 5'd4;
        config_seed  = 12'h222;
        config_valid = 1'b1;

        @(posedge clk);
        #1;

        config_valid = 1'b0;

        // Start transaction
        mode    = 1'b0;
        data_in = 8'h41;
        start   = 1'b1;

        @(posedge clk);
        #1;

        start = 1'b0;

        // At this point DUT should be busy
        if (busy === 1'b1) begin

            $display("PASS: Core entered busy state");

            pass_count = pass_count + 1;

        end
        else begin

            $display("FAIL: Core did not enter busy state");

            error_count = error_count + 1;

        end

        // --------------------------------------------------------
        // Attempt configuration while BUSY
        // --------------------------------------------------------

        config_shift = 5'd8;
        config_seed  = 12'h456;
        config_valid = 1'b1;

        @(posedge clk);
        #1;

        if (security_alert === 1'b1) begin

            $display("PASS: Configuration-while-busy detected");

            pass_count = pass_count + 1;

        end
        else begin

            $display("FAIL: Configuration-while-busy NOT detected");

            error_count = error_count + 1;

        end

        config_valid = 1'b0;

        // Wait for crypto transaction to finish
        @(posedge clk);
        #1;

        // ========================================================
        // ASSERTION CHECK SUMMARY
        // ========================================================

        $display("");
        $display("==============================================");
        $display("          CRYPTO ASSERTION CHECK");
        $display("==============================================");

        if (assertion_errors == 0)
            $display("Assertions were checked during simulation.");
        else
            $display("Assertion errors = %0d", assertion_errors);

        $display("==============================================");

        // ========================================================
        // FUNCTIONAL COVERAGE
        // ========================================================

        $display("");
        $display("==============================================");
        $display("       CRYPTO FUNCTIONAL COVERAGE");
        $display("==============================================");

        $display("");
        $display("MODE COVERAGE");
        $display("Encryption transactions : %0d", enc_count);
        $display("Decryption transactions : %0d", dec_count);

        $display("");
        $display("SHIFT KEY COVERAGE");
        $display("Zero    (0)      : %0d", shift_zero);
        $display("Low     (1-8)    : %0d", shift_low);
        $display("Medium  (9-17)   : %0d", shift_medium);
        $display("High    (18-25)  : %0d", shift_high);
        $display("Invalid (26-31)  : %0d", shift_invalid);

        $display("");
        $display("SEED COVERAGE");
        $display("Small  (1-255)     : %0d", seed_small);
        $display("Medium (256-2047)  : %0d", seed_medium);
        $display("Large  (2048-4095) : %0d", seed_large);

        $display("");
        $display("DATA COVERAGE");
        $display("Uppercase : %0d", data_upper);
        $display("Lowercase : %0d", data_lower);
        $display("Space     : %0d", data_space);
        $display("Digit     : %0d", data_digit);
        $display("Special   : %0d", data_special);

        $display("");
        $display("MODE x DATA COVERAGE");
        $display("ENC + Uppercase : %0d", enc_upper);
        $display("ENC + Lowercase : %0d", enc_lower);
        $display("ENC + Space     : %0d", enc_space);
        $display("ENC + Digit     : %0d", enc_digit);
        $display("ENC + Special   : %0d", enc_special);

        $display("DEC + Uppercase : %0d", dec_upper);
        $display("DEC + Lowercase : %0d", dec_lower);
        $display("DEC + Space     : %0d", dec_space);
        $display("DEC + Digit     : %0d", dec_digit);
        $display("DEC + Special   : %0d", dec_special);

        $display("");
        $display("----------------------------------------------");
        $display("TOTAL CRYPTO TESTS : %0d", 46);
        $display("PASS                : %0d", pass_count);
        $display("ERRORS              : %0d", error_count);
        $display("----------------------------------------------");

        if ((error_count == 0) && (assertion_errors == 0))
            $display("CRYPTO VERIFICATION: PASS");
        else
            $display("CRYPTO VERIFICATION: FAIL");

        $display("==============================================");

        #20;
        $finish;

    end

    // ============================================================
    // SIMPLE ASSERTIONS
    // ============================================================
    //
    // These are written as immediate assertions so they work
    // cleanly with Verilator.
    //
    // ============================================================

    always @(posedge clk) begin
        #1;

        // valid should never be high while busy
        if (valid === 1'b1) begin

            assert (busy === 1'b0)
            else begin
                $display("ASSERTION ERROR: valid asserted while busy");
                assertion_errors = assertion_errors + 1;
            end

        end

        // invalid configuration must generate security alert
        if (invalid_config === 1'b1) begin

            assert (security_alert === 1'b1)
            else begin
                $display("ASSERTION ERROR: invalid_config without security_alert");
                assertion_errors = assertion_errors + 1;
            end

        end

    end

endmodule