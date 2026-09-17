"""Minimal read-only adapter to the installed 64-bit Quartus JTAG Atlantic DLL."""
import ctypes as C
import os
from pathlib import Path

class JtagLink:
    def __init__(self, quartus_root='C:/altera_lite/25.1std', device=1, instance=0):
        directory = Path(quartus_root) / 'quartus/bin64'
        self.directory = os.add_dll_directory(str(directory))
        self.dll = C.CDLL(str(directory / 'jtag_atlantic.dll'))
        def bind(name, decorated, args, result):
            try:
                fn = getattr(self.dll, name)
            except AttributeError:
                fn = getattr(self.dll, decorated)
            fn.argtypes = args
            fn.restype = result
            return fn
        open_link = bind('jtagatlantic_open', '?jtagatlantic_open@@YAPEAUJTAGATLANTIC@@PEBDHH0@Z',
                         [C.c_char_p, C.c_int, C.c_int, C.c_char_p], C.c_void_p)
        self._read = bind('jtagatlantic_read', '?jtagatlantic_read@@YAHPEAUJTAGATLANTIC@@PEADI@Z',
                          [C.c_void_p, C.c_void_p, C.c_uint], C.c_int)
        self._close = bind('jtagatlantic_close', '?jtagatlantic_close@@YAXPEAUJTAGATLANTIC@@@Z',
                           [C.c_void_p], None)
        self.handle = open_link(None, device, instance, b'DOOM UART capture')
        if not self.handle:
            self.directory.close()
            raise RuntimeError('Cannot open JTAG UART; check board and close other UART captures')

    def read(self):
        buf = C.create_string_buffer(256)
        count = self._read(self.handle, buf, len(buf))
        if count < 0:
            raise RuntimeError('JTAG UART connection lost')
        return buf.raw[:count]

    def close(self):
        if self.handle:
            self._close(self.handle)
            self.handle = None
        self.directory.close()
