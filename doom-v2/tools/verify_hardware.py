from pathlib import Path
import re,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
def verify():
    hw=ROOT/'hardware';build=ROOT/'build'
    text=(hw/'output_files/doom_de2_115.sta.summary').read_text()
    slacks=[float(v) for v in re.findall(r'Slack\s*:\s*([-\d.]+)',text)]
    if not slacks or min(slacks)<0 or 'Critical Warning' in (build/'quartus.log').read_text():
        raise RuntimeError('Timing failure or critical Quartus warning; inspect build logs')
    ucp=(build/'unconstrained_paths.txt').read_text()
    counts=re.findall(r'; Unconstrained (?:Clocks|Input Ports|Output Ports)\s*;\s*(\d+)\s*;\s*(\d+)',ucp)
    # Vendor JTAG pads have internal TCK timing but no user-board I/O delays.
    # Permit only their exact identities, never an unrecognized external port.
    ports=set(re.findall(r'^;\s*(\S+)\s*; No (?:input|output) delay',ucp,re.M))
    reserved={'altera_reserved_tdi','altera_reserved_tms','altera_reserved_tdo'}
    if len(counts)!=3 or counts[0]!=('0','0') or not ports.issubset(reserved):raise RuntimeError('Unconstrained application clocks or ports')
    if any(int(n)>limit for pair,limit in zip(counts,(0,2,1)) for n in pair):raise RuntimeError('Unexpected unconstrained port count')
    expected=dict(re.findall(r'^set_location_assignment PIN_(\S+) -to "([^"]+)"',(hw/'doom_de2_115.qsf').read_text(),re.M))
    actual=dict(re.findall(r'^\s*(\S+)\s*:\s*(\S+)\s*:',(hw/'output_files/doom_de2_115.pin').read_text(),re.M))
    if len(expected)<80:raise RuntimeError('Incomplete board pin assignments')
    for pin,name in expected.items():
        if actual.get(name)!=pin:raise RuntimeError(f'Pin mismatch {name}: {actual.get(name)} != {pin}')
    sof=hw/'output_files/doom_de2_115.sof'
    proof={'sof_sha256':hashlib.sha256(sof.read_bytes()).hexdigest(),'minimum_slack_ns':min(slacks),
        'device':'EP4CE115F29C7','verified_pins':len(expected),'unconstrained_vendor_jtag_pads':sorted(ports),'board_tested':False}
    (build/'hardware_verified.json').write_text(json.dumps(proof,indent=2));print(json.dumps(proof,indent=2))
if __name__=='__main__':verify()
