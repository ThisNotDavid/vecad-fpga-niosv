import argparse
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[1]
def main():
    p=argparse.ArgumentParser();p.add_argument('--reference',action='store_true');a=p.parse_args()
    (ROOT/'build').mkdir(exist_ok=True)
    base=['rtl/chess_pkg.sv','rtl/attack_detector.sv','rtl/move_checker.sv']
    tests={'game':base+['rtl/game_controller.sv'],'video':['rtl/vga_timing.sv'],'transport':['rtl/jtag_transport.sv']}
    tests.update(ps2=['rtl/ps2_receiver.sv','rtl/ps2_decoder.sv'],
                 keyboard=base+['rtl/game_controller.sv','rtl/keyboard_commands.sv'],
                 de2_video=['rtl/vga_timing.sv','rtl/de2_vga_output.sv'])
    if a.reference:
        subprocess.run([sys.executable,'tools/generate_rule_vectors.py'],cwd=ROOT,check=True)
        tests['rules']=base
    for name,sources in tests.items():
        result=subprocess.run(['iverilog','-g2012','-I','rtl','-s',f'tb_{name}','-o',f'build/{name}.vvp',
            *sources,f'sim/tb_{name}.sv'],cwd=ROOT,capture_output=True,text=True)
        (ROOT/f'build/{name}_compile.log').write_text(result.stdout+result.stderr)
        if result.returncode: print(result.stderr);return result.returncode
        result=subprocess.run(['vvp',f'build/{name}.vvp'],cwd=ROOT)
        if result.returncode:return result.returncode
    subprocess.run(["iverilog","-g2012","-I","rtl","-s","tb_game","-Ptb_game.AUTO_FLIP=1","-o","build/game_flip.vvp",*base,"rtl/game_controller.sv","sim/tb_game.sv"],cwd=ROOT,check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    subprocess.run(["vvp","build/game_flip.vvp"],cwd=ROOT,check=True)
    return 0
if __name__=='__main__':sys.exit(main())
