"""64-bit Windows JTAG Atlantic adapter for Quartus Prime Lite 25.1.

Uses the installed vendor DLL; does not redistribute it. The C++ exports in this
release are explicitly named to avoid accidentally selecting an overload.
"""
import ctypes as C
import os
from pathlib import Path
import time

class JtagError(RuntimeError): pass

class JtagLink:
    def __init__(self, quartus_root='C:/altera_lite/25.1std', cable=None, device=0, instance=0):
        directory=Path(quartus_root)/'quartus/bin64'
        self._directory=os.add_dll_directory(str(directory))
        self.dll=C.CDLL(str(directory/'jtag_atlantic.dll'))
        self.handle=None
        def bind(name,decorated,args,result):
            try: fn=getattr(self.dll,name)
            except AttributeError: fn=getattr(self.dll,decorated)
            fn.argtypes=args;fn.restype=result
            return fn
        self._open=bind('jtagatlantic_open','?jtagatlantic_open@@YAPEAUJTAGATLANTIC@@PEBDHH0@Z',
            [C.c_char_p,C.c_int,C.c_int,C.c_char_p],C.c_void_p)
        self._close=bind('jtagatlantic_close','?jtagatlantic_close@@YAXPEAUJTAGATLANTIC@@@Z',[C.c_void_p],None)
        self._read=bind('jtagatlantic_read','?jtagatlantic_read@@YAHPEAUJTAGATLANTIC@@PEADI@Z',
            [C.c_void_p,C.c_void_p,C.c_uint],C.c_int)
        self._write=bind('jtagatlantic_write','?jtagatlantic_write@@YAHPEAUJTAGATLANTIC@@PEBDI@Z',
            [C.c_void_p,C.c_char_p,C.c_uint],C.c_int)
        self._flush=bind('jtagatlantic_flush','?jtagatlantic_flush@@YAHPEAUJTAGATLANTIC@@@Z',[C.c_void_p],C.c_int)
        self._error=bind('jtagatlantic_get_error','?jtagatlantic_get_error@@YA?AW4JATL_ERROR@@PEAPEBD@Z',
            [C.POINTER(C.c_char_p)],C.c_int)
        self.handle=self._open(cable.encode() if cable else None,device,instance,b'VECAD Chess')
        if not self.handle:
            detail=C.c_char_p(); code=self._error(C.byref(detail))
            raise JtagError(f'Cannot open JTAG UART (code {code}). Connect/program the board and close other terminals. '
                +(detail.value.decode(errors='replace') if detail.value else ''))

    def read(self):
        buf=C.create_string_buffer(256)
        count=self._read(self.handle,buf,len(buf))
        if count<0: raise JtagError('JTAG read failed; connection lost.')
        return buf.raw[:count]

    def exchange(self, command, timeout=3.0):
        if len(command)!=1: raise ValueError('Commands must be exactly one byte')
        if self._write(self.handle,command,1)!=1: raise JtagError('JTAG write failed')
        if self._flush(self.handle)<0: raise JtagError('JTAG flush failed')
        deadline=time.monotonic()+timeout
        while time.monotonic()<deadline:
            received=self.read()
            if received:
                if received!=command: raise JtagError(f'Unexpected FPGA reply: {received!r}; reconnect to resynchronize.')
                return
            time.sleep(0.005)
        raise JtagError('No FPGA acknowledgement. Check that chess.sof is programmed; reconnect before retrying.')

    def close(self):
        if self.handle:
            self._close(self.handle);self.handle=None
        self._directory.close()
