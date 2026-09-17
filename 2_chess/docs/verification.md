# Verification record — 9 September 2026

## Final compiled design

- Quartus Prime Lite 25.1std.0 Build 1129.
- Target: MAX 10 `10M50DAF484C7G`.
- Logic: **8,093 / 49,760 elements (16%)**.
- Registers: **1,782**.
- Memory bits reported by fitter: **1,063** (small sprite ROM optimized into logic).
- Worst 50 MHz setup slack: **+1.061 ns** at the slow 85 C corner.
- All setup/hold/recovery/removal/pulse-width slacks in the generated summary are nonnegative.
- Full compilation: **0 errors, 21 warnings, no critical warnings**.
- Clock, VGA, LED and key physical pin locations checked in the final `.pin` report.
- Build/source hashes are recorded in `output_files/build_manifest.json`.

Remaining warnings concern the read-only sprite memory's unused write signals,
the reserved KEY1 input, Lite-only feature notices, voltage-interface notices,
and vendor JTAG timing filters/reserved I/O. Reserved JTAG external I/O delays
are not fully constrained; see `docs/architecture.md` for the timing boundary.

## Simulation

- **68,480** independent python-chess reference cases over **94** positions pass.
- Legal moves are checked against canonical standard-chess coordinates.
- Accepted moves also match resulting board, castling rights, and en passant state.
- Public keyboard input tests pass: selection, cancellation, illegal destination,
  cursor limits, restart, Fool's Mate, stalemate, all four promotions and promotion
  cancellation, en passant, and castling.
- VGA test passes: 800x525 total raster, 640x480 active, 96-pixel horizontal sync,
  two-line vertical sync, one frame boundary per raster.
- Transport test passes: Avalon wait states, game backpressure, full TX FIFO, and
  exactly one ordered echo per consumed command.
- Actual HDL renderer frames were captured and visually inspected for ordinary
  selection and the promotion menu. RGB blanking and sync pipeline checks pass.

## Physical board

- Detected USB-Blaster `[USB-0]` and device ID `031050DD`.
- `quartus_pgm` successfully configured the device from `chess.sof`.
- Configuration was loaded into volatile SRAM; configuration flash was not changed.
- `python host/keyboard_client.py --probe` returned **FPGA command/echo PASSED**.
- The laptop keyboard controller was launched for the user's VGA/interaction check.
- User confirmed: **board visible and keyboard controls work** on the physical VGA setup.
- Full special-move coverage is from simulation; no claim is made that every rule
  was manually exercised on the physical board.

## Reproduce

```powershell
python tools/test.py --reference
python tools/build.py
python tools/program.py
python host/keyboard_client.py --probe
python host/keyboard_client.py
```

Close the graphical controller before the probe or another JTAG UART terminal.
