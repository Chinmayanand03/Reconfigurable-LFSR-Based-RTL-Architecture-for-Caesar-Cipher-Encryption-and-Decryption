create_clock -name clk -period 10.0 clk
set_input_delay -clock clk 2.0 {seed_load seed mode start data_in config_valid config_shift config_seed}
set_output_delay -clock clk 2.0 {data_out busy valid lfsr_state security_alert invalid_config}
set_false_path -from reset
