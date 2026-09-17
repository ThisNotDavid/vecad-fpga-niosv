"""Create a portable Quartus project using the selected local installation."""
from pathlib import Path
import argparse
from board_config import BOARDS,pins_for,io_standard

ROOT=Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--quartus-root',default='C:/altera_lite/25.1std')
    parser.add_argument('--board',choices=BOARDS,default='de10-lite')
    args=parser.parse_args()
    install=Path(args.quartus_root)
    ip=install/'ip/altera/sopc_builder_ip/altera_avalon_jtag_uart'
    if args.board=='de10-lite' and not (ip/'altera_avalon_jtag_uart.sv').is_file():
        parser.error(f'JTAG UART IP not found under {install}')
    cfg=BOARDS[args.board];project=cfg['project']
    lines=[f'set_global_assignment -name FAMILY "{cfg["family"]}"',
        f'set_global_assignment -name DEVICE {cfg["device"]}',
        f'set_global_assignment -name TOP_LEVEL_ENTITY {cfg["top"]}',
        f'set_global_assignment -name PROJECT_OUTPUT_DIRECTORY {cfg["output"]}',
        'set_global_assignment -name NUM_PARALLEL_PROCESSORS 4',
        'set_global_assignment -name SEARCH_PATH rtl',
        f'set_global_assignment -name SDC_FILE {project}.sdc',
        'set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"']
    for f in cfg['sources']:
        lines.append(f'set_global_assignment -name SYSTEMVERILOG_FILE rtl/{f}.sv')
    for f in (['altera_avalon_jtag_uart','altera_avalon_jtag_uart_scfifo_r','altera_avalon_jtag_uart_scfifo_w'] if args.board=='de10-lite' else []):
        lines.append(f'set_global_assignment -name SYSTEMVERILOG_FILE "{(ip/(f+".sv")).as_posix()}"')
    for name,pin in pins_for(args.board).items():
        lines.append(f'set_location_assignment PIN_{pin} -to "{name}"')
        standard=io_standard(args.board,name)
        lines.append(f'set_instance_assignment -name IO_STANDARD "{standard}" -to "{name}"')
    (ROOT/f'{project}.qsf').write_text('\n'.join(lines)+'\n')
    (ROOT/f'{project}.qpf').write_text(f'QUARTUS_VERSION = "25.1"\nPROJECT_REVISION = "{project}"\n')
    print(f'Created {project}.qpf and .qsf for',install)

if __name__=='__main__': main()
