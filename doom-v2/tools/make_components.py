"""Emit Platform Designer descriptors with explicit bus timing and memory map."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
for name,aw,latency,pins in [
    ('doom_io',16,1,[('ps2_clk','Input',1),('ps2_dat','Input',1),('vga_r','Output',8),('vga_g','Output',8),('vga_b','Output',8),('vga_clk','Output',1),('vga_hs','Output',1),('vga_vs','Output',1),('vga_blank_n','Output',1),('vga_sync_n','Output',1)]),
    ('doom_sdram',25,0,[('addr','Output',13),('ba','Output',2),('cas_n','Output',1),('ras_n','Output',1),('we_n','Output',1),('cs_n','Output',1),('cke','Output',1),('dqm','Output',4),('dq','Bidir',32),('ready','Output',1)])]:
    lines=['package require -exact qsys 16.1',f'set_module_property NAME {name}','set_module_property VERSION 1.0',f'set_module_property DISPLAY_NAME {name}',
        'set_module_property INSTANTIATE_IN_SYSTEM_MODULE true','set_module_property EDITABLE false',
        'add_fileset synth QUARTUS_SYNTH ""',f'set_fileset_property synth TOP_LEVEL {name}',
        f'add_fileset_file {name}.sv SYSTEM_VERILOG PATH ../rtl/{name}.sv TOP_LEVEL_FILE']
    if name=='doom_io': lines+=['add_fileset_file ps2_receiver.sv SYSTEM_VERILOG PATH ../rtl/ps2_receiver.sv']
    lines+=['add_interface clock clock end','add_interface_port clock clk clk Input 1',
        'add_interface reset reset end','set_interface_property reset associatedClock clock',
        'set_interface_property reset synchronousEdges DEASSERT','add_interface_port reset reset reset Input 1',
        'add_interface s avalon end','set_interface_property s associatedClock clock','set_interface_property s associatedReset reset',
        'set_interface_property s addressUnits WORDS',f'set_interface_property s readLatency {latency}',
        'set_interface_property s readWaitTime 0','set_interface_property s writeWaitTime 0',
        'set_interface_property s maximumPendingReadTransactions '+('1' if name=='doom_sdram' else '0'),
        'set_interface_property s isMemoryDevice '+('true' if name=='doom_sdram' else 'false'),
        'set_interface_property s bitsPerSymbol 8','set_interface_property s timingUnits Cycles']
    for signal,direction,width in [('address','Input',aw),('read','Input',1),('write','Input',1),('writedata','Input',32),('byteenable','Input',4),('readdata','Output',32)]:
        lines.append(f'add_interface_port s {signal} {signal} {direction} {width}')
    if name=='doom_sdram':
        lines+=['add_interface_port s waitrequest waitrequest Output 1','add_interface_port s readdatavalid readdatavalid Output 1',
            'set_interface_assignment s embeddedsw.configuration.isMemoryDevice 1',
            'set_interface_assignment s embeddedsw.configuration.isFlash 0',
            'set_interface_assignment s embeddedsw.configuration.isNonVolatileStorage 0',
            'set_interface_assignment s embeddedsw.configuration.isPrintableDevice 0']
    lines+=['add_interface pins conduit end','set_interface_property pins associatedClock clock']
    for signal,direction,width in pins:
        port=('dram_'+signal if name=='doom_sdram' and signal!='ready' else signal)
        lines.append(f'add_interface_port pins {port} {signal} {direction} {width}')
    out=ROOT/'hardware';out.mkdir(exist_ok=True)
    (out/f'{name}_hw.tcl').write_text('\n'.join(lines)+'\n')
