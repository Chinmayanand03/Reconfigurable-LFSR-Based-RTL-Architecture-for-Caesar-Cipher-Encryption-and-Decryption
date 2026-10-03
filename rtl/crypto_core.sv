`timescale 1ns/1ps

module crypto_core (
    input  logic        clk,
    input  logic        reset,

    input  logic        seed_load,
    input  logic [11:0] seed,

    input  logic [4:0]  shift_key,
    input  logic        mode,
    input  logic        start,
    input  logic [7:0]  data_in,

    output logic [7:0]  data_out,
    output logic        busy,
    output logic        valid,
    output logic [11:0] lfsr_state,

    input  logic        config_valid,
    input  logic [4:0]  config_shift,
    input  logic [11:0] config_seed,

    output logic        security_alert,
    output logic        invalid_config
);

    logic [4:0]  runtime_shift;
    logic [11:0] runtime_seed;

    integer key;
    integer temp;
    integer result;


    // ============================================================
    // 12-BIT LFSR
    // Polynomial:
    // x^12 + x^11 + x^10 + x^4 + 1
    // ============================================================

    function automatic [11:0] lfsr_next(
        input [11:0] current
    );
        begin
            if (current == 12'h000)
                lfsr_next = 12'h001;
            else
                lfsr_next = {
                    current[10:0],
                    current[11] ^
                    current[10] ^
                    current[9]  ^
                    current[3]
                };
        end
    endfunction


    // ============================================================
    // ENCRYPTION
    // ============================================================

    function automatic [7:0] encrypt_byte(
        input [7:0] data,
        input integer k
    );
        begin
            if ((data >= 8'h41) && (data <= 8'h5A)) begin
                result = ((data - 8'h41) + k) % 26;
                encrypt_byte = 8'h41 + result;
            end
            else if ((data >= 8'h61) && (data <= 8'h7A)) begin
                result = ((data - 8'h61) + k) % 26;
                encrypt_byte = 8'h61 + result;
            end
            else begin
                encrypt_byte = data;
            end
        end
    endfunction


    // ============================================================
    // DECRYPTION
    // ============================================================

    function automatic [7:0] decrypt_byte(
        input [7:0] data,
        input integer k
    );
        begin
            if ((data >= 8'h41) && (data <= 8'h5A)) begin

                temp = (data - 8'h41) - k;

                while (temp < 0)
                    temp = temp + 26;

                decrypt_byte = 8'h41 + temp;
            end
            else if ((data >= 8'h61) && (data <= 8'h7A)) begin

                temp = (data - 8'h61) - k;

                while (temp < 0)
                    temp = temp + 26;

                decrypt_byte = 8'h61 + temp;
            end
            else begin
                decrypt_byte = data;
            end
        end
    endfunction


    // ============================================================
    // MAIN CRYPTO CORE
    // ============================================================

    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin

            runtime_shift <= 5'd0;
            runtime_seed  <= 12'h001;

            lfsr_state    <= 12'h001;

            data_out      <= 8'h00;
            busy          <= 1'b0;
            valid         <= 1'b0;

        end
        else begin

            // valid is a one-cycle pulse
            valid <= 1'b0;


            // ====================================================
            // RUNTIME RECONFIGURATION
            // ====================================================

            if (config_valid && !busy) begin

                runtime_shift <= config_shift;

                if (config_seed == 12'h000)
                    runtime_seed <= 12'h001;
                else
                    runtime_seed <= config_seed;

                if (config_seed == 12'h000)
                    lfsr_state <= 12'h001;
                else
                    lfsr_state <= config_seed;

            end


            // ====================================================
            // LEGACY SEED LOAD
            // ====================================================

            if (seed_load && !busy) begin

                if (seed == 12'h000) begin
                    runtime_seed <= 12'h001;
                    lfsr_state   <= 12'h001;
                end
                else begin
                    runtime_seed <= seed;
                    lfsr_state   <= seed;
                end

            end


            // ====================================================
            // START CRYPTO TRANSACTION
            // ====================================================

            if (start && !busy) begin

                busy <= 1'b1;

                // LFSR-derived dynamic Caesar key
                key = (lfsr_state + runtime_shift) % 26;

                if (mode == 1'b0)
                    data_out <= encrypt_byte(data_in, key);
                else
                    data_out <= decrypt_byte(data_in, key);

            end


            // ====================================================
            // COMPLETE TRANSACTION
            // ====================================================

            else if (busy) begin

                busy  <= 1'b0;
                valid <= 1'b1;

                // Advance LFSR after every transaction
                lfsr_state <= lfsr_next(lfsr_state);

            end

        end

    end


    // ============================================================
    // SECURITY MONITOR
    // ============================================================

    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin

            security_alert <= 1'b0;
            invalid_config <= 1'b0;

        end
        else begin

            // One-cycle pulses
            security_alert <= 1'b0;
            invalid_config <= 1'b0;


            // Invalid Caesar shift
            if (config_valid && (config_shift > 5'd25)) begin

                invalid_config <= 1'b1;
                security_alert <= 1'b1;

            end


            // Zero seed
            if (config_valid && (config_seed == 12'h000)) begin

                security_alert <= 1'b1;

            end


            // Runtime configuration while busy
            if (config_valid && busy) begin

                security_alert <= 1'b1;

            end

        end

    end

endmodule
