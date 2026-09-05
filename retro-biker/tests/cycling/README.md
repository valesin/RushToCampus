# Cycling runner verification — 5 September 2026

Branch: codex/copenhagen-cycling-runner. Entry: scenes/cycling/CyclingGame.tscn.
Original MainMenu/Level scenes and platformer scripts remain independently available. A direct Level smoke probe loaded successfully; it retained a pre-existing sky.jpg UID fallback warning. This was a load smoke check, not a full replay of all four platformer levels.

## Reproduce
Submit the complete contents of gameplay_probe.txt as RunVerification.probe_source through Summer MCP, max_seconds 25. The base class is supplied by Summer's verification runtime, so keep the stored probe as .txt. It calls runner_checks.gd, injects real confirm/pause actions, stages every actor category and captures both animation frames plus results. Test saves use isolated paths, not the player's cycling_best.json.

## Latest evidence
36 checks passed; finished true; errors_seen empty.
Local evidence: .godot/summer_verify/21112_5602909/results.json and three screenshots.
Checks cover lane latch/edges/transitions, wind warning/blend/rates, exhaustion, drafting/matching/release, minor cooldown/once per actor, lethal during cooldown, swept collision including an extreme vehicle crossing the entire viewport in one step, retry/pause, score persistence and corrupt data, authored-pattern escape checks and population bounds.

A separate real-input/natural-traffic run accepted encounters, reached 118.14 m and entered headwind with five actors active. It measured 30 engine fps, median 33.813 ms and p95 35.117 ms between sampled physics-frame signals in the hidden Windows verification instance. These are desktop probe measurements, not a hardware benchmark.
Evidence: .godot/summer_verify/21112_5472860.

## Fairness limits
The route graph checks 18 seconds ahead at constant speeds 1.8, 3.6, 8 and 9.6 m/s with swept transitions and added collision margins. Every authored pattern is tested from all five lanes. This is a conservative sampled guard, not a proof covering every possible player action or continuously varying speed. A player can still choose an unsafe route.

## Build and remaining playtest
Linux arm64 release ZIP exported with separate PCK; ELF machine code 0xB7 confirms AArch64. Compatibility renderer, ETC2/ASTC imports, viewport 960x540 and 60 fps cap configured.
No USB board detected by adb devices -l. Deployment, physical joystick/button feel, on-screen readability and Uno Q frame rate remain unverified. Follow the summer-uno-q runbook for deployment.

## Team boundaries
No push or commit performed. Pre-existing MainMenu.tscn edits and project.godot.bak preserved. project.godot combines the pre-existing 4.7 feature update with our input, renderer, display and final entrypoint changes; separate those hunks when reviewing/committing.
Generated art is provisional. Two magenta-keyed atlases provide pedalling/walking and lamp changes; final transparent frames and seamless road art can replace them. Existing music and Sfx are reused; bespoke cycling/traffic audio remains an art/audio follow-up.
