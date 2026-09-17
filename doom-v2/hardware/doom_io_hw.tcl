package require -exact qsys 16.1
set_module_property NAME doom_io
set_module_property VERSION 1.0
set_module_property DISPLAY_NAME doom_io
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
add_fileset synth QUARTUS_SYNTH ""
set_fileset_property synth TOP_LEVEL doom_io
add_fileset_file doom_io.sv SYSTEM_VERILOG PATH ../rtl/doom_io.sv TOP_LEVEL_FILE
add_fileset_file ps2_receiver.sv SYSTEM_VERILOG PATH ../rtl/ps2_receiver.sv
add_interface clock clock end
add_interface_port clock clk clk Input 1
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
add_interface_port reset reset reset Input 1
add_interface s avalon end
set_interface_property s associatedClock clock
set_interface_property s associatedReset reset
set_interface_property s addressUnits WORDS
set_interface_property s readLatency 1
set_interface_property s readWaitTime 0
set_interface_property s writeWaitTime 0
set_interface_property s maximumPendingReadTransactions 0
set_interface_property s isMemoryDevice false
set_interface_property s bitsPerSymbol 8
set_interface_property s timingUnits Cycles
add_interface_port s address address Input 16
add_interface_port s read read Input 1
add_interface_port s write write Input 1
add_interface_port s writedata writedata Input 32
add_interface_port s byteenable byteenable Input 4
add_interface_port s readdata readdata Output 32
add_interface pins conduit end
set_interface_property pins associatedClock clock
add_interface_port pins ps2_clk ps2_clk Input 1
add_interface_port pins ps2_dat ps2_dat Input 1
add_interface_port pins vga_r vga_r Output 8
add_interface_port pins vga_g vga_g Output 8
add_interface_port pins vga_b vga_b Output 8
add_interface_port pins vga_clk vga_clk Output 1
add_interface_port pins vga_hs vga_hs Output 1
add_interface_port pins vga_vs vga_vs Output 1
add_interface_port pins vga_blank_n vga_blank_n Output 1
add_interface_port pins vga_sync_n vga_sync_n Output 1
