`timescale 1ns/1ps

module tb_lfsr_12bit;

    logic        clk;
    logic        reset;
    logic        seed_load;
    logic [11:0] seed;
    logic        enable;
    logic [11:0] state;

    integer error_count;
    integer i;

    logic [11:0] previous_state;

    lfsr_12bit dut (
        .clk       (clk),
        .reset     (reset),
        .seed_load (seed_load),
        .seed      (seed),
        .enable    (enable),
        .state     (state)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        error_count = 0;
        reset     = 1'b1;
        seed_load = 1'b0;
        seed      = 12'hACE;
        enable    = 1'b0;

        $display("");
        $display("==============================================");
        $display("       12-BIT LFSR VERIFICATION");
        $display("==============================================");

        @(posedge clk); #1;
        if (state !== 12'h001) begin
            $display("FAIL: Reset. Expected 001, Got %03h", state);
            error_count = error_count + 1;
        end
        else
            $display("PASS: Reset. State = %03h", state);

        reset = 1'b0;
        seed = 12'hACE;
        seed_load = 1'b1;
        @(posedge clk); #1;
        seed_load = 1'b0;
        if (state !== 12'hACE) begin
            $display("FAIL: Seed load. Expected ACE, Got %03h", state);
            error_count = error_count + 1;
        end
        else
            $display("PASS: Seed load. State = %03h", state);

        enable = 1'b0;
        previous_state = state;
        @(posedge clk); #1;
        if (state !== previous_state) begin
            $display("FAIL: Enable=0. State changed from %03h to %03h", previous_state, state);
            error_count = error_count + 1;
        end
        else
            $display("PASS: Enable=0. State held at %03h", state);

        enable = 1'b1;
        previous_state = state;
        @(posedge clk); #1;
        if (state === previous_state) begin
            $display("FAIL: Enable=1. LFSR state did not change");
            error_count = error_count + 1;
        end
        else
            $display("PASS: Enable=1. %03h -> %03h", previous_state, state);

        seed_load = 1'b1;
        seed = 12'hACE;
        @(posedge clk); #1;
        seed_load = 1'b0;
        enable = 1'b1;
        for (i = 0; i < 100; i = i + 1) begin
            @(posedge clk); #1;
            if (state === 12'h000) begin
                $display("FAIL: Zero state reached at cycle %0d", i);
                error_count = error_count + 1;
            end
        end
        if (state !== 12'h000)
            $display("PASS: No zero state detected during 100 cycles");

        enable = 1'b0;
        seed = 12'h123;
        seed_load = 1'b1;
        @(posedge clk); #1;
        seed_load = 1'b0;
        if (state !== 12'h123) begin
            $display("FAIL: Second seed load. Expected 123, Got %03h", state);
            error_count = error_count + 1;
        end
        else
            $display("PASS: Second seed load. State = %03h", state);

        seed = 12'h000;
        seed_load = 1'b1;
        @(posedge clk); #1;
        seed_load = 1'b0;
        if (state !== 12'h001) begin
            $display("FAIL: Zero seed protection. Expected 001, Got %03h", state);
            error_count = error_count + 1;
        end
        else
            $display("PASS: Zero seed protection. State = %03h", state);

        $display("");
        $display("==============================================");
        if (error_count == 0)
            $display("LFSR VERIFICATION: PASS");
        else
            $display("LFSR VERIFICATION: FAIL (%0d errors)", error_count);
        $display("==============================================");
        $display("");
        $finish;
    end

endmodule
