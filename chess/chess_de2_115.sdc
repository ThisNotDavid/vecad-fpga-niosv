create_clock -name clk50 -period 20.000 [get_ports CLOCK_50]
# 25 MHz forwarded DAC clock changes at the falling edge of CLOCK_50.
create_generated_clock -name vga_dac_internal -source [get_ports CLOCK_50] -edges {2 4 6} [get_registers {*video_output|VGA_CLK}]
# Propagate the forwarded clock through its output pad, so I/O timing includes
# the actual clock-pin insertion delay rather than assuming zero latency.
create_generated_clock -name vga_dac -source [get_registers {*video_output|VGA_CLK}] -divide_by 1 [get_ports VGA_CLK]
derive_clock_uncertainty
# Only asynchronous external sources are excluded; synchronizer-to-logic paths
# remain timed. PS/2 data/clock are sampled by two-register synchronizers.
set_false_path -from [get_ports {KEY[0] PS2_CLK PS2_DAT}]
# ADV7123 setup 0.2 ns / hold 1.5 ns; use 2 ns including routing margin.
set_output_delay -clock vga_dac -max 2.0 [get_ports {VGA_R[*] VGA_G[*] VGA_B[*] VGA_BLANK_N VGA_SYNC_N}]
set_output_delay -clock vga_dac -min -2.0 [get_ports {VGA_R[*] VGA_G[*] VGA_B[*] VGA_BLANK_N VGA_SYNC_N}]
set_output_delay -clock clk50 -max 2.0 [get_ports {VGA_HS VGA_VS LEDR[*]}]
set_output_delay -clock clk50 -min 0.0 [get_ports {VGA_HS VGA_VS LEDR[*]}]
