read_liberty sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog crypto_core_sky130_optimized.v
link_design crypto_core
create_clock -name clk -period 10.0 clk
set_input_delay -clock clk 2.0 {seed_load seed mode start data_in config_valid config_shift config_seed}
set_output_delay -clock clk 2.0 {data_out busy valid lfsr_state security_alert invalid_config}
set_false_path -from reset
all_clocks
check_setup -verbose
report_checks -path_delay max -format full_clock_expanded
report_checks -path_delay min -format full_clock_expanded
exit
