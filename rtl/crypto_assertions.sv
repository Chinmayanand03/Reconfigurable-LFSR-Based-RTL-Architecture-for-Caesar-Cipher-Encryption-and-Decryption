`timescale 1ns/1ps

module crypto_assertions (
    input logic        clk,
    input logic        reset,

    input logic        seed_load,
    input logic [11:0] seed,

    input logic        start,
    input logic        busy,
    input logic        valid,

    input logic        execute,
    input logic        lfsr_enable,

    input logic [11:0] lfsr_state,
    input logic [7:0]  data_out
);

    // ---------------------------------------------------------
    // 1. After reset, core must not be busy or valid
    // ---------------------------------------------------------
    property p_reset_outputs;
        @(posedge clk)
        reset |=> (!busy && !valid);
    endproperty

    assert property (p_reset_outputs)
        else $error("ASSERTION FAILED: reset did not clear busy/valid");


    // ---------------------------------------------------------
    // 2. A start request must make the core busy
    // ---------------------------------------------------------
    property p_start_busy;
        @(posedge clk)
        disable iff (reset)
        start |=> busy;
    endproperty

    assert property (p_start_busy)
        else $error("ASSERTION FAILED: start did not cause busy");


    // ---------------------------------------------------------
    // 3. Execution must occur after start
    // ---------------------------------------------------------
    property p_start_execute;
        @(posedge clk)
        disable iff (reset)
        start |=> execute;
    endproperty

    assert property (p_start_execute)
        else $error("ASSERTION FAILED: start did not cause execute");


    // ---------------------------------------------------------
    // 4. Valid result must occur after execution
    // ---------------------------------------------------------
    property p_execute_valid;
        @(posedge clk)
        disable iff (reset)
        execute |=> valid;
    endproperty

    assert property (p_execute_valid)
        else $error("ASSERTION FAILED: execute did not produce valid");


    // ---------------------------------------------------------
    // 5. Valid must be a one-cycle pulse
    // ---------------------------------------------------------
    property p_valid_one_cycle;
        @(posedge clk)
        disable iff (reset)
        valid |=> !valid;
    endproperty

    assert property (p_valid_one_cycle)
        else $error("ASSERTION FAILED: valid is not one cycle");


    // ---------------------------------------------------------
    // 6. Valid result must occur while core is busy
    // ---------------------------------------------------------
    property p_valid_requires_busy;
        @(posedge clk)
        disable iff (reset)
        valid |-> busy;
    endproperty

    assert property (p_valid_requires_busy)
        else $error("ASSERTION FAILED: valid asserted while not busy");


    // ---------------------------------------------------------
    // 7. LFSR must never become zero
    // ---------------------------------------------------------
    property p_lfsr_nonzero;
        @(posedge clk)
        disable iff (reset)
        lfsr_enable |=> (lfsr_state != 12'h000);
    endproperty

    assert property (p_lfsr_nonzero)
        else $error("ASSERTION FAILED: LFSR entered zero state");


    // ---------------------------------------------------------
    // 8. Seed load must produce the requested seed
    //    Zero seed is mapped to 001 by the RTL
    // ---------------------------------------------------------
    property p_seed_load;
        @(posedge clk)
        disable iff (reset)
        seed_load |=> (lfsr_state ==
                       ((seed == 12'h000) ? 12'h001 : seed));
    endproperty

    assert property (p_seed_load)
        else $error("ASSERTION FAILED: incorrect LFSR seed load");


    // ---------------------------------------------------------
    // 9. LFSR should only advance during execution
    // ---------------------------------------------------------
    property p_no_lfsr_enable_when_idle;
        @(posedge clk)
        disable iff (reset)
        !execute |-> !lfsr_enable;
    endproperty

    assert property (p_no_lfsr_enable_when_idle)
        else $error("ASSERTION FAILED: LFSR enabled outside execution");


    // ---------------------------------------------------------
    // 10. Data output should be available with valid
    // ---------------------------------------------------------
    property p_valid_data;
        @(posedge clk)
        disable iff (reset)
        valid |-> !$isunknown(data_out);
    endproperty

    assert property (p_valid_data)
        else $error("ASSERTION FAILED: data_out unknown when valid");


    // ---------------------------------------------------------
    // 11. Busy should eventually clear after valid
    // ---------------------------------------------------------
    property p_valid_to_idle;
        @(posedge clk)
        disable iff (reset)
        valid |=> !busy;
    endproperty

    assert property (p_valid_to_idle)
        else $error("ASSERTION FAILED: busy did not clear after valid");


    // ---------------------------------------------------------
    // Assertion status
    // ---------------------------------------------------------
    final begin
        $display("");
        $display("==============================================");
        $display("          CRYPTO ASSERTION CHECK");
        $display("==============================================");
        $display("Assertions were enabled during simulation.");
        $display("==============================================");
    end

endmodule
