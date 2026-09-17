# Hardware/software contract

## Address map

| Address | Size | Purpose |
|---|---:|---|
| `0x00000000` | 16 KiB | On-chip boot park memory |
| `0x00020000` | 64 KiB | Nios V debug agent |
| `0x00030000` | 64 B | CPU timer/software interrupt agent |
| `0x00030060` | 8 B | JTAG UART |
| `0x08000000` | 128 MiB | SDRAM, cached |
| `0x10000000` | 256 KiB | DOOM IO aperture, uncached |

Generated `system.h` remains the authoritative software map. The CPU's second
peripheral region covers the UART/timer. IO uses its first peripheral region.

## Display registers (byte offsets from IO_BASE)

| Offset | Access | Meaning |
|---|---|---|
| `0x00000` | W | Framebuffer 0; 64,000 active bytes, 65,536-byte aperture |
| `0x10000` | W | Framebuffer 1 |
| `0x20000` | W32 | Palette 0: 256 entries, `0x00RRGGBB` |
| `0x20400` | W32 | Palette 1 |
| `0x21000` | R32 | bit 0 front bank, bit 1 pending, bit 2 enabled |
| `0x21004` | W32 | Submit: bit 0 bank, bit 1 enable |
| `0x21008` | R32 | Milliseconds modulo 2^32 |
| `0x2100c` | R32 | PS/2 FIFO pop: bit 8 valid, bits 7:0 byte |
| `0x21010` | R32/W1C | bit 0 overflow, bit 1 receiver error |
| `0x21014` | R32 | Hardware identity `0x444f4f4d` |

RAM writes honor byte enables. Palette writes are full 32-bit transactions.
Front-bank writes and writes during a pending submission are discarded. Software
must finish the back framebuffer and its palette, issue a fence, submit, and
wait for acknowledgment before modifying either bank. Both swap together at
the first blank line. There is one clock domain, so no asynchronous swap CDC.

The display RAM is not initialized. Output remains blank until software submits
a fully written frame/palette. Reset returns to front bank 0, so first draw is
to bank 1. The palette and pixel data are synchronous M9K memories. The forwarded
DAC clock and synchronization pipeline account for registered video data.

## SDRAM

Two x16 devices form a 32-bit bus: 4 banks, 8192 rows, 1024 columns. Word address
bits `[24:23]` select bank, `[22:10]` row, and `[9:0]` column. Initialization waits
220 us at 50 MHz, precharges all banks, performs eight refresh commands, and sets
CAS 2/single-word bursts. Normal accesses use activate and auto-precharge.

Refresh is requested every 350 cycles (7 us) and serviced between bounded
transactions. Platform Designer adapts Nios V/g bursts to single-word Avalon
transactions. DRAM_CLK is inverted CLOCK_50; input sampling occurs on a falling
system edge before returning data to the CPU. The SDC budgets include provisional
device/PCB delays; actual board operation is verified separately.

## Software and boot

The FPGA boots into a self-loop in on-chip memory. The debugger downloads a
single ELF into SDRAM and resumes at its ELF entry point. The HAL initializes
the runtime and UART; no filesystem, OS, SD card or external bootloader is needed.

`/ram/<iwad-name>` is a read-only file backed directly by the embedded data.
Other `/ram/` files allocate memory as needed, capped at 512 KiB each, 20 files,
and 24 handles. Reads, seeks, append, rename, unlink, and sparse writes have
explicit bounds and error handling. Directory creation is implicit.

No audio module is compiled. The engine runs with `-nosound`. Timed game logic
uses the hardware millisecond counter; video refresh is independent of rendering.
There is no measured FPGA FPS target until a board run has completed.
