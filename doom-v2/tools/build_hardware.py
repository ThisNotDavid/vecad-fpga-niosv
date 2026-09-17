from pathlib import Path
import argparse,os,subprocess,sys,json,shutil,tempfile,uuid,stat,re,hashlib
ROOT=Path(__file__).resolve().parents[1]
def main():
    p=argparse.ArgumentParser();p.add_argument('--quartus-root',type=Path,default=Path('C:/altera_lite/25.1std'))
    p.add_argument('--generate',action='store_true');p.add_argument('--compile',action='store_true');p.add_argument('--bsp',action='store_true');a=p.parse_args()
    q=a.quartus_root;hw=ROOT/'hardware';build=ROOT/'build';build.mkdir(exist_ok=True)
    env=os.environ.copy();env['QUARTUS_ROOTDIR']=str(q/'quartus')
    paths=[q/'quartus/bin64',q/'riscfree/toolchain/riscv32-unknown-elf/bin',q/'riscfree/build_tools/bin',q/'riscfree/build_tools/cmake/bin']
    env['PATH']=os.pathsep.join(map(str,paths))+os.pathsep+env.get('PATH','')
    def run(args,log,cwd=hw):
        print('Running',Path(str(args[0])).name,flush=True)
        runenv=env if Path(str(args[0])).name=='cmake.exe' else os.environ.copy()
        with (build/log).open('w') as f:r=subprocess.run(list(map(str,args)),cwd=cwd,env=runenv,stdout=f,stderr=subprocess.STDOUT)
        if r.returncode: print((build/log).read_text(errors='replace')[-7000:]);raise SystemExit(r.returncode)
    if a.generate:
        # Use the checked-in Qsys/QSF; prepare_hardware.py is a historical import utility.
        run([sys.executable,ROOT/'tools/make_components.py'],'components.log')
        run([q/'quartus/sopc_builder/bin/ip-make-ipx.exe','--source-directory='+str(hw),'--output='+str(hw/'components.ipx')],'index.log')
        run([q/'quartus/sopc_builder/bin/qsys-generate.exe','doom_system.qsys','--synthesis=VERILOG','--search-path='+hw.as_posix()+',$'],'generate.log')
    if a.compile:
        from verify_bus import verify as verify_bus
        verify_bus()
        stage=Path(tempfile.gettempdir())/('doom_fpga_'+uuid.uuid4().hex[:10]);stage.mkdir()
        shutil.copytree(hw,stage/'hardware',ignore=shutil.ignore_patterns('db','incremental_db','output_files','*.qws','*.qpf','doom_de2_115.qsf'))
        shutil.copy2(hw/'doom_de2_115.qsf',stage/'hardware/project_settings.txt')
        shutil.copytree(ROOT/'rtl',stage/'rtl')
        # OneDrive marks directories read-only for Explorer customization;
        # copytree preserves that flag, which Quartus treats as unwritable.
        for path in [stage,*stage.rglob('*')]:os.chmod(path,stat.S_IREAD|stat.S_IWRITE)
        (build/'hardware_stage.txt').write_text(str(stage))
        run([q/'quartus/bin64/quartus_sh.exe','-t',ROOT/'tools/bootstrap_project.tcl','doom_de2_115'],'quartus_project.log',stage/'hardware')
        try:
            run([q/'quartus/bin64/quartus_sh.exe','--flow','compile','doom_de2_115'],'quartus.log',stage/'hardware')
            run([q/'quartus/bin64/quartus_sta.exe','-t',ROOT/'tools/check_timing.tcl','doom_de2_115'],'timing.log',stage/'hardware')
            for name in ('critical_paths.txt','unconstrained_paths.txt'):shutil.copy2(stage/'hardware'/name,build/name)
        finally:
            if (stage/'hardware/output_files').exists():shutil.copytree(stage/'hardware/output_files',hw/'output_files',dirs_exist_ok=True)
        from verify_hardware import verify
        verify()
    if a.bsp:
        bsp=build/'bsp';bsp.mkdir(exist_ok=True)
        run([q/'niosv/bin/niosv-bsp.exe','-c','--type=hal','--sopcinfo='+str(hw/'doom_system.sopcinfo'),'--cpu-instance=My_NiosV','--script='+str(ROOT/'tools/bsp_settings.tcl'),bsp/'settings.bsp'],'bsp.log')
        # A copied CMake cache embeds the old absolute source/build locations.
        make_build=bsp/'make_build';cache=make_build/'CMakeCache.txt'
        if cache.exists():
            match=re.search(r'^CMAKE_HOME_DIRECTORY:INTERNAL=(.+)$',cache.read_text(),re.M)
            if match and Path(match[1].strip()).resolve()!=bsp.resolve():
                previous=bsp/('make_build_previous_'+uuid.uuid4().hex[:8])
                if not make_build.resolve().is_relative_to(ROOT.resolve()) or not previous.resolve().is_relative_to(ROOT.resolve()):
                    raise RuntimeError('Build-cache relocation escaped project')
                make_build.rename(previous)
                print('Preserved old-path CMake cache at',previous,flush=True)
        cmake=q/'riscfree/build_tools/cmake/bin/cmake.exe'
        run([cmake,'-S',bsp,'-B',bsp/'make_build','-G','Unix Makefiles','-DCMAKE_MAKE_PROGRAM='+str(q/'riscfree/build_tools/bin/make.exe'),'-DCMAKE_BUILD_TYPE=Release'],'bsp_configure.log')
        run([cmake,'--build',bsp/'make_build','-j','4'],'bsp_build.log')
    print('Requested build steps completed.')
if __name__=='__main__':main()
