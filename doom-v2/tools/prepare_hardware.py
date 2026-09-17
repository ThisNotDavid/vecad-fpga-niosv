"""Create the reproducible project from the user's existing Nios V/g design."""
from pathlib import Path
import argparse, json, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--baseline',type=Path,default=Path('C:/FPGA/vecad-fpga-niosv/7_niosv_piece_control'))
    p.add_argument('--board-cd',type=Path,default=Path('C:/FPGA/DE2-115_v.3.0.6_SystemCD'))
    a=p.parse_args()
    out=ROOT/'hardware';out.mkdir(exist_ok=True)
    tree=ET.parse(a.baseline/'niosv_system.qsys');root=tree.getroot()
    for el in list(root):
        if el.tag=='interface' or (el.tag=='module' and el.get('name') in ('PIECE_ROW','PIECE_COL')) or (el.tag=='connection' and any(v.split('.')[0] in ('PIECE_ROW','PIECE_COL') for v in (el.get('start',''),el.get('end','')))):
            root.remove(el)
    for el in root.findall('parameter'):
        if el.get('name')=='projectName': el.set('value','doom_de2_115.qpf')
    def param(module,name,value):
        m=root.find(f"module[@name='{module}']")
        el=m.find(f"parameter[@name='{name}']")
        if el is None: el=ET.SubElement(m,'parameter',name=name)
        el.attrib.pop('value',None);el.text=None;el.set('value',str(value))
    param('SRAM','memorySize',16384)
    for name,value in {'instCacheSize':16384,'dataCacheSize':16384,'peripheralRegionABase':0x10000000,
        'peripheralRegionASize':0x40000,'peripheralRegionBBase':0x30000,'peripheralRegionBSize':4096}.items(): param('My_NiosV',name,value)
    for name in ('dataSlaveMapParam','instSlaveMapParam'): param('My_NiosV',name,'')
    # Reset instruction is a safe park loop until the debugger downloads an ELF.
    param('SRAM','initializationFileName','boot.mif')
    param('SRAM','useNonDefaultInitFile','true')
    for name,kind in [('SDRAM','doom_sdram'),('IO','doom_io')]:
        ET.SubElement(root,'module',name=name,kind=kind,version='1.0',enabled='1')
    def connect(kind,start,end,base=None):
        el=ET.SubElement(root,'connection',kind=kind,version='25.1',start=start,end=end)
        if base is not None: ET.SubElement(el,'parameter',name='baseAddress',value=hex(base))
    for name in ('SDRAM','IO'):
        connect('clock','clk_0.clk',name+'.clock')
        connect('reset','clk_0.clk_reset',name+'.reset')
    connect('avalon','My_NiosV.data_manager','IO.s',0x10000000)
    for master in ('instruction_manager','data_manager'):
        connect('avalon','My_NiosV.'+master,'SDRAM.s',0x08000000)
    for name,internal,typ in [('clk','clk_0.clk_in','clock'),('reset','clk_0.clk_in_reset','reset'),('io','IO.pins','conduit'),('dram','SDRAM.pins','conduit')]:
        ET.SubElement(root,'interface',name=name,internal=internal,type=typ,dir='end')
    # Replace debug-reset feedback with an external reset; CPU debug reset still
    # resets the system through an exported reset source handled in top-level.
    for el in list(root.findall('connection')):
        if el.get('start')=='My_NiosV.dbg_reset_out': root.remove(el)
    ET.SubElement(root,'interface',name='debug_reset',internal='My_NiosV.dbg_reset_out',type='reset',dir='start')
    order={'component':0,'parameter':1,'instanceScript':2,'interface':3,'module':4,'connection':5,'interconnectRequirement':6}
    root[:]=sorted(root,key=lambda el:order.get(el.tag,7))
    ET.indent(tree);tree.write(out/'doom_system.qsys',encoding='UTF-8',xml_declaration=True)
    # RISC-V jal x0,0 (0x0000006f), park at reset.
    (out/'boot.mif').write_text('WIDTH=32;\nDEPTH=4096;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN\n[0..FFF]: 0000006F;\nEND;\n')
    # Source board pins from the Terasic System CD; filter to actual top ports.
    golden=a.board_cd/'DE2_115_demonstrations/DE2_115_golden_top/DE2_115_GOLDEN_TOP.qsf'
    pins=[]
    import re
    for line in golden.read_text().splitlines():
        if not line.startswith(('set_location_assignment','set_instance_assignment')): continue
        m=re.search(r'-to\s+"?([^"\s]+)',line)
        if m and (m[1].split('[')[0] in ('CLOCK_50','DRAM_ADDR','DRAM_BA','DRAM_CAS_N','DRAM_CKE','DRAM_CLK','DRAM_CS_N','DRAM_DQ','DRAM_DQM','DRAM_RAS_N','DRAM_WE_N','VGA_R','VGA_G','VGA_B','VGA_HS','VGA_VS','VGA_CLK','VGA_BLANK_N','VGA_SYNC_N','PS2_CLK','PS2_DAT') or m[1]=='KEY[0]'):
            pins.append(re.sub(r'-to\s+"?([^"\s]+)"?',lambda m:'-to "'+m[1]+'"',line))
    if not any('DRAM_DQ[31]' in s for s in pins): raise RuntimeError('Incomplete board pin source')
    (out/'doom_de2_115.qpf').write_text('QUARTUS_VERSION = "25.1"\nPROJECT_REVISION = "doom_de2_115"\n')
    (out/'doom_de2_115.qsf').write_text('\n'.join([
        'set_global_assignment -name FAMILY "Cyclone IV E"',
        'set_global_assignment -name DEVICE EP4CE115F29C7',
        'set_global_assignment -name TOP_LEVEL_ENTITY doom_de2_115_top',
        'set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files',
        'set_global_assignment -name NUM_PARALLEL_PROCESSORS 4',
        'set_instance_assignment -name FAST_INPUT_REGISTER ON -to "DRAM_DQ[*]"',
        'set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"',
        'set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/doom_de2_115_top.sv',
        'set_global_assignment -name QIP_FILE doom_system/synthesis/doom_system.qip',
        'set_global_assignment -name SDC_FILE doom_de2_115.sdc',*pins])+'\n')
    (out/'baseline.json').write_text(json.dumps({'baseline':str(a.baseline),'cpu':'intel_niosv_g 4.0.0','clock_hz':50000000,'pin_source':str(golden)},indent=2))
    print(out/'doom_system.qsys')

if __name__=='__main__': main()
