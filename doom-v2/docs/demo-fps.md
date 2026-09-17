# Playable demo with live FPS

Prepared 2026-09-11 in C:/FPGA/doom-v2. V1 remains unchanged.

## Launch on DE2-115

With the verified V1 FPGA configuration already loaded:

```powershell
cd C:/FPGA/doom-v2
python tools/run_board.py demo-fps
```

The ELF download takes about six minutes. On a power-cycled board, first load
its FPGA configuration (volatile; no flash programming):

```powershell
cd C:/FPGA/doom
python tools/run_board.py program
cd C:/FPGA/doom-v2
python tools/run_board.py demo-fps
```

Connect VGA and PS/2 keyboard; power the board with keyboard connected.
Controls: W/S forward/back, A/D strafe, left/right arrows turn, right Ctrl fire,
Space use/open doors, Esc menu. Quit Game then Y returns to title.

## Counter meaning

FPS appears at top right over an opaque dark rectangle. It updates approximately
once per second, counting completed frame submissions divided by actual elapsed
milliseconds. A delayed frame extends the interval; it is not assumed to be exactly
one second. The first displayed value is FPS: --, then a value such as FPS: 8.0.
The counter also runs on menus/title screens, whose rates differ from gameplay.
It counts submitted frames, not physical monitor refreshes. Display is rounded to
one decimal place and reflects the preceding interval, including overlay cost.

The Nios output uses the current palette's darkest/brightest colors, so damage or
bonus flashes can tint the overlay. It changes only the outgoing VGA bank; game
and DG framebuffers remain untouched. It adds 308 packed pixel writes per frame
plus a small palette scan. Its performance overhead has not been separately
benchmarked. The recorded 8.016 FPS baseline remains a separate timedemo result.

## Files and rebuild

- Playable ELF: build/demo-fps/niosv/doom.elf
- Compiler options and ELF SHA-256: build/demo-fps/niosv/build_manifest.json
- IWAD provenance: build/demo-fps/niosv/wad_manifest.json
- Changed overlay/build source snapshot: build/demo-fps/overlay-source.zip
- Source snapshot and ELF checksums: build/demo-fps/demo-files.json
- Visual checks: build/demo-fps/overlay-preview.png and controls-title.png
- Startup log: build/demo-fps/board-demo.log

```powershell
python tools/build_software.py niosv --fps-overlay --wad assets/freedoom-0.13.0/freedoom1.wad
```

--fps-overlay is optional and incompatible with benchmark/diagnostic mode.
Normal and benchmark outputs are preserved in their separate build directories.

Local validation passed: known FPS intervals, irregular timing, 32-bit clock
wraparound, raster bounds, desktop movement/fire/Esc/quit-to-title regression,
and visual inspection. Nios compilation succeeded with the existing RWX linker
warning. Physical VGA readability and control confirmation are recorded in the
next-session handoff after deployment.

Physical validation: user confirmed the FPS display and all controls work normally,
with approximately 3-10 FPS observed during gameplay. This is a user-estimated
scene-dependent range, not a controlled benchmark. The game is left running.
