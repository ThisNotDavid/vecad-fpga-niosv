# Friday demonstration

## Current DE2-115 / PS/2 setup

Connect the PS/2 keyboard before powering the board, attach VGA, then run
`python tools/program.py --board de2-115`. Use the **external keyboard**, with
no laptop controller. The border is blue. **F2 shows NEW GAME on VGA; Enter
confirms and Esc cancels.** The board automatically rotates after each completed move, putting the next player at the bottom.
Arrow keys always follow the screen; use the displayed coordinates to locate pieces.
Promotion waits for a choice before rotation. New games restore White at the bottom.

For the presentation, emphasize that the FPGA receives keyboard scan codes,
enforces the rules and renders VGA. USB-Blaster is only used for programming.
The DE2-115 package and bitstream are in `build/de2_115` and `output_files/de2_115`.

The laptop-controller setup below applies only to the archived DE10-Lite version.

## Before the presentation

- Run the HDL tests and retain the verified `.sof` and build reports.
- Connect the external VGA monitor and USB-Blaster, program, and launch the client.
- Keep the keyboard controller focused. Confirm the status says Connected.
- Move the cursor once and confirm both the VGA border and LEDR0 respond.
- Press F2 and confirm the reset so the presentation starts in the initial position.

## Suggested three-minute walkthrough

1. **Explain ownership:** the laptop sends keyboard commands; the FPGA stores the
   board, validates chess moves and generates the VGA picture.
2. **Show legal destinations:** the cursor starts on e2. Press Enter. The e3/e4
   markers appear. Press Up twice and Enter to play e2-e4.
3. **Show an illegal move:** select a blocked piece or try a destination without
   a marker. The board stays unchanged. Esc cancels the selection.
4. **Demonstrate a result:** reset and play Fool's Mate using the moves below.
5. **Discuss implementation:** sequential state machines, trial positions, sprite
   ROM, VGA timing, and JTAG UART command acknowledgements.

Fool's Mate from a new game: **f2-f3, e7-e5, g2-g4, d8-h4**. The sidebar should
show CHECKMATE / BLACK WINS, White's king is highlighted, and moves are disabled.
F2 starts another game.

For each move, navigate to the source square, Enter, navigate to the destination,
Enter. On the current DE2-115, the board flips each turn and labels follow the orientation.
On the archived DE10-Lite, rank numbers increase upward; file letters increase rightward. Cursor
orientation remains White-at-bottom throughout the game.

## Presentation talking points

- This is hardware chess logic in SystemVerilog, without a soft processor.
- A small board representation stores the position in 256 bits.
- Sequential move/attack scans trade a little latency for lower logic usage.
- The display uses a pixel enable and registered rendering pipeline.
- Independent reference tests check resulting positions as well as legal/illegal
  decisions. Hardware echo testing verifies the real USB-Blaster path separately.
- Future upgrades: clocks, move history, draw adjudication, AI, and better artwork.

Keep simulation verification and physical observations distinct when reporting
results. A generated preview is not a photograph of the monitor.
