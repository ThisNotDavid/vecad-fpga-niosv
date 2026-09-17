"""Compile from a temporary local directory; run outside restrictive sandboxes."""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import re
import hashlib
import json
from board_config import BOARDS,pins_for

ROOT=Path(__file__).resolve().parents[1]
def main():
    p=argparse.ArgumentParser()
    p.add_argument('--quartus-root',default='C:/altera_lite/25.1std')
    p.add_argument('--board',choices=BOARDS,default='de10-lite')
    a=p.parse_args()
    cfg=BOARDS[a.board];project=cfg['project'];output=ROOT/cfg['output']
    subprocess.run([sys.executable,str(ROOT/'tools/generate_assets.py')],check=True)
    subprocess.run([sys.executable,str(ROOT/'tools/create_project.py'),'--quartus-root',a.quartus_root,'--board',a.board],check=True)
    stage=Path(tempfile.mkdtemp(prefix='vecad_chess_'))
    for name in ['rtl','assets']:
        shutil.copytree(ROOT/name,stage/name)
    for name in [f'{project}.qpf',f'{project}.qsf',f'{project}.sdc']:
        shutil.copy2(ROOT/name,stage/name)
    shutil.copy2(ROOT/'tools/timing_report.tcl',stage/'timing_report.tcl')
    build=ROOT/cfg['build']; build.mkdir(exist_ok=True,parents=True)
    (build/'staging_path.txt').write_text(str(stage))
    print('Compiling in',stage,flush=True)
    with (build/'compile.log').open('w') as log:
        result=subprocess.run([str(Path(a.quartus_root)/'quartus/bin64/quartus_sh.exe'),
            '--flow','compile',project],cwd=stage,stdout=log,stderr=subprocess.STDOUT)
    if (stage/cfg['output']).exists():
        shutil.copytree(stage/cfg['output'],output,dirs_exist_ok=True)
    if result.returncode==0:
        with (build/'timing_detail.log').open('w') as log:
            subprocess.run([str(Path(a.quartus_root)/'quartus/bin64/quartus_sta.exe'),
                '-t','timing_report.tcl',project],cwd=stage,stdout=log,stderr=subprocess.STDOUT,check=True)
        for name in ['critical_paths.txt','unconstrained_paths.txt']:
            shutil.copy2(stage/name,build/name)
    if result.returncode:
        print('Compilation FAILED - see build/compile.log');return result.returncode
    compile_text=(build/'compile.log').read_text(errors='replace')
    summary=(output/f'{project}.sta.summary').read_text()
    slacks=[float(s) for s in re.findall(r'Slack\s*:\s*([-\d.]+)',summary)]
    if not slacks or min(slacks)<0 or 'Critical Warning' in compile_text:
        print('Build rejected: timing or critical warnings remain. See build/compile.log.');return 2
    if a.board=='de2-115':
        ucp=(build/'unconstrained_paths.txt').read_text()
        unconstrained=re.findall(r'; Unconstrained (?:Clocks|Input Ports|Output Ports)\s*;\s*(\d+)\s*;\s*(\d+)',ucp)
        if len(unconstrained)!=3 or any(int(n) for pair in unconstrained for n in pair):
            print('Build rejected: unconstrained clock or external port. See unconstrained_paths.txt.');return 2
    manifest={}
    # Check physical pin placements, not merely assignment-file syntax.
    pin_report=(output/f'{project}.pin').read_text()
    actual=dict(re.findall(r'^\s*(\S+)\s*:\s*(\S+)\s*:',pin_report,re.M))
    for name,pin in pins_for(a.board).items():
        if actual.get(name)!=pin:
            print(f'Build rejected: {name} assigned to {actual.get(name)}, expected {pin}');return 3
    source_files=[ROOT/f'rtl/{f}.sv' for f in cfg['sources']]+[ROOT/'rtl/font_function.svh']
    source_files+=list((ROOT/'assets').glob('*'))
    for f in source_files:
        if f.is_file(): manifest[f.relative_to(ROOT).as_posix()]=hashlib.sha256(f.read_bytes()).hexdigest()
    for name in [f'{project}.qsf',f'{project}.sdc',f'{cfg["output"]}/{project}.sof']:
        manifest[name]=hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
    (output/'build_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(f'Compilation, timing and pin checks PASSED - {cfg["output"]}/{project}.sof')
    return 0

if __name__=='__main__': sys.exit(main())
