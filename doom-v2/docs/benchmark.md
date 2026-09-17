# Repeatable benchmark, revision 1

Purpose: prepare measurement without changing the CPU, SDRAM controller or target
board. The current worktree is V1 game/RTL plus benchmark/profiling code. It is
NOT a performance-optimized V2 release. No hardware was tested tonight.

## Workload

Freedoom 0.13.0 Phase 1, medium skill, E1M1, normal enemies. A generated Doom v1.9
demo gives deterministic movement, turning and fire input. It has 700 game tics.
The benchmark stops after 70 warm-up frames plus 350 measured frames. The player
survives this route in desktop validation. This is one representative route, not
a worst-case guarantee for every map.

Demo SHA-256: `b6aea23bc045ef9ea9a8482d76b7b852a4663185a327cfe2c9bcc9cc3c1182bf`.
Generator and metadata: `tools/make_benchmark.py`, `build/benchmark_spec.json`.
Fixed viewport screenblocks=10, high detail (detailLevel=0), indexed 320x200 output,
16 MiB game zone, silent sound. Config settings cannot change viewport/detail.
Live keyboard input is ignored. Benchmark-only wipes are disabled in BOTH modes.

Timedemo advances one game tic per rendered frame as fast as the system permits.
Thus its FPS measures rendering throughput; it is not identical to normal paced
gameplay FPS. The historical 5.6 FPS figure cannot be compared directly to this run.

## Measurement

Nios V uses `alt_niosv_mtime_get()` and the HAL timer frequency (50 MHz for this
configuration). Desktop uses QueryPerformanceCounter independently of synthetic
game time. Reported values: total measured elapsed time, FPS*100, median/p95/max
frame time, game state and final indexed-frame FNV-1a hash. P95 is nearest rank.
Frame boundaries enclose the engine's full outer tick; first-level loading and
warm-up are excluded. Frame output means a submitted buffer, not monitor scanout.

Profiling-on additionally measures:
- `logic`: TryRunTics, including input/tick scheduling work.
- `render`: 3D R_RenderPlayerView.
- `convert`: engine framebuffer conversion/copy into DG_ScreenBuffer.
- `wait`: Nios VGA swap wait (desktop has no equivalent).
- `transfer`: Nios MMIO framebuffer/palette transfer; desktop RGB presentation.
- `other`: remaining sampled frame time, including HUD/menu work and overhead.

These stages are non-overlapping. Off builds compile stage hooks away; both modes
retain frame-boundary timestamps and the same workload. There is no serial output
during measured frames. Final hashing, sorting and report transmission are outside
timing. The extra stage timer accesses still cost time: compare off/on on the board
before trusting small changes. Raw per-frame traces are not transmitted; the
350-sample array remains available to a debugger until the next load.

## Prepare (no board needed)

```powershell
cd C:\FPGA\doom-v2
python tools/build_software.py desktop --benchmark
python tools/build_software.py desktop --benchmark --profile
python tools/run_benchmark.py
python tools/build_software.py niosv --benchmark --wad assets/freedoom-0.13.0/freedoom1.wad
python tools/build_software.py niosv --benchmark --profile --wad assets/freedoom-0.13.0/freedoom1.wad
```

Outputs are separate: `build/benchmark-off/niosv/doom.elf` and
`build/benchmark-on/niosv/doom.elf`, with build manifests and hashes. They do not
replace V1's archived game ELF. Desktop paired runs must have identical gametic,
frame hash, position, health and ammo. Expected route result: gametic421,
hash b7aab676, x34061857, y19890797, health95, ammo30. Confirm on real hardware;
do not hide a mismatch as a speed gain.

## Tomorrow: DE2-115 only

1. Verify V1's archive: `python C:/FPGA/doom/tools/verify_release.py C:/FPGA/doom/releases/v1.0.0`.
2. Load the proven V1 SOF via Quartus Programmer. Do not target the DE10-Lite.
   Optionally restore the historical game ELF first to check keyboard/display.
3. Start a fresh UART capture in a separate terminal BEFORE each load:
   `python tools/capture_uart.py --seconds 900 --log build/board-off-1.log`.
4. Run `python tools/run_board.py benchmark-off` from the other terminal.
   Wait for the `BENCHMARK {...}` line. A completed benchmark intentionally parks
   the bare-metal program, leaving the final image; this is not a gameplay freeze.
5. Close the first capture. Repeat with `board-on-1.log` and
   `python tools/run_board.py benchmark-on`.
6. Compare: `python tools/compare_benchmarks.py build/board-off-1.log build/board-on-1.log`.
7. Repeat off/on with fresh numbered logs, preferably three pairs, alternating
   order. Keep the same SOF, ELF hashes, IWAD, settings and board conditions.

Capture must be connected for the final report: benchmark-only stdout switches
to blocking to avoid truncating evidence. Measurements stop before that switch.
If no completion record appears, investigate; missing output is not a performance
result. Verify the board clock and HAL timer first if times are implausible.

After measuring overhead, select the largest cost and propose the next change.
No SDRAM bursts, CPU-clock/cache changes, crosshair, death behavior or USB support
are included in this preparation phase.
