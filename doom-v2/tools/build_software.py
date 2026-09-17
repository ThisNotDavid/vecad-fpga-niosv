"""Build desktop preview or the real Nios V ELF; no board required."""
from pathlib import Path
import argparse, subprocess, os, re, json, shutil, hashlib
from concurrent.futures import ThreadPoolExecutor
ROOT=Path(__file__).resolve().parents[1]
QUARTUS=Path('C:/altera_lite/25.1std')
PIN='dcb7a8dbc7a16ce3dda29382ac9aae9d77d21284'

def prepare():
    src=ROOT/'vendor/doomgeneric/doomgeneric'
    actual=subprocess.check_output(['git','-C',str(src.parent),'rev-parse','HEAD'],text=True).strip()
    if actual!=PIN: raise RuntimeError(f'Upstream revision mismatch: expected {PIN}, got {actual}')
    out=ROOT/'build/engine';out.mkdir(parents=True,exist_ok=True)
    for p in src.iterdir():
        if p.suffix in ('.c','.h'): shutil.copy2(p,out/p.name)
    p=out/'doomtype.h';s=p.read_text().replace('#define strncasecmp _strnicmp','#include "ascii_case.h"\n#define strncasecmp doom_ascii_ncasecmp');p.write_text(s)
    p=out/'doomgeneric.c';s=p.read_text().replace('DOOMGENERIC_RESX * DOOMGENERIC_RESY * 4','DOOMGENERIC_RESX * DOOMGENERIC_RESY * sizeof(pixel_t)');p.write_text(s)
    p=out/'d_main.c';s=p.read_text().replace('M_SetConfigDir(NULL);','#ifdef DOOM_NIOSV\n        M_SetConfigDir("/ram/");\n#else\n        M_SetConfigDir(NULL);\n#endif');p.write_text(s)
    p=out/'i_video.c';s=p.read_text();s=s.replace('color.r = GFX_RGB565_R(rgb565_palette[i]);','color.r = colors[i].r;').replace('color.g = GFX_RGB565_G(rgb565_palette[i]);','color.g = colors[i].g;').replace('color.b = GFX_RGB565_B(rgb565_palette[i]);','color.b = colors[i].b;');p.write_text(s)
    p=out/'i_system.c';s=p.read_text().replace('#if ORIGCODE\n    SDL_Quit();\n\n    exit(0);\n#endif','    exit(0);');p.write_text(s)
    # Match physical PS/2 keys while preserving ASCII for menus/save names.
    p=out/'m_controls.c';s=p.read_text()
    for before,after in [('int key_up = KEY_UPARROW;', "int key_up = 'w';"),
                         ('int key_down = KEY_DOWNARROW;', "int key_down = 's';"),
                         ('int key_strafeleft = KEY_STRAFE_L;', "int key_strafeleft = 'a';"),
                         ('int key_straferight = KEY_STRAFE_R;', "int key_straferight = 'd';"),
                         ('int key_fire = KEY_FIRE;', 'int key_fire = KEY_RCTRL;'),
                         ('int key_use = KEY_USE;', "int key_use = ' ';")]:
        if before not in s:raise RuntimeError('Upstream control binding changed: '+before)
        s=s.replace(before,after)
    p.write_text(s)
    # Bare-metal Quit returns home; process exit would park the CPU forever.
    p=out/'m_menu.c';s=p.read_text()
    begin=s.index('void M_QuitResponse(int key)');end=s.index('static char *M_SelectEndMessage',begin)
    s=s[:begin]+"void M_QuitResponse(int key)\n{\n    if(key != key_menu_confirm)return;\n    M_ClearMenus();\n    D_StartTitle();\n}\n\n"+s[end:]
    begin=s.index('void M_QuitDOOM(int choice)\n{');end=s.index('void M_ChangeSensitivity',begin)
    s=s[:begin]+"void M_QuitDOOM(int choice)\n{\n    (void)choice;\n    M_StartMessage(\"RETURN TO TITLE SCREEN?\\n(Y/N)\",M_QuitResponse,true);\n}\n\n"+s[end:]
    p.write_text(s)
    from instrument_engine import instrument
    instrument(out)
    names=re.search(r'SRC_DOOM = (.*)',(src/'Makefile').read_text())[1].split()
    sources=[out/n.replace('.o','.c') for n in names if n!='doomgeneric_xlib.o']
    (ROOT/'build/upstream.json').write_text(json.dumps({'url':'https://github.com/ozkl/doomgeneric','commit':actual},indent=2))
    return out,sources

def validate_wad(path):
    import struct
    data=path.read_bytes()
    if len(data)<12 or data[:4]!=b'IWAD':raise ValueError('Expected an IWAD file')
    count,offset=struct.unpack_from('<II',data,4)
    if count>100000 or offset>len(data) or count*16>len(data)-offset:raise ValueError('Invalid WAD directory')
    for i in range(count):
        pos,size=struct.unpack_from('<II',data,offset+16*i)
        if pos>len(data) or size>len(data)-pos:raise ValueError('Invalid WAD lump bounds')
    if len(data)>80*1024*1024:raise ValueError('WAD exceeds the 80 MiB build limit')
    return data

def main():
    p=argparse.ArgumentParser();p.add_argument('target',choices=['desktop','niosv','diagnostic']);p.add_argument('--wad',type=Path)
    p.add_argument('--benchmark',action='store_true');p.add_argument('--profile',action='store_true');p.add_argument('--fps-overlay',action='store_true')
    p.add_argument('--quartus-root',type=Path,default=QUARTUS);a=p.parse_args()
    if a.profile and not a.benchmark:p.error('--profile currently requires --benchmark')
    if a.benchmark and a.target=='diagnostic':p.error('Diagnostic is not a game benchmark')
    if a.fps_overlay and (a.benchmark or a.target=='diagnostic'):p.error('--fps-overlay requires a playable game build')
    out,sources=prepare()
    build=ROOT/'build'
    if a.benchmark:build/= 'benchmark-on' if a.profile else 'benchmark-off'
    if a.fps_overlay:build/='demo-fps'
    build/=a.target;build.mkdir(parents=True,exist_ok=True)
    if a.benchmark:
        from make_benchmark import generate
        demo=generate()
    flags=['-O2','-g','-std=gnu99','-fno-strict-aliasing','-fwrapv','-ffunction-sections','-fdata-sections',
        '-DCMAP256','-DDOOMGENERIC_RESX=320','-DDOOMGENERIC_RESY=200','-DNORMALUNIX','-DLINUX','-DSNDSERV','-D_DEFAULT_SOURCE',
        '-I'+str(out),'-I'+str(ROOT/'software')]
    sources += [ROOT/'software/doom_profile.c']
    if a.benchmark:flags+=['-DDOOM_BENCHMARK']
    if a.profile:flags+=['-DDOOM_PROFILE']
    if a.fps_overlay:flags+=['-DDOOM_FPS_OVERLAY']
    if a.target=='desktop':
        cc=a.quartus_root/'questa_fse/gcc-7.4.0-mingw64vc16/bin/gcc.exe'
        sources+=[ROOT/'software/doomgeneric_desktop.c']
        libs=['-luser32','-lgdi32','-lm'];output=build/'doom_desktop.exe'
    else:
        if a.target=='niosv' and not a.wad:p.error('--wad is required for niosv')
        data=validate_wad(a.wad) if a.wad else b'';wad=build/'game.wad';wad.write_bytes(data)
        if a.benchmark and hashlib.sha256(data).hexdigest()!='7323bcc168c5a45ff10749b339960e98314740a734c30d4b9f3337001f9e703d':
            raise RuntimeError('Benchmark requires pinned Freedoom Phase 1 IWAD')
        if a.wad:(build/'wad_manifest.json').write_text(json.dumps({'source':str(a.wad.resolve()),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()},indent=2))
        gccdir=a.quartus_root/'riscfree/toolchain/riscv32-unknown-elf/bin';cc=gccdir/'riscv32-unknown-elf-gcc.exe'
        # .incbin avoids a multi-million-element C initializer and fixes naming.
        if a.wad:(build/'wad.S').write_text('.section .rodata.wad,"a",@progbits\n.balign 4\n.global embedded_wad\nembedded_wad:\n.incbin "'+wad.as_posix()+'"\n.global embedded_wad_size\n.balign 4\nembedded_wad_size: .word '+str(len(data))+'\n.global embedded_wad_name\nembedded_wad_name: .asciz "'+a.wad.name+'"\n')
        if a.benchmark:
            with (build/'wad.S').open('a') as f:f.write('\n.section .rodata.benchmark,"a",@progbits\n.balign 4\n.global embedded_demo\nembedded_demo:\n.incbin "'+demo.as_posix()+'"\n.balign 4\n.global embedded_demo_size\nembedded_demo_size: .word '+str(demo.stat().st_size)+'\n')
        bsp=ROOT/'build/bsp'
        if not (bsp/'system.h').exists():raise RuntimeError('Generate BSP first with build_hardware.py --bsp')
        flags+=['-DDOOM_NIOSV','-DALT_SINGLE_THREADED','-D__hal__','-march=rv32im_zicbom','-mabi=ilp32','-I'+str(bsp),'-I'+str(bsp/'HAL/inc'),'-I'+str(bsp/'drivers/inc')]
        sources += [ROOT/'software'/n for n in ('doomgeneric_niosv.c','ps2_keys.c','ramfs.c','niosv_fs.c')]+[build/'wad.S']
        if a.target=='diagnostic':sources=[ROOT/'software/diagnostic.c',ROOT/'software/ramfs.c']
        libs=['-nostdlib','-T'+str(bsp/'linker.x'),'-Wl,--start-group',str(bsp/'make_build/libhal2_bsp.a'),'-lc','-lgcc','-lm','-Wl,--end-group']
        output=build/'doom.elf'
    env=os.environ.copy();env['PATH']=str(cc.parent)+os.pathsep+env.get('PATH','')
    def compile_one(src):
        obj=build/(src.stem+'.o');r=subprocess.run([str(cc),*flags,'-c',str(src),'-o',str(obj)],env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
        return obj,r.returncode,r.stdout
    with ThreadPoolExecutor(max_workers=4) as pool: results=list(pool.map(compile_one,sources))
    (build/'compile.log').write_text(''.join(r[2] for r in results))
    errors=[r for r in results if r[1]]
    if errors:print(''.join(r[2] for r in errors));raise SystemExit(1)
    args=[*flags,*[str(r[0]) for r in results],'-Wl,--gc-sections','-Wl,-Map,'+str(build/'doom.map'),'-o',str(output),*libs]
    rsp=build/'link.rsp';rsp.write_text('\n'.join('"'+s.replace('\\','/')+'"' for s in args))
    r=subprocess.run([str(cc),'@'+str(rsp)],env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    (build/'link.log').write_text(r.stdout);print(r.stdout)
    if r.returncode:raise SystemExit(r.returncode)
    (build/'build_manifest.json').write_text(json.dumps({'target':a.target,'benchmark':a.benchmark,
        'profile':a.profile,'fps_overlay':a.fps_overlay,'elf_or_exe_sha256':hashlib.sha256(output.read_bytes()).hexdigest(),
        'git_commit':subprocess.check_output(['git','-C',str(ROOT),'rev-parse','HEAD'],text=True).strip(),
        'working_tree_status':subprocess.check_output(['git','-C',str(ROOT),'status','--porcelain'],text=True),
        'flags':flags,'upstream':PIN},indent=2))
    print(output)

if __name__=='__main__':main()
