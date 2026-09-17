from pathlib import Path
import subprocess,sys,os
ROOT=Path(__file__).resolve().parents[1]
build=ROOT/'build/tests';build.mkdir(parents=True,exist_ok=True)
logs=[]
def run(args):
    r=subprocess.run(list(map(str,args)),cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=90)
    logs.append(r.stdout);print(r.stdout)
    (build/'results.log').write_text(''.join(logs))
    if r.returncode:raise SystemExit(r.returncode)
cc=Path('C:/altera_lite/25.1std/questa_fse/gcc-7.4.0-mingw64vc16/bin/gcc.exe')
run([cc,'-std=c99','-Wall','-Wextra','-Isoftware','-Ivendor/doomgeneric/doomgeneric','tests/test_runtime.c','software/ramfs.c','software/ps2_keys.c','-o',build/'runtime.exe'])
run([build/'runtime.exe'])
run([cc,'-std=c99','-Wall','-Wextra','-Isoftware','tests/test_fps_overlay.c','-o',build/'fps.exe'])
run([build/'fps.exe'])
for test,sources in [('sdram',['rtl/doom_sdram.sv']),('io',['rtl/doom_io.sv','rtl/ps2_receiver.sv'])]:
    run(['iverilog','-g2012','-s','tb_'+test,'-o',build/(test+'.vvp'),'tests/tb_'+test+'.sv',*sources])
    run(['vvp',build/(test+'.vvp')])
translator=ROOT/'hardware/doom_system/synthesis/submodules/altera_merlin_slave_translator.sv'
if translator.exists():
    from verify_bus import verify
    verify()
    run(['iverilog','-g2012','-s','tb_io_bus','-o',build/'io_bus.vvp','tests/tb_io_bus.sv',
         'rtl/doom_io.sv','rtl/ps2_receiver.sv',translator])
    run(['vvp',build/'io_bus.vvp'])
else:
    print('Bus integration test requires generated Platform Designer HDL.')
