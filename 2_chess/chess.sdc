create_clock -name clk50 -period 20.000 [get_ports MAX10_CLK1_50]
derive_clock_uncertainty
# Buttons are asynchronous human inputs; KEY0 is synchronized in chess_top.
set_false_path -from [get_ports {KEY[*]}]
# VGA is an asynchronous external display, with registered RGB/sync outputs.
set_output_delay -clock clk50 -max 2.0 [get_ports {VGA_* LEDR[*]}]
set_output_delay -clock clk50 -min 0.0 [get_ports {VGA_* LEDR[*]}]
