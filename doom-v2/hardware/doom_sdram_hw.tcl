package require -exact qsys 16.1
set_module_property NAME doom_sdram
set_module_property VERSION 1.0
set_module_property DISPLAY_NAME doom_sdram
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
add_fileset synth QUARTUS_SYNTH ""
set_fileset_property synth TOP_LEVEL doom_sdram
add_fileset_file doom_sdram.sv SYSTEM_VERILOG PATH ../rtl/doom_sdram.sv TOP_LEVEL_FILE
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
set_interface_property s readLatency 0
set_interface_property s readWaitTime 0
set_interface_property s writeWaitTime 0
set_interface_property s maximumPendingReadTransactions 1
set_interface_property s isMemoryDevice true
set_interface_property s bitsPerSymbol 8
set_interface_property s timingUnits Cycles
add_interface_port s address address Input 25
add_interface_port s read read Input 1
add_interface_port s write write Input 1
add_interface_port s writedata writedata Input 32
add_interface_port s byteenable byteenable Input 4
add_interface_port s readdata readdata Output 32
add_interface_port s waitrequest waitrequest Output 1
add_interface_port s readdatavalid readdatavalid Output 1
set_interface_assignment s embeddedsw.configuration.isMemoryDevice 1
set_interface_assignment s embeddedsw.configuration.isFlash 0
set_interface_assignment s embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment s embeddedsw.configuration.isPrintableDevice 0
add_interface pins conduit end
set_interface_property pins associatedClock clock
add_interface_port pins dram_addr addr Output 13
add_interface_port pins dram_ba ba Output 2
add_interface_port pins dram_cas_n cas_n Output 1
add_interface_port pins dram_ras_n ras_n Output 1
add_interface_port pins dram_we_n we_n Output 1
add_interface_port pins dram_cs_n cs_n Output 1
add_interface_port pins dram_cke cke Output 1
add_interface_port pins dram_dqm dqm Output 4
add_interface_port pins dram_dq dq Bidir 32
add_interface_port pins ready ready Output 1
