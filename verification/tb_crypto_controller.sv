`timescale 1ns/1ps

module tb_crypto_controller;

    logic clk;
    logic reset;
    logic start;

    logic busy;
    logic execute;
    logic valid;
    logic lfsr_enable;

    integer error_count;
    integer test_count;

    crypto_controller dut (
        .clk         (clk),
        .reset       (reset),
        .start       (start),
        .busy        (busy),
        .execute     (execute),
        .valid       (valid),
        .lfsr_enable (lfsr_enable)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_crypto_controller);
    end

    task automatic check_outputs(
        input logic expected_busy,
        input logic expected_execute,
        input logic expected_valid,
        input logic expected_lfsr_enable
    );
        begin
            test_count = test_count + 1;
            if ((busy !== expected_busy) ||
                (execute !== expected_execute) ||
                (valid !== expected_valid) ||
                (lfsr_enable !== expected_lfsr_enable)) begin
                $display(
                    "FAIL: busy=%b execute=%b valid=%b lfsr_enable=%b | Expected: busy=%b execute=%b valid=%b lfsr_enable=%b",
                    busy, execute, valid, lfsr_enable,
                    expected_busy, expected_execute, expected_valid, expected_lfsr_enable
                );
                error_count = error_count + 1;
            end
            else begin
                $display(
                    "PASS: busy=%b execute=%b valid=%b lfsr_enable=%b",
                    busy, execute, valid, lfsr_enable
                );
            end
        end
    endtask

    initial begin
        error_count = 0;
        test_count  = 0;
        reset = 1'b1;
        start = 1'b0;

        $display("");
        $display("==============================================");
        $display("       CRYPTO CONTROLLER VERIFICATION");
        $display("==============================================");

        @(posedge clk); #1;
        check_outputs(1'b0,1'b0,1'b0,1'b0);

        reset = 1'b0;
        #1;
        check_outputs(1'b0,1'b0,1'b0,1'b0);

        start = 1'b1;
        @(posedge clk); #1;
        check_outputs(1'b1,1'b1,1'b0,1'b0);
        start = 1'b0;

        @(posedge clk); #1;
        check_outputs(1'b0,1'b0,1'b1,1'b1);

        @(posedge clk); #1;
        check_outputs(1'b0,1'b0,1'b0,1'b0);

        start = 1'b1;
        @(posedge clk); #1;
        check_outputs(1'b1,1'b1,1'b0,1'b0);
        start = 1'b0;

        @(posedge clk); #1;
        check_outputs(1'b0,1'b0,1'b1,1'b1);

        @(posedge clk); #1;
        check_outputs(1'b0,1'b0,1'b0,1'b0);

        repeat (3) begin
            @(posedge clk); #1;
            check_outputs(1'b0,1'b0,1'b0,1'b0);
        end

        $display("");
        $display("==============================================");
        $display("Total tests : %0d", test_count);
        $display("Total errors: %0d", error_count);

        if (error_count == 0)
            $display("CRYPTO CONTROLLER VERIFICATION: PASS");
        else
            $display("CRYPTO CONTROLLER VERIFICATION: FAIL");

        $display("==============================================");
        $display("");
        $finish;
    end

endmodule
