# Verification record

Tested on 10 September 2026 with Quartus Prime Lite 25.1 and the installed
RiscFree RV32 GCC 13.2 toolchain.

## Automated checks

- Runtime C tests passed: RAM file bounds, seek, append, sparse writes, read-only
  IWAD protection, rename, and PS/2 make/break parsing.
- Icarus SDRAM simulation passed initialization, refresh under traffic, bank and
  address separation, read/write and byte masks against an independent model.
- Icarus VGA/IO simulation passed full-frame pixel counts, palette selection,
  atomic swap, write protection, timer and PS/2 parity/error handling.
- Native desktop Freedoom Phase 1 completed 240 headless frames, entered E1M1,
  and exercised save/load. `build/desktop/gameplay.png` shows the rendered scene.
  Synthetic desktop time does not measure FPGA performance.
- Full FPGA compilation completed with no errors or critical warnings. Minimum
  reported timing slack is +0.129 ns; 90 application pins were checked. Only
  the three reserved vendor JTAG pads lack external delay constraints.

Reports: `build/tests/results.log`, `build/quartus.log`,
`build/hardware_verified.json`, `build/desktop/run.log`.

## Real DE2-115 checks

The generated SOF was successfully programmed into the EP4CE115 device over
JTAG. The diagnostic ELF then executed from external SDRAM and reported:

```
PASS IO ID and timer
PASS SDRAM 3x256KiB and 64 high-address probes (cache flushed)
PASS RAMFS
PASS VGA swap. Color grid displayed. Press PS/2 keys; raw bytes follow.
```

The user confirmed a stable VGA color grid. PS/2 bytes were captured after arrow
key presses, including extended make/break prefixes. This establishes receipt;
interactive game controls still require a gameplay check. Memory tests are
sampled checks, not an exhaustive test of every SDRAM location or temperature.

The first game run exposed an IO interface problem. Platform Designer's default
read wait time held the read strobe for two cycles. The descriptor now explicitly
sets read/write wait times to zero. A regression using Altera's generated Avalon
translator reproduces the old double strobe and passes with the corrected timing.
After rebuilding and reprogramming, the extended board diagnostic additionally
passed 10,000 interleaved ID/timer/status reads, followed by all memory and display
checks above.

Evidence: `build/board_program.log`, `build/board_diagnostic.log`,
`build/diagnostic_uart.log`, and `build/board_verified_uart.log`.
The subsequent board run reached gameplay; see the controls update below.

## Limitations

No audio or SD card is needed. Settings and saves are volatile. No flash boot
is implemented. Actual gameplay FPS, long-duration stability, and on-board
save/load have not yet been established. Do not interpret successful fitting or
desktop execution alone as proof of these properties.

## Controls and title-return update (10 September 2026)

Active working project: `C:/FPGA/doom`. The source copy matched the earlier
OneDrive project. The BSP was regenerated here, and its CMake cache now points
to this folder. The old CMake build directory was preserved as a backup.

The first corrected IO image ran on the real board, and the user played it.
The reported inability to shoot was traced to an engine binding mismatch:
PS/2 Ctrl produced KEY_RCTRL, while the engine expected KEY_FIRE. Defaults now
use W/S for forward/back, A/D for strafing, left/right arrows for turning,
Ctrl for fire, and Space for use. Right Ctrl has an explicit make/break test.

The user clarified that the apparent stall followed Y at the exit confirmation.
Confirmed Quit previously called exit(), leaving the bare-metal CPU parked with
the last frame visible. Quit now asks to return to the title screen and uses
D_StartTitle without shutting down the engine or RAM filesystem. Esc alone
continues to open/close the menu.

The desktop controls regression passed W movement, ammo consumption with Ctrl,
Esc open/close with resumed ticks, and Quit+Y returning to a live title screen.
The run completed 320 frames, gametic 129, state GS_DEMOSCREEN. All runtime/RTL
regressions also passed from the new folder. The final ELF downloaded successfully at about 16:42 and has produced over 1,600 VGA frames without a reported error. Physical controls and title-return confirmation is pending user feedback.
