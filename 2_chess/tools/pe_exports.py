"""Inspect named PE exports without third-party packages."""
import struct
import sys
from pathlib import Path

def exports(path):
    data=Path(path).read_bytes()
    u16=lambda p: struct.unpack_from('<H',data,p)[0]
    u32=lambda p: struct.unpack_from('<I',data,p)[0]
    pe=u32(0x3c); opt=pe+24
    sections=opt+u16(pe+20)
    def offset(rva):
        for n in range(u16(pe+6)):
            s=sections+40*n
            size=max(u32(s+8),u32(s+16)); va=u32(s+12)
            if va<=rva<va+size:
                return u32(s+20)+rva-va
        raise ValueError(f'RVA {rva:x} not mapped')
    exp=offset(u32(opt+(112 if u16(opt)==0x20b else 96)))
    names=offset(u32(exp+32))
    result=[]
    for i in range(u32(exp+24)):
        start=offset(u32(names+4*i))
        result.append(data[start:data.index(b'\0',start)].decode('ascii'))
    return result

if __name__=='__main__':
    print('\n'.join(exports(sys.argv[1])))
