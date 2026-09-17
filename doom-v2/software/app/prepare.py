"""Prepare a CMake app using the repository's existing engine patch functions."""
from pathlib import Path
import argparse,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from build_software import prepare,validate_wad
p=argparse.ArgumentParser();p.add_argument('--wad',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--fps',action='store_true');a=p.parse_args()
engine,sources=prepare()
build=a.output.parent;build.mkdir(parents=True,exist_ok=True)
data=validate_wad(a.wad);wad=build/'game.wad';wad.write_bytes(data)
assembly=build/'wad.S'
assembly.write_text('.section .rodata.wad,"a",@progbits\n.balign 4\n.global embedded_wad\nembedded_wad:\n.incbin "'+wad.as_posix()+'"\n.global embedded_wad_size\n.balign 4\nembedded_wad_size: .word '+str(len(data))+'\n.global embedded_wad_name\nembedded_wad_name: .asciz "'+a.wad.name+'"\n')
bsp=ROOT/'build/bsp'
flags=['-O2','-g','-std=gnu99','-fno-strict-aliasing','-fwrapv','-ffunction-sections','-fdata-sections','-DCMAP256','-DDOOMGENERIC_RESX=320','-DDOOMGENERIC_RESY=200','-DNORMALUNIX','-DLINUX','-DSNDSERV','-D_DEFAULT_SOURCE','-I'+str(engine),'-I'+str(ROOT/'software'),'-DDOOM_NIOSV','-DALT_SINGLE_THREADED','-D__hal__','-march=rv32im_zicbom','-mabi=ilp32','-I'+str(bsp),'-I'+str(bsp/'HAL/inc'),'-I'+str(bsp/'drivers/inc')]
if a.fps:flags+=['-DDOOM_FPS_OVERLAY']
sources += [ROOT/'software'/n for n in ['doom_profile.c','doomgeneric_niosv.c','ps2_keys.c','ramfs.c','niosv_fs.c']]+[assembly]
libs=['-nostdlib','-T'+str(bsp/'linker.x'),'-Wl,--start-group',str(bsp/'make_build/libhal2_bsp.a'),'-lc','-lgcc','-lm','-Wl,--end-group']
def export(name,values):
 return 'set('+name+'\n'+''.join('  [==['+str(v).replace(chr(92),'/')+']==]\n' for v in values)+')\n'
a.output.write_text(export('DOOM_SOURCES',sources)+export('DOOM_FLAGS',flags)+export('DOOM_LIBS',libs))
