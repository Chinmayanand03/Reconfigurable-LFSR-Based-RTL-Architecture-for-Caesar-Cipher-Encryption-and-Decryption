`timescale 1ns/1ps

module tb_baud_tick_gen;

    logic clk;
    logic reset;
    logic tick;

    integer error_count;
    integer tick_count;
    integer clock_count;
    integer last_tick_cycle;
    integer current_tick_cycle;
    integer tick_period;

    localparam integer EXPECTED_DIVISOR = 434;

    baud_tick_gen dut (
        .clk   (clk),
        .reset (reset),
        .tick  (tick)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_baud_tick_gen);
    end

    initial begin
        error_count     = 0;
        tick_count      = 0;
        clock_count     = 0;
        last_tick_cycle = 0;
        current_tick_cycle = 0;
        tick_period     = 0;

        reset = 1'b1;

        $display("");
        $display("==============================================");
        $display("       BAUD TICK GENERATOR VERIFICATION");
        $display("==============================================");

        repeat (3) begin
            @(posedge clk);
            #1;
            if (tick !== 1'b0) begin
                $display("FAIL: Tick asserted during reset");
                error_count = error_count + 1;
            end
        end

        $display("PASS: Reset. Tick = 0");

        reset = 1'b0;

        repeat (2000) begin
            @(posedge clk);
            #1;
            clock_count = clock_count + 1;

            if (tick === 1'b1) begin
                tick_count = tick_count + 1;
                current_tick_cycle = clock_count;

                if (tick_count == 1) begin
                    $display("PASS: First tick at cycle %0d", current_tick_cycle);
                end
                else begin
                    tick_period = current_tick_cycle - last_tick_cycle;
                    if (tick_period == EXPECTED_DIVISOR) begin
                        $display("PASS: Tick %0d period = %0d clocks", tick_count, tick_period);
                    end
                    else begin
                        $display("FAIL: Tick %0d period = %0d clocks, expected %0d", tick_count, tick_period, EXPECTED_DIVISOR);
                        error_count = error_count + 1;
                    end
                end

                last_tick_cycle = current_tick_cycle;
            end
        end

        reset = 1'b1;
        @(posedge clk);
        #1;

        if (tick !== 1'b0) begin
            $display("FAIL: Tick not cleared by reset");
            error_count = error_count + 1;
        end
        else begin
            $display("PASS: Reset clears tick");
        end

        $display("");
        $display("==============================================");
        $display("Total ticks observed: %0d", tick_count);
        $display("Total errors        : %0d", error_count);

        if (error_count == 0)
            $display("BAUD TICK GENERATOR VERIFICATION: PASS");
        else
            $display("BAUD TICK GENERATOR VERIFICATION: FAIL");

        $display("==============================================");
        $display("");
        $finish;

    end

endmodule
