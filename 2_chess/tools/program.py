"""Verify the build and target, then load volatile FPGA SRAM over USB-Blaster."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from board_config import BOARDS
ROOT=Path(__file__).resolve().parents[1]
def main():
    p=argparse.ArgumentParser()
    p.add_argument('--quartus-root',default='C:/altera_lite/25.1std')
    p.add_argument('--cable',default='USB-Blaster [USB-0]')
    p.add_argument('--board',choices=BOARDS,default='de10-lite')
    args=p.parse_args()
    cfg=BOARDS[args.board];sof=ROOT/cfg['output']/(cfg['project']+'.sof')
    manifest_path=ROOT/cfg['output']/'build_manifest.json'
    if not manifest_path.exists():p.error('No verified build manifest. Run tools/build.py first.')
    for name,expected in json.loads(manifest_path.read_text()).items():
        f=ROOT/name
        if not f.is_file() or hashlib.sha256(f.read_bytes()).hexdigest()!=expected:
            p.error(f'{name} changed since the verified build; rebuild before programming.')
    binary=Path(args.quartus_root)/'quartus/bin64'
    chain=subprocess.run([str(binary/'jtagconfig.exe')],capture_output=True,text=True,check=True)
    print(chain.stdout)
    # Single board is intentional: avoid programming the wrong device in a lab.
    devices=re.findall(r'^\s+([0-9A-Fa-f]{8})\s+',chain.stdout,re.M)
    cables=re.findall(r'^\d+\)',chain.stdout,re.M)
    if len(cables)!=1 or [d.upper() for d in devices]!=[cfg['idcode']]:
        p.error(f'Expected one {args.board} ({cfg["idcode"]}). Resolve the JTAG chain before programming.')
    subprocess.run([str(binary/'quartus_pgm.exe'),'-m','jtag','-c',args.cable,
                    '-o',f'p;{sof}@1'],check=True)
    print(f'Loaded {sof.name} into volatile SRAM. No configuration flash was changed.')
    return 0
if __name__=='__main__':sys.exit(main())
