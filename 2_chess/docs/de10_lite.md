# VECAD FPGA Chess

Two-player chess on a **DE10-Lite MAX 10**, rendered by the FPGA on an external
**640 x 480 VGA monitor**. A Windows laptop sends keyboard commands over the
board's existing **USB-Blaster** cable. No mouse, UART adapter, soft processor,
SDRAM controller, or network service is required.

## Quick start

1. Connect and power the DE10-Lite. Connect its VGA output to the monitor.
2. Program the verified SRAM image:
   ```powershell
   python tools/program.py
   ```
3. Start the laptop controller:
   ```powershell
   python host/keyboard_client.py
   ```
4. Keep the controller window focused and watch the VGA monitor.

Alternatively, use Quartus Programmer to load `output_files/chess.sof` with
**Program/Configure** selected. This is a volatile `.sof` download, not a flash
update; power cycling restores whatever was previously stored in board flash.
Close other JTAG UART terminals before connecting the controller.

| Key | Action |
|---|---|
| Arrow keys / WASD | Move the white cursor border |
| Enter / Space | Select a friendly piece, then confirm a legal destination |
| Esc | Cancel selection or return from the promotion menu |
| 1 / 2 / 3 / 4 | Promote to queen / rook / bishop / knight |
| F2 | New game, after a laptop confirmation |
| Board KEY0 | Reset the game and JTAG interface; reconnect the controller if necessary |

White starts at the bottom, with the cursor on e2. Selected squares are gold;
legal moves have dots or capture corners. The last move stays highlighted.
The sidebar shows the active player, check, promotion choices, and the result.

## Implemented rules

- All six piece types, captures, path blocking, alternating turns, and king safety.
- Castling, including rook/king history and attacked transit squares.
- En passant, including discovered-check validation.
- Promotion to all four legal pieces.
- Check, checkmate, and stalemate; moves are disabled after a result.

This demo does **not** adjudicate repetition, the fifty/seventy-five-move rules,
dead positions/insufficient material, agreed draws, or resignation. It has no
clock, AI, undo, saved games, drag-and-drop, or online play.
Artwork is original pixel art inspired by a green-and-cream online chess layout.

## Build

Tested tool installation: **Quartus Prime Lite 25.1std.0 Build 1129** at
`C:/altera_lite/25.1std`. Requires MAX 10 device support and 64-bit Python with Tk.

```powershell
python tools/build.py
```

For another installation:

```powershell
python tools/build.py --quartus-root C:/altera_lite/25.1std
python tools/program.py --quartus-root C:/altera_lite/25.1std
python host/keyboard_client.py --quartus-root C:/altera_lite/25.1std
```

The build script regenerates the project/assets, stages files in a temporary local
directory, runs Quartus, collects reports, and rejects negative timing slack or
critical warnings. Run it in a normal Windows environment: the agent sandbox caused
Quartus path resolution and USB/JTAG access failures during development.
Temporary build directories are retained for debugging; their latest location is
recorded in `build/staging_path.txt`.

The project references JTAG UART RTL from your own Quartus installation; vendor IP
is not redistributed here. Opening `chess.qpf` in Quartus is also supported.
Re-run `tools/create_project.py` if the installation path changes.

## Verification

Basic HDL tests need Icarus Verilog (`iverilog` and `vvp`) on PATH:

```powershell
python tools/test.py
```

Independent reference checks additionally use python-chess, only during testing:

```powershell
python -m pip install --target build/test_deps chess==1.11.2
python tools/test.py --reference
```

The reference suite compares **68,480 moves across 94 positions**, including
castling, pins, en passant, promotions, king adjacency, and random legal games.
Every accepted move's resulting position, castling rights, and en passant state
is checked. Separate tests cover the public keyboard interface, Fool's Mate,
restart, cursor limits, VGA timing, and JTAG backpressure/echo sequencing.

Capture the actual HDL renderer, without a physical monitor:

```powershell
python tools/render_preview.py
python tools/render_preview.py --mode 2
```

Output is `build/frame_0.png` (selected e2 pawn) or `build/frame_2.png` (promotion
menu). Modes 1 and 3 exercise checkmate and stalemate labels. These screenshots
come from RTL simulation, not from the physical VGA output.

## Hardware troubleshooting

```powershell
& C:/altera_lite/25.1std/quartus/bin64/jtagconfig.exe
python host/keyboard_client.py --probe
```

- Expected target: USB-Blaster and device ID `031050DD` (10M50).
- Close Nios terminals or other software holding the same JTAG UART instance.
- A connected cable alone is insufficient: the board must be powered and the
  generated chess image must be programmed.
- On a timeout, reconnect instead of repeatedly sending moves. The client sends
  one command at a time and waits for its echo; a timeout has an uncertain outcome.
- The host uses the installed 64-bit JTAG Atlantic DLL, including the decorated
  C++ export names in this Quartus version. It is not a COM-port application.
- Select VGA input on the monitor. The raster uses Terasic's documented 25 MHz
  pixel timing (approximately 59.52 Hz), generated as a clock enable at 50 MHz.
- LEDR0 toggles for every consumed command; LEDR1 indicates Black to move;
  LEDR2 check; LEDR3 mate; LEDR4 stalemate; LEDR5 promotion. LEDR9:6 show the low
  four bits of the half-move count. KEY1 is reserved.

See [architecture](architecture.md) and [presentation walkthrough](demo.md).

## Hardware references

- [Terasic DE10-Lite specifications](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1021&PartNo=2)
- [Terasic user manual, mirrored by TI](https://e2e.ti.com/cfs-file/__key/communityserver-discussions-components-files/73/DE10_2D00_Lite_5F00_User_5F00_Manual.pdf): clock, key, LED and VGA pin tables; section 3.8 VGA timing.
- [Altera JTAG UART interface](https://docs.altera.com/r/docs/683130/26.1/embedded-peripherals-ip-user-guide/avalon-agent-interface-and-registers)

Pin assignments were checked against the Terasic manual, not the unrelated
DE2-115 projects elsewhere on the development laptop.
