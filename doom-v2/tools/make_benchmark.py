"""Deterministic Doom 1 v1.9 input stream, not a timed host-key sequence."""
from pathlib import Path
import hashlib,json,struct
ROOT=Path(__file__).resolve().parents[1]
def generate():
    # v1.9, medium skill, E1M1, normal enemies, no respawn/fast/deathmatch, player 1.
    data=bytearray([109,2,1,1,0,0,0,0,0,1,0,0,0])
    # 700 tics allow the 70 warm-up + 350 measured frames to finish before EOF.
    for tic in range(700):
        phase=(tic//70)%4
        forward=20 if phase in (0,2) else 0
        side=12 if phase==1 else -12 if phase==3 else 0
        turn=2 if phase in (1,3) else 0
        buttons=1 if tic>=70 and tic%35<18 else 0
        data+=struct.pack('<bbbb',forward,side,turn,buttons)
    data.append(0x80)
    out=ROOT/'build/benchmark.lmp';out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(data)
    (out.parent/'benchmark_spec.json').write_text(json.dumps({
        'name':'freedoom-e1m1-route-v1','demo_sha256':hashlib.sha256(data).hexdigest(),
        'warmup_frames':70,'measured_frames':350,'demo_tics':700,'detail':0,'screenblocks':10,
        'iwad_sha256':'7323bcc168c5a45ff10749b339960e98314740a734c30d4b9f3337001f9e703d',
        'mode':'timedemo: one game tic per frame; wipes and live input disabled'},indent=2))
    return out
if __name__=='__main__':print(generate())
