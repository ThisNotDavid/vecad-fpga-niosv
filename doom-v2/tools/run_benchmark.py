"""Run paired desktop correctness checks; desktop timing is not FPGA FPS."""
from pathlib import Path
import argparse,hashlib,json,subprocess,tempfile
from make_benchmark import generate
ROOT=Path(__file__).resolve().parents[1]
def main():
    p=argparse.ArgumentParser();p.add_argument('--repeats',type=int,default=2);a=p.parse_args()
    demo=generate();wad=ROOT/'assets/freedoom-0.13.0/freedoom1.wad'
    spec=json.loads((ROOT/'build/benchmark_spec.json').read_text())
    if hashlib.sha256(wad.read_bytes()).hexdigest()!=spec['iwad_sha256']:raise RuntimeError('Wrong benchmark IWAD')
    results=[];identity=None
    for mode in ('off','on'):
        exe=ROOT/'build'/('benchmark-'+mode)/'desktop/doom_desktop.exe'
        for repeat in range(a.repeats):
            # Isolate configs and saves from ordinary gameplay.
            cwd=Path(tempfile.mkdtemp(prefix='doom_benchmark_'))
            r=subprocess.run([str(exe),'-iwad',str(wad),'-nosound','-mb','16','-nogui','-headless',
                              '-timedemo',str(demo)],cwd=cwd,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=90)
            log=ROOT/'build'/f'benchmark-desktop-{mode}-{repeat}.log';log.write_text(r.stdout)
            rows=[json.loads(line[len('BENCHMARK '):]) for line in r.stdout.splitlines() if line.startswith('BENCHMARK ')]
            if r.returncode or len(rows)!=1:raise RuntimeError('Benchmark failed: '+str(log)+'\n'+r.stdout[-2000:])
            row=rows[0]
            if row['frames']!=350 or row['profile']!=int(mode=='on'):raise RuntimeError('Wrong benchmark length/mode')
            observed={k:row[k] for k in ('gametic','frame_hash','x','y','health','ammo')}
            if identity is None:identity=observed
            if observed!=identity:raise RuntimeError('Simulation changed across profiling modes: '+str(observed))
            if mode=='on' and (row['logic_us']<=0 or row['render_us']<=0 or row['convert_us']<=0):raise RuntimeError('Missing stage measurements')
            results.append({'mode':mode,'repeat':repeat,'result':row,'log':log.name})
            print('PASS desktop',mode,repeat,observed)
    (ROOT/'build/benchmark-desktop-results.json').write_text(json.dumps({'platform':'desktop-only; not FPGA performance',
        'spec':spec,'runs':results},indent=2))
if __name__=='__main__':main()
