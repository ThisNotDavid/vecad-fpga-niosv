"""Validate the generated adapter, not only our requested component properties."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]

def verify():
    path=ROOT/'hardware/doom_system/synthesis/submodules/doom_system_mm_interconnect_0.v'
    blocks=dict((name,body) for body,name in re.findall(
        r'altera_merlin_slave_translator\s*#\((.*?)\)\s*(\w+)\s*\(',path.read_text(),re.S))
    params=dict(re.findall(r'\.(\w+)\s*\((\d+)\)',blocks['io_s_translator']))
    expected={'AV_READLATENCY':'1','AV_READ_WAIT_CYCLES':'0','AV_WRITE_WAIT_CYCLES':'0',
              'AV_SETUP_WAIT_CYCLES':'0','AV_DATA_HOLD_CYCLES':'0','USE_WAITREQUEST':'0',
              'USE_READDATAVALID':'0'}
    for key,value in expected.items():
        if params.get(key)!=value:
            raise RuntimeError(f'Generated IO timing mismatch: {key}={params.get(key)}, expected {value}')
    print('PASS generated IO adapter timing contract')

if __name__=='__main__':verify()
