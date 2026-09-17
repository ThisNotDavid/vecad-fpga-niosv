"""Capture the actual RTL renderer output, then losslessly encode it as PNG."""
from pathlib import Path
import argparse
import struct
import subprocess
import zlib
ROOT=Path(__file__).resolve().parents[1]
def png(ppm,path):
    header,w_h,maxval,pixels=ppm.split(b'\n',3)
    assert header==b'P6' and maxval==b'255'
    w,h=map(int,w_h.split());assert len(pixels)==w*h*3
    def chunk(kind,data):
        return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    rows=b''.join(b'\0'+pixels[y*w*3:(y+1)*w*3] for y in range(h))
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+
                    chunk(b'IDAT',zlib.compress(rows))+chunk(b'IEND',b''))
def main():
    p=argparse.ArgumentParser();p.add_argument('--mode',type=int,default=0)
    p.add_argument('--board',choices=['de10-lite','de2-115'],default='de10-lite');a=p.parse_args()
    defines=['-DDE2_115'] if a.board=='de2-115' else []
    result=subprocess.run(['iverilog','-g2012',*defines,'-I','rtl','-s','tb_render','-o','build/render.vvp',
        'rtl/chess_pkg.sv','rtl/text_layer.sv','rtl/chess_renderer.sv','sim/tb_render.sv'],cwd=ROOT,capture_output=True,text=True)
    (ROOT/'build/render_compile.log').write_text(result.stdout+result.stderr)
    result.check_returncode()
    subprocess.run(['vvp','build/render.vvp',f'+MODE={a.mode}'],cwd=ROOT,check=True)
    target=ROOT/('build/de2_115' if a.board=='de2-115' else 'build');target.mkdir(exist_ok=True,parents=True)
    png((ROOT/f'build/frame_{a.mode}.ppm').read_bytes(),target/f'frame_{a.mode}.png')
    print(f'Created {target}/frame_{a.mode}.png')
if __name__=='__main__':main()
