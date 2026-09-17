"""Volatile programming only. Never writes configuration flash."""
from pathlib import Path
import argparse,subprocess,os,json,hashlib,re,sys
ROOT=Path(__file__).resolve().parents[1]
def main():
    p=argparse.ArgumentParser();p.add_argument('action',choices=['program','diagnostic','game','benchmark-off','benchmark-on','demo-fps'])
    p.add_argument('--quartus-root',type=Path,default=Path('C:/altera_lite/25.1std'));a=p.parse_args()
    q=a.quartus_root;env=os.environ.copy()
    dirs=[q/'quartus/bin64',q/'riscfree/toolchain/riscv32-unknown-elf/bin',q/'riscfree/debugger/gdbserver-riscv',q/'niosv/bin']
    env['PATH']=os.pathsep.join(map(str,dirs))+os.pathsep+env.get('PATH','')
    chain=subprocess.check_output([str(q/'quartus/bin64/jtagconfig.exe')],env=env,text=True)
    print(chain)
    if '020F70DD' not in chain.upper():raise RuntimeError('Expected DE2-115 JTAG ID 020F70DD not found')
    log=ROOT/'build'/('board_'+a.action+'.log')
    if a.action=='program':
        sof=ROOT/'hardware/output_files/doom_de2_115.sof'
        proof=json.loads((ROOT/'build/hardware_verified.json').read_text())
        if hashlib.sha256(sof.read_bytes()).hexdigest()!=proof['sof_sha256']:raise RuntimeError('Bitstream differs from timing-checked build')
        args=[q/'quartus/bin64/quartus_pgm.exe','-m','JTAG','-c','1','-o','p;'+str(sof)+'@1']
    else:
        target='diagnostic' if a.action=='diagnostic' else 'niosv'
        elf=ROOT/'build'/target/'doom.elf'
        if a.action.startswith('benchmark-'):elf=ROOT/'build'/a.action/'niosv/doom.elf'
        if a.action=='demo-fps':elf=ROOT/'build/demo-fps/niosv/doom.elf'
        if not elf.exists():raise RuntimeError('Build the ELF first')
        args=[q/'niosv/bin/niosv-download.exe','--go',elf.as_posix()]
    with log.open('w') as f:r=subprocess.run(list(map(str,args)),env=env,stdout=f,stderr=subprocess.STDOUT)
    output=log.read_text(errors='replace');print(output)
    if r.returncode:raise SystemExit(r.returncode)
    if a.action!='program' and ('Transfer rate:' not in output or 'No such file' in output or 'Error' in output):
        raise RuntimeError('Downloader did not confirm a successful ELF transfer; inspect '+str(log))
if __name__=='__main__':main()
