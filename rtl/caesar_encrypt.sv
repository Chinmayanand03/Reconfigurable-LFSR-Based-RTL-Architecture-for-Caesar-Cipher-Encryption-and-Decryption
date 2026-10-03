`timescale 1ns/1ps

module caesar_encrypt (
    input  logic [7:0] data_in,
    input  logic [4:0] shift_key,
    input  logic       enable,
    output logic [7:0] data_out
);

    integer idx;
    integer shifted;

    always_comb begin

        // Default: pass input unchanged
        data_out = data_in;

        idx     = 0;
        shifted = 0;

        if (enable) begin

            // Uppercase A-Z
            if ((data_in >= 8'h41) && (data_in <= 8'h5A)) begin

                idx = data_in - 8'h41;
                shifted = idx + shift_key;

                // Wrap around alphabet
                shifted = shifted % 26;

                data_out = 8'h41 + shifted;
            end

            // Lowercase a-z
            else if ((data_in >= 8'h61) && (data_in <= 8'h7A)) begin

                idx = data_in - 8'h61;
                shifted = idx + shift_key;

                // Wrap around alphabet
                shifted = shifted % 26;

                data_out = 8'h61 + shifted;
            end

            // Non-alphabetic characters remain unchanged
            else begin
                data_out = data_in;
            end

        end

    end

endmodule
