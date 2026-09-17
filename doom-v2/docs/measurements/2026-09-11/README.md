# DE2-115 baseline measurement — 11 September 2026

## Outcome

V1 release verification passed (116 files). The user confirmed VGA display,
WASD movement, right Ctrl shooting, and Esc > Quit Game > Y returning to title.
Initial JTAG chain failure cleared after the user checked/reconnected the board.
The proven V1 SOF programmed successfully with zero errors and warnings.

One profiling-off/on benchmark pair completed on DE2-115. This is an initial
controlled baseline, not a statistically established repeatability range.
No CPU, cache, SDRAM, RTL, game-feature or optimization changes were made.

| Measurement | Profiling off | Profiling on |
|---|---:|---:|
| Average FPS | 8.016 | 7.964 |
| Measured elapsed time | 43.663230 s | 43.947828 s |
| Median frame time | 126.559 ms | 126.844 ms |
| 95th-percentile frame time | 145.978 ms | 146.320 ms |
| Maximum frame time | 153.031 ms | 157.713 ms |

Observed elapsed-time difference: +0.65% with profiling. One pair cannot isolate
instrumentation cost from all run/layout variation. Repeat alternating runs before
claiming small improvements. The historical uncontrolled ~5.6 FPS gameplay figure
is not comparable to this timedemo; 8.016 FPS is not an optimization gain.

## Where time goes

Profiled elapsed time divided by 350 frames is 125.565 ms/frame. Stage totals
below cover sampled frames; about 0.050 ms/frame lies between sampled boundaries.

| Stage | Mean ms/frame | Approximate share of elapsed time |
|---|---:|---:|
| 3D rendering | 92.149 | 73.39% |
| Framebuffer conversion/copy | 13.049 | 10.39% |
| VGA framebuffer/palette transfer | 11.998 | 9.56% |
| Game logic | 6.092 | 4.85% |
| Other sampled work | 2.218 | 1.77% |
| VGA swap wait | 0.009 | 0.007% |

Rendering dominates this route. These timers do not separate CPU computation
from SDRAM/cache stalls within rendering. Negligible swap wait gives no evidence
that monitor refresh is the present bottleneck.

A theoretical calculation using this profile: halving rendering time alone gives
about 12.58 FPS; removing all measured VGA transfer cost gives about 8.81 FPS.
These are illustrative upper-bound scenarios with other costs held fixed, not
promises of achievable hardware performance.

## Workload and validation

350 measured frames after 70 warm-up frames. Freedoom 0.13.0 Phase 1, E1M1,
medium skill, normal enemies, fixed recorded inputs, 320x200 indexed output,
high detail, screenblocks=10, 16 MiB zone, silent sound, benchmark wipes disabled.
One game tic per frame, so this measures timedemo throughput rather than the
normal gameplay pacing loop. Keyboard input is ignored during the benchmark.

Both reports match desktop validation exactly:
- gametic: 421
- indexed-frame FNV-1a hash: b7aab676
- x: 34061857; y: 19890797
- health: 95; ammo: 30

Both reported clock_hz=50000000, matching the saved HAL CPU/timer configuration.
Elapsed duration was consistent with the observed run. No independent oscillator
frequency measurement was performed.

Source commit: 518161c709c766aef9f28cd8ad2ce70d77c30823.
V2 was clean before measurement; hardware/RTL diff against v1.0.0 was empty.
V1 source commit: 02670fbc9dfacaa87e07576e81bd19b8334a6445.

SHA-256 identities:
- SOF: b303f82a8dd50c66cc15c05483f27f9eb18249f0769dd24a909450cb692bfeb2
- Profiling-off ELF: 64612d285fd515aa8467e73f2aae11613d6d84ee6076f89d46d6f070f913931f
- Profiling-on ELF: 9b3314666c8c367baef6f31378bfd8c1f4d0940a29ee581897a32fec45a66a50
- Demo: b6aea23bc045ef9ea9a8482d76b7b852a4663185a327cfe2c9bcc9cc3c1182bf
- IWAD: 7323bcc168c5a45ff10749b339960e98314740a734c30d4b9f3337001f9e703d

## Evidence and reproduction

Raw captured logs are preserved beside this report:
[profiling off](profiling-off.log), [profiling on](profiling-on.log),
[gameplay startup/frames](gameplay.log). Gameplay behavior was user-confirmed;
UART frame counters alone do not establish correctness of keyboard actions.

From C:/FPGA/doom-v2:

```powershell
python tools/compare_benchmarks.py docs/measurements/2026-09-11/profiling-off.log docs/measurements/2026-09-11/profiling-on.log
```

## Proposed next work — approval required

1. Establish repeatability with additional alternating off/on runs before treating
   small differences as gains.
2. Inspect generated renderer assembly, cache configuration, and SDRAM transaction
   behavior to select one targeted renderer/CPU-memory experiment. Stage profiling
   alone does not justify choosing a faster CPU clock or a new SDRAM controller.
3. Make one change in V2, retain the same route/resolution/quality, and rerun the
   benchmark. Require matching state/image hashes for changes intended to preserve
   exact rendering. Check timing closure and hardware correctness for RTL changes.
4. Consider redundant framebuffer-copy reduction as a separate later experiment.
   It accounts for ~10.4% here; do not bundle it with CPU/cache changes.

The board remains on the completed profiling-on benchmark, intentionally stopped
on its final frame. UART capture and downloader sessions were closed. Restore V1
with `python tools/run_board.py game` from C:/FPGA/doom (about six minutes).
