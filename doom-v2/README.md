# DOOM on DE2-115 / Nios V

This is the **V2 preparation worktree**, with benchmark/profiling additions only.
Read [tomorrow's handoff](NEXT_SESSION.md) and [benchmark procedure](docs/benchmark.md).
The frozen V1 source and artifacts remain in `C:/FPGA/doom`.

V1 is the preserved implementation: Nios V/g at 50 MHz, 16 KiB instruction and
data caches, 128 MiB SDRAM, 320x200 indexed rendering and centered 640x400 VGA.
It uses PS/2 input, no audio, an embedded Freedoom IWAD and volatile RAM saves.

Start with [V1 baseline](docs/v1-baseline.md), [architecture](docs/architecture.md),
[verification](docs/verification.md), and [licenses](THIRD_PARTY.md).

## Organization

- `hardware/`: checked-in Quartus project, Qsys configuration and constraints.
  Generated IP/database/output folders remain here to preserve Quartus relative
  paths; Git ignores them.
- `rtl/`, `software/`, `tests/`, `tools/`: maintained source and tools.
- `vendor/`, `assets/`: pinned dependencies, recreated by the fetch script.
- `build/`: disposable software builds, BSP, tests and current logs.
- `releases/v1.0.0/`: historical binaries, source, evidence and checksums; keep it.
- `archive/pre-v1/`: recovered session notes, obsolete experiments and caches.

## Build from this folder

Requires Python, Git, Icarus Verilog and Quartus Prime Lite 25.1 at
`C:/altera_lite/25.1std` (build scripts accept `--quartus-root`).

```powershell
python tools/fetch_dependencies.py
python tools/build_hardware.py --generate --compile --bsp
python tools/build_software.py niosv --wad assets/freedoom-0.13.0/freedoom1.wad
python tools/build_software.py diagnostic
python tools/build_software.py desktop
python tools/test.py
```

Generation uses the checked-in Qsys/QSF. `prepare_hardware.py` is retained only
as the historical import utility; normal builds do not read the chess project
or Terasic CD. Builds use a temporary Quartus directory and verify timing/pins.
The BSP uses bundled CMake/GNU Make and RV32 GCC.

## Board operation (DE2-115 only)

```powershell
python tools/run_board.py program
# Separate terminal, before downloading the executable:
python tools/capture_uart.py --seconds 900 --log build/session_uart.log
# Original terminal:
python tools/run_board.py game
```

Programming is volatile. Downloads take about six minutes with this IWAD.
Use `diagnostic` instead of `game` for memory/IO checks. Avoid concurrent UART readers.
To restore the preserved binaries, follow the baseline document.

Controls: W/S forward/back; A/D strafe; left/right arrows turn; Ctrl fires
(including right Ctrl); Space uses; Shift runs; Tab automap; Esc menus;
F2/F3 save/load. Quit followed by Y returns to the title. Saves disappear on reset.
Death still uses the original restart behavior; there is no crosshair.

## Desktop checks

```powershell
cd build/desktop
./doom_desktop.exe -iwad ../../assets/freedoom-0.13.0/freedoom1.wad -nosound -nogui -headless -warp 1 1 -frames 320 -controls-test -capture controls.ppm
```

Headless time is synthetic: its FPS cannot predict FPGA performance. The historic
board log averaged roughly 5.6 FPS over uncontrolled gameplay. A repeatable board
benchmark is required before claiming an improvement.
