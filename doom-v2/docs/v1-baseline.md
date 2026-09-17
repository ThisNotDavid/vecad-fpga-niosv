# V1.0.0 baseline

Frozen source is identified by the annotated Git tag `v1.0.0`. Historical build
artifacts were copied BEFORE cleanup, without recompilation, into
`releases/v1.0.0`. `manifest.json` lists their SHA-256 hashes. `source-original`
preserves pre-cleanup source; tagged source adds organization and makes normal
IP generation use checked-in configuration. Game and RTL source were not changed.

Configuration: EP4CE115F29C7; Quartus Prime Lite 25.1; Nios V/g 4.0.0, 50 MHz;
16 KiB instruction/data caches; RV32IM plus cache management; GCC 13.2, -O2;
single-word SDRAM controller; two on-chip 320x200 indexed framebuffers;
25 MHz VGA pixel clock; PS/2 keyboard; no sound/SD/flash boot.

Engine: doomgeneric commit `dcb7a8dbc7a16ce3dda29382ac9aae9d77d21284`.
Data: Freedoom 0.13.0 Phase 1, 28,795,076 bytes, SHA-256
`7323bcc168c5a45ff10749b339960e98314740a734c30d4b9f3337001f9e703d`.
Archive includes the official Freedoom ZIP and a Git bundle of the engine.

Proven SOF SHA-256:
`b303f82a8dd50c66cc15c05483f27f9eb18249f0769dd24a909450cb692bfeb2`.
Minimum reported timing slack: +0.129 ns. Physical diagnostics passed sampled
SDRAM tests, timer and IO checks; the user confirmed stable VGA and played the
game. Controls and confirmed Quit were subsequently fixed and passed desktop
regressions; final board ELF produced over 1,600 frames. Full user confirmation
of all final controls/save-load behavior was not recorded. See archived logs.

Historical FPS: last 20 complete intervals in `controls_uart.log`, 2,400 frames
over 427.988 seconds: 5.6076 FPS weighted average; 4.13–7.62 FPS interval range.
Scenes were not recorded. This is context, NOT a controlled benchmark.
No hardware FPS improvement may be claimed from desktop or simulation results.

## Restore without rebuilding

Run `python tools/verify_release.py releases/v1.0.0`. Then use Quartus Programmer
to load `releases/v1.0.0/hardware/output_files/doom_de2_115.sof` into DE2-115.
In the Quartus Nios V command environment run:

```powershell
niosv-download --go C:/FPGA/doom/releases/v1.0.0/build/niosv/doom.elf
```

Use forward slashes for ELF paths. This writes volatile configuration/SDRAM only.
Keep the release separately backed up; a worktree is not a backup.

## V2

V2 lives in a separate worktree on `codex/v2-performance`. Keep this V1 checkout
unchanged. Ignore build output in both; never share a BSP/CMake cache.
Profiling additions must be checked for overhead against the identical benchmark
with profiling disabled, not compared directly to the uncontrolled historical log.
