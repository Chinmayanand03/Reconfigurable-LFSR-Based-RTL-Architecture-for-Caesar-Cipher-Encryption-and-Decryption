`timescale 1ns/1ps

module tb_uart_receiver_fsm;

    localparam integer CLKS_PER_BIT = 434;

    logic clk;
    logic reset;
    logic rx;
    logic [7:0] data_out;
    logic data_valid;

    integer error_count;
    integer check_count;
    integer timeout_count;

    uart_receiver_fsm #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk       (clk),
        .reset     (reset),
        .rx        (rx),
        .data_out  (data_out),
        .data_valid(data_valid)
    );

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_uart_receiver_fsm);
    end

    task automatic send_bit(input logic bit_value);
        begin
            rx = bit_value;
            repeat (CLKS_PER_BIT)
                @(negedge clk);
        end
    endtask

    task automatic send_uart_byte(input logic [7:0] data);
        integer j;
        begin
            rx = 1'b1;
            repeat (CLKS_PER_BIT)
                @(negedge clk);
            send_bit(1'b0);
            for (j = 0; j < 8; j = j + 1)
                send_bit(data[j]);
            send_bit(1'b1);
            rx = 1'b1;
        end
    endtask

    task automatic wait_for_data(input logic [7:0] expected);
        integer timeout;
        begin
            timeout = 0;
            while ((data_valid !== 1'b1) && (timeout < (CLKS_PER_BIT * 12))) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (data_valid !== 1'b1) begin
                $display("FAIL: data_valid timeout. Expected=%02h", expected);
                error_count = error_count + 1;
            end
            else if (data_out !== expected) begin
                $display("FAIL: Expected=%02h Got=%02h", expected, data_out);
                error_count = error_count + 1;
            end
            else begin
                $display("PASS: Received=%02h", data_out);
            end

            check_count = check_count + 1;
        end
    endtask

    initial begin
        error_count   = 0;
        check_count   = 0;
        timeout_count = 0;

        reset = 1'b1;
        rx    = 1'b1;

        $display("");
        $display("==============================================");
        $display("       UART RECEIVER VERIFICATION");
        $display("==============================================");

        repeat (3) @(posedge clk);
        #1;

        if ((data_out === 8'h00) && (data_valid === 1'b0)) begin
            $display("PASS: Reset");
        end
        else begin
            $display("FAIL: Reset. data_out=%02h data_valid=%b", data_out, data_valid);
            error_count = error_count + 1;
        end

        reset = 1'b0;

        $display("");
        $display("----------------------------------------------");
        $display("RECEIVING DATA = 0xA5");
        $display("----------------------------------------------");
        fork
            send_uart_byte(8'hA5);
            wait_for_data(8'hA5);
        join

        repeat (CLKS_PER_BIT) @(posedge clk);

        $display("");
        $display("----------------------------------------------");
        $display("RECEIVING DATA = 0x3C");
        $display("----------------------------------------------");
        fork
            send_uart_byte(8'h3C);
            wait_for_data(8'h3C);
        join

        repeat (CLKS_PER_BIT) @(posedge clk);

        $display("");
        $display("----------------------------------------------");
        $display("RECEIVING DATA = 0x55");
        $display("----------------------------------------------");
        fork
            send_uart_byte(8'h55);
            wait_for_data(8'h55);
        join

        repeat (CLKS_PER_BIT) @(posedge clk);

        $display("");
        $display("----------------------------------------------");
        $display("RECEIVING DATA = 0x00");
        $display("----------------------------------------------");
        fork
            send_uart_byte(8'h00);
            wait_for_data(8'h00);
        join

        repeat (CLKS_PER_BIT) @(posedge clk);

        $display("");
        $display("----------------------------------------------");
        $display("RECEIVING DATA = 0xFF");
        $display("----------------------------------------------");
        fork
            send_uart_byte(8'hFF);
            wait_for_data(8'hFF);
        join

        $display("");
        $display("==============================================");
        $display("Total checks : %0d", check_count);
        $display("Total errors : %0d", error_count);

        if (error_count == 0)
            $display("UART RECEIVER VERIFICATION: PASS");
        else
            $display("UART RECEIVER VERIFICATION: FAIL");

        $display("==============================================");
        $display("");
        $finish;
    end

endmodule
