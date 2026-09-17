"""Validate matching workloads before reporting profiling overhead."""
import argparse,json
from pathlib import Path
def read(path):
    rows=[json.loads(line[len('BENCHMARK '):]) for line in path.read_text(errors='replace').splitlines() if line.startswith('BENCHMARK ')]
    if len(rows)!=1:raise ValueError(f'{path}: expected exactly one completed benchmark')
    row=rows[0]
    if row['frames']!=350 or row['warmup']!=70 or row['elapsed_us']<=0:raise ValueError('Incomplete/invalid benchmark')
    return row
def main():
    p=argparse.ArgumentParser();p.add_argument('off',type=Path);p.add_argument('on',type=Path);a=p.parse_args()
    off,on=read(a.off),read(a.on)
    if off['profile']!=0 or on['profile']!=1:raise ValueError('Expected profiling-off then profiling-on logs')
    for field in ('platform','clock_hz','frames','warmup','gametic','frame_hash','x','y','health','ammo'):
        if off[field]!=on[field]:raise ValueError('Cannot compare different workloads: '+field)
    for name,row in [('off',off),('on',on)]:
        print(f'{name}: {350000000/row["elapsed_us"]:.3f} FPS; median {row["median_us"]/1000:.3f} ms; p95 {row["p95_us"]/1000:.3f} ms')
    print(f'Profiling elapsed-time overhead: {(on["elapsed_us"]/off["elapsed_us"]-1)*100:.2f}% (repeat trials; negative can be measurement noise)')
    for stage in ('logic','render','convert','wait','transfer','other'):
        print(f'{stage}: {on[stage+"_us"]/350/1000:.3f} ms/frame')
    if off['platform']=='desktop':print('Desktop validation only; these numbers are NOT FPGA FPS.')
if __name__=='__main__':main()
