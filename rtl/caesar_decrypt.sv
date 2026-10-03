`timescale 1ns/1ps

module caesar_decrypt (
    input  logic [7:0] data_in,
    input  logic [4:0] shift_key,
    input  logic       enable,
    output logic [7:0] data_out
);

    integer idx;
    integer shifted;
    integer key_value;

    always_comb begin

        // Default: input passes through unchanged
        data_out = data_in;

        idx       = 0;
        shifted   = 0;
        key_value = 0;

        // Convert 5-bit key to a signed integer value
        key_value = shift_key;

        if (enable) begin

            // ----------------------------------------------------
            // Uppercase A-Z
            // ----------------------------------------------------
            if ((data_in >= 8'h41) && (data_in <= 8'h5A)) begin

                idx = data_in - 8'h41;

                // Signed integer subtraction
                shifted = idx - key_value;

                // Normalize negative result
                shifted = shifted % 26;

                if (shifted < 0)
                    shifted = shifted + 26;

                data_out = 8'h41 + shifted;
            end

            // ----------------------------------------------------
            // Lowercase a-z
            // ----------------------------------------------------
            else if ((data_in >= 8'h61) && (data_in <= 8'h7A)) begin

                idx = data_in - 8'h61;

                // Signed integer subtraction
                shifted = idx - key_value;

                // Normalize negative result
                shifted = shifted % 26;

                if (shifted < 0)
                    shifted = shifted + 26;

                data_out = 8'h61 + shifted;
            end

            // ----------------------------------------------------
            // Non-alphabetic characters
            // ----------------------------------------------------
            else begin
                data_out = data_in;
            end

        end

    end

endmodule
