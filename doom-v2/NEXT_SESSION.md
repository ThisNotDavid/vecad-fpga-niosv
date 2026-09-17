# Next session

Measurement session completed on DE2-115 on 2026-09-11.
Read docs/measurements/2026-09-11/README.md and docs/benchmark.md first.

- V1 remains C:/FPGA/doom, main, tag v1.0.0; all 116 archived checksums passed.
- V2 remains C:/FPGA/doom-v2, codex/v2-performance. No optimization implemented.
- User confirmed VGA, WASD, right Ctrl fire, and quit-to-title all work.
- One controlled board pair: off 8.016 FPS; on 7.964 FPS; observed +0.65% elapsed.
- Matching desktop/off/on final state and frame hash b7aab676.
- Rendering 92.149 ms/frame (~73.4%); conversion 13.049; transfer 11.998;
  logic 6.092; VGA wait 0.009. Profile does not separate compute from memory stalls.
- Historical ~5.6 FPS was uncontrolled gameplay and is not comparable.
- No independent oscillator measurement; reported 50 MHz matches HAL configuration.
- Raw logs and report are in docs/measurements/2026-09-11; build logs remain too.
- Board now runs the playable FPS-overlay demo (see update below).
- Next proposal: repeatability checks, then inspect renderer/CPU-memory behavior
  and select one measured optimization. Obtain user approval before implementation.
- Preserve V1 and use V2 for experiments. No subagents requested. Minimize repeated
  downloads/builds and keep progress updates concise.

## Playable FPS demo update

User approved skipping the preliminary V1 restore and downloading the FPS demo once.
Implemented --fps-overlay and demo-fps loader action; source changes are uncommitted
in V2. Existing measurement docs are also uncommitted. V1 remains unchanged.

- ELF: build/demo-fps/niosv/doom.elf
- SHA256: 7edc5c02dd311d893a54814fe4c7a2652734d4ac58b57274b4d182707a088af7
- Guide: docs/demo-fps.md; overlay source snapshot and hashes in build/demo-fps.
- Top-right counter updates about once per second using completed submissions and
  real millisecond intervals; no benchmark FPS hardcoding. It includes overlay cost.
- Nios paints outgoing VGA bank only, 308 extra packed pixel writes per frame.
- Desktop image inspection, timing/wrap/bounds tests, and controls regression passed.
- Single ELF download succeeded; UART confirms startup and over 2600 frames.
- User confirmed the overlay updates and all controls work normally; observed gameplay
  FPS approximately 3-10 (user estimate, scene-dependent). UART capture is closed.
- No hardware changes/recompile. Gameplay remains running when UART capture closes.
- To restore after power cycle, follow docs/demo-fps.md (V1 SOF, then demo-fps ELF).
