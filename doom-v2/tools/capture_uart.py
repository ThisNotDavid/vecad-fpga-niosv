"""Read-only JTAG UART capture; run after programming, before downloading ELF."""
from pathlib import Path
import time,argparse
ROOT=Path(__file__).resolve().parents[1]
from jtag_uart import JtagLink
p=argparse.ArgumentParser();p.add_argument('--seconds',type=float,default=60);p.add_argument('--log',type=Path,default=ROOT/'build/uart.log');a=p.parse_args()
link=JtagLink(device=1,instance=0)
try:
    deadline=time.monotonic()+a.seconds
    with a.log.open('w') as f:
        while time.monotonic()<deadline:
            data=link.read()
            if data:
                text=data.decode(errors='replace');f.write(text);f.flush();print(text,end='',flush=True)
            time.sleep(.01)
finally:link.close()
