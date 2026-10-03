`timescale 1ns/1ps

module crypto_coverage (
    input logic        clk,
    input logic        reset,

    input logic        start,
    input logic        valid,

    input logic        mode,
    input logic [4:0]  shift_key,
    input logic [11:0] seed,
    input logic [7:0]  data_in,
    input logic [7:0]  data_out
);

    // ============================================================
    // MODE COVERAGE
    // ============================================================

    integer enc_count;
    integer dec_count;

    // ============================================================
    // SHIFT COVERAGE
    // ============================================================

    integer shift_zero_count;
    integer shift_low_count;
    integer shift_medium_count;
    integer shift_high_count;
    integer shift_invalid_count;

    // ============================================================
    // SEED COVERAGE
    // ============================================================

    integer seed_small_count;
    integer seed_medium_count;
    integer seed_large_count;

    // ============================================================
    // DATA COVERAGE
    // ============================================================

    integer uppercase_count;
    integer lowercase_count;
    integer space_count;
    integer digit_count;
    integer special_count;

    // ============================================================
    // MODE x DATA COVERAGE
    // ============================================================

    integer enc_upper_count;
    integer enc_lower_count;
    integer enc_space_count;
    integer enc_digit_count;
    integer enc_special_count;

    integer dec_upper_count;
    integer dec_lower_count;
    integer dec_space_count;
    integer dec_digit_count;
    integer dec_special_count;

    // ============================================================
    // TOTAL TRANSACTIONS
    // ============================================================

    integer total_transactions;

    // ============================================================
    // CAPTURE TRANSACTION INPUTS
    // ============================================================

    logic       mode_reg;
    logic [4:0] shift_reg;
    logic [11:0] seed_reg;
    logic [7:0] data_reg;

    // ============================================================
    // INITIALIZATION
    // ============================================================

    initial begin

        enc_count = 0;
        dec_count = 0;

        shift_zero_count    = 0;
        shift_low_count     = 0;
        shift_medium_count  = 0;
        shift_high_count    = 0;
        shift_invalid_count = 0;

        seed_small_count  = 0;
        seed_medium_count = 0;
        seed_large_count  = 0;

        uppercase_count = 0;
        lowercase_count = 0;
        space_count     = 0;
        digit_count     = 0;
        special_count   = 0;

        enc_upper_count  = 0;
        enc_lower_count  = 0;
        enc_space_count  = 0;
        enc_digit_count  = 0;
        enc_special_count = 0;

        dec_upper_count  = 0;
        dec_lower_count  = 0;
        dec_space_count  = 0;
        dec_digit_count  = 0;
        dec_special_count = 0;

        total_transactions = 0;

        mode_reg  = 1'b0;
        shift_reg = 5'd0;
        seed_reg  = 12'd0;
        data_reg  = 8'h00;

    end

    // ============================================================
    // CAPTURE INPUTS WHEN TRANSACTION STARTS
    // ============================================================

    always @(posedge clk) begin

        if (reset) begin

            mode_reg  <= 1'b0;
            shift_reg <= 5'd0;
            seed_reg  <= 12'd0;
            data_reg  <= 8'h00;

        end
        else if (start) begin

            mode_reg  <= mode;
            shift_reg <= shift_key;
            seed_reg  <= seed;
            data_reg  <= data_in;

        end

    end

    // ============================================================
    // COLLECT COVERAGE WHEN CRYPTO OPERATION COMPLETES
    // ============================================================

    always @(posedge clk) begin

        if (!reset && valid) begin

            total_transactions = total_transactions + 1;

            // ----------------------------------------------------
            // MODE
            // ----------------------------------------------------

            if (mode_reg == 1'b0)
                enc_count = enc_count + 1;
            else
                dec_count = dec_count + 1;

            // ----------------------------------------------------
            // SHIFT KEY
            // ----------------------------------------------------

            if (shift_reg == 0)

                shift_zero_count = shift_zero_count + 1;

            else if (shift_reg <= 8)

                shift_low_count = shift_low_count + 1;

            else if (shift_reg <= 17)

                shift_medium_count = shift_medium_count + 1;

            else if (shift_reg <= 25)

                shift_high_count = shift_high_count + 1;

            else

                shift_invalid_count = shift_invalid_count + 1;

            // ----------------------------------------------------
            // SEED
            // ----------------------------------------------------

            if ((seed_reg >= 12'd1) &&
                (seed_reg <= 12'd255))

                seed_small_count = seed_small_count + 1;

            else if (seed_reg <= 12'd2047)

                seed_medium_count = seed_medium_count + 1;

            else

                seed_large_count = seed_large_count + 1;

            // ----------------------------------------------------
            // DATA
            // ----------------------------------------------------

            if ((data_reg >= 8'h41) &&
                (data_reg <= 8'h5A)) begin

                uppercase_count = uppercase_count + 1;

                if (mode_reg == 1'b0)
                    enc_upper_count = enc_upper_count + 1;
                else
                    dec_upper_count = dec_upper_count + 1;

            end

            else if ((data_reg >= 8'h61) &&
                     (data_reg <= 8'h7A)) begin

                lowercase_count = lowercase_count + 1;

                if (mode_reg == 1'b0)
                    enc_lower_count = enc_lower_count + 1;
                else
                    dec_lower_count = dec_lower_count + 1;

            end

            else if (data_reg == 8'h20) begin

                space_count = space_count + 1;

                if (mode_reg == 1'b0)
                    enc_space_count = enc_space_count + 1;
                else
                    dec_space_count = dec_space_count + 1;

            end

            else if ((data_reg >= 8'h30) &&
                     (data_reg <= 8'h39)) begin

                digit_count = digit_count + 1;

                if (mode_reg == 1'b0)
                    enc_digit_count = enc_digit_count + 1;
                else
                    dec_digit_count = dec_digit_count + 1;

            end

            else begin

                special_count = special_count + 1;

                if (mode_reg == 1'b0)
                    enc_special_count = enc_special_count + 1;
                else
                    dec_special_count = dec_special_count + 1;

            end

        end

    end

    // ============================================================
    // FINAL COVERAGE REPORT
    // ============================================================

    final begin

        $display("");
        $display("==============================================");
        $display("          CRYPTO FUNCTIONAL COVERAGE");
        $display("==============================================");

        $display("");
        $display("MODE COVERAGE");
        $display("Encryption transactions : %0d", enc_count);
        $display("Decryption transactions : %0d", dec_count);

        $display("");
        $display("SHIFT KEY COVERAGE");
        $display("Zero    (0)      : %0d", shift_zero_count);
        $display("Low     (1-8)    : %0d", shift_low_count);
        $display("Medium  (9-17)   : %0d", shift_medium_count);
        $display("High    (18-25)  : %0d", shift_high_count);
        $display("Invalid (26-31)  : %0d", shift_invalid_count);

        $display("");
        $display("SEED COVERAGE");
        $display("Small  (1-255)     : %0d", seed_small_count);
        $display("Medium (256-2047)  : %0d", seed_medium_count);
        $display("Large  (2048-4095) : %0d", seed_large_count);

        $display("");
        $display("DATA COVERAGE");
        $display("Uppercase : %0d", uppercase_count);
        $display("Lowercase : %0d", lowercase_count);
        $display("Space     : %0d", space_count);
        $display("Digit     : %0d", digit_count);
        $display("Special   : %0d", special_count);

        $display("");
        $display("MODE x DATA COVERAGE");

        $display("ENC + Uppercase : %0d", enc_upper_count);
        $display("ENC + Lowercase : %0d", enc_lower_count);
        $display("ENC + Space     : %0d", enc_space_count);
        $display("ENC + Digit     : %0d", enc_digit_count);
        $display("ENC + Special   : %0d", enc_special_count);

        $display("DEC + Uppercase : %0d", dec_upper_count);
        $display("DEC + Lowercase : %0d", dec_lower_count);
        $display("DEC + Space     : %0d", dec_space_count);
        $display("DEC + Digit     : %0d", dec_digit_count);
        $display("DEC + Special   : %0d", dec_special_count);

        $display("");
        $display("TOTAL TRANSACTIONS : %0d", total_transactions);

        $display("");
        $display("==============================================");
        $display("          COVERAGE COLLECTION COMPLETE");
        $display("==============================================");
        $display("");

    end

endmodule