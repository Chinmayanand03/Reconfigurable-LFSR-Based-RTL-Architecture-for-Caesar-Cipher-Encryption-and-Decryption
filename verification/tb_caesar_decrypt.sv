`timescale 1ns/1ps

module tb_caesar_decrypt;

    logic [7:0] data_in;
    logic [4:0] shift_key;
    logic       enable;
    logic [7:0] data_out;

    integer error_count;
    integer test_count;

    caesar_decrypt dut (
        .data_in   (data_in),
        .shift_key (shift_key),
        .enable    (enable),
        .data_out  (data_out)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_caesar_decrypt);
    end

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
                    test_data, test_shift, test_enable, expected_data, data_out
                );
                error_count = error_count + 1;
            end
            else begin
                $display(
                    "PASS: Input=%02h Shift=%0d Enable=%b Output=%02h",
                    test_data, test_shift, test_enable, data_out
                );
            end
        end
    endtask

    initial begin
        error_count = 0;
        test_count  = 0;
        data_in   = 8'h00;
        shift_key = 5'd0;
        enable    = 1'b0;

        $display("");
        $display("==============================================");
        $display("       CAESAR DECRYPTION VERIFICATION");
        $display("==============================================");

        check_case(8'h44, 5'd3, 1'b0, 8'h44);
        check_case(8'h44, 5'd3, 1'b1, 8'h41);
        check_case(8'h48, 5'd5, 1'b1, 8'h43);
        check_case(8'h41, 5'd1, 1'b1, 8'h5A);
        check_case(8'h5A, 5'd25, 1'b1, 8'h41);
        check_case(8'h64, 5'd3, 1'b1, 8'h61);
        check_case(8'h61, 5'd1, 1'b1, 8'h7A);
        check_case(8'h7A, 5'd25, 1'b1, 8'h61);
        check_case(8'h4D, 5'd0, 1'b1, 8'h4D);
        check_case(8'h45, 5'd31, 1'b1, 8'h5A);
        check_case(8'h65, 5'd31, 1'b1, 8'h7A);
        check_case(8'h20, 5'd5, 1'b1, 8'h20);
        check_case(8'h35, 5'd10, 1'b1, 8'h35);
        check_case(8'h21, 5'd10, 1'b1, 8'h21);
        check_case(8'h41, 5'd2, 1'b1, 8'h59);
        check_case(8'h61, 5'd2, 1'b1, 8'h79);

        $display("");
        $display("==============================================");
        $display("Total tests : %0d", test_count);
        $display("Total errors: %0d", error_count);

        if (error_count == 0)
            $display("CAESAR DECRYPTION VERIFICATION: PASS");
        else
            $display("CAESAR DECRYPTION VERIFICATION: FAIL");

        $display("==============================================");
        $display("");
        $finish;
    end

endmodule
