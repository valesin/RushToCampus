# Boost and food verification - 5 September 2026

The current energy model supersedes the historical commute figures below.

Run with stock Godot 4.7.2 from the game directory, redirecting APPDATA to a disposable workspace folder:

```powershell
$env:APPDATA = '<workspace>/work/appdata'
& '<godot-console.exe>' --headless --path . --script res://tests/cycling/web_checks.gd
& '<godot-console.exe>' --headless --path . --script res://tests/cycling/playthrough.gd
& '<godot-console.exe>' --path . --position 16000,16000 --script res://tests/cycling/render_checks.gd -- '<output-directory>'
& '<godot-console.exe>' --headless --path . --export-release Web '<output-directory>/index.html'
```

`web_checks.gd` is a SceneTree harness; it does not require SummerProbeBase. It runs the existing regression suite plus `energy_checks.gd`. `playthrough.gd` drives real keyboard events over physics frames, then compares full-route cruise, repeated exhaustion and food-assisted runs. The balance comparison disables traffic deliberately; the separate seeded director sweep measures pickup availability with traffic. `render_checks.gd` captures staged pickup and recovery fixtures, not a completed playthrough.

Inputs: W/S or Up/Down change lane; K / handheld B boosts; Enter/Space/J / handheld A starts or retries; Escape/L / handheld C pauses. Boost is edge-triggered. Collision cooldown remains collision-only.

Safety checks cover 3.6, 7.2, 7.8, 10.8, 14.4, 15.84 and 21.6 m/s. Food requires a reachable pickup waypoint with a safe continuation; active pickups reject future traffic that would overlap them or invalidate the approach. The graph is a conservative sampled guard, not a proof for arbitrary speed changes or player decisions. Unsafe opportunities retry after 0.5s. Bread begins searching at 6-6.5s to leave retry room inside the 6-8s target; pastries begin searching at 18-23s within the 18-24s target. Safety takes precedence if an exceptional layout cannot satisfy the window.

Web-only audio streaming avoids the observed sample-loop allocation failure and retains the existing audio buses/effects. Native/Uno Q playback and Linux arm64 export settings remain intact. The Web preset references the verified local toolchain; adjust those two template paths on another machine.

## Difficulty ramp and risk-weighted pickups — 5 September 2026

Design: `docs/superpowers/specs/2026-09-05-difficulty-ramp-design.md`. Difficulty rises with **route distance**, not elapsed time, so a boosting rider cannot outrun their own curve. `run_controller` passes `distance / route_length` into `traffic.step()`.

Precision: the route-check padding is now a director field interpolated from `Vector2(1.0, 0.15)` at the start line down to `Vector2(0.5, 0.075)` at university. It is a field rather than a parameter so the pickup corridors `food_director` validates through `has_route` inherit the current difficulty automatically. The `dt = 0.20` lane-change budget is deliberately untouched, since it also sets the 18 s planning horizon.

Density: `final_interval` 2.8 → 2.2 s, keyed to progress so it now completes at the finish instead of stalling near 3.03 s. Rejected patterns, and patterns blocked by `maximum_actors`, reschedule 1.0 s out instead of forfeiting the slot.

Pickups: both kinds draw from all five lanes via a weighted sample without replacement, `pow(LANE_WEIGHTS[lane], LANE_BIAS[kind])` with weights `[5,4,3,2,1]` and bias 1.0 for rugbrød, 2.0 for Danishes. Preference order degrades to safer lanes when a corridor is blocked, so availability survives. Previously rugbrød only ever spawned in lanes 3 and 4, making the main energy source a free collect.

The route guarantee never relaxes: every accepted pattern still requires a survivable line at all seven sampled speeds. Only the comfort inside it shrinks.

Evidence: 89/89 model checks pass, zero runtime errors (.godot/summer_verify/1232_1706814). New checks cover margin endpoints and monotonicity, `all_patterns_safe_at_max_difficulty`, `rejected_pattern_retries`, `actors_bounded_at_max_difficulty` and `pickups_reach_exposed_lanes`.

Seeded full route at 14.4 m/s, against the pre-change baseline in the section below: encounters 10 in the first half versus 16 in the second, traffic accepted 26 (was 20) and rejected 13 (was 5), peak 9 live actors against the cap of 24 (was 6), final margin 0.5. Rugbrød placed 14 (unchanged), Danishes 3 (was 4), deferred opportunities 18 (was 8). Realised pickup distribution by lane 0 to 4: 6/3/6/2/0, so 15 of 17 landed in the exposed vehicle lanes. The design doc predicted a much less top-heavy outcome because buses veto lane-0 corridors; that prediction was too pessimistic and the measurement supersedes it.

Full keyboard-driven commute still completes: 1500 m arrival in 135.284 game seconds at 4x simulation (98.613 wall seconds), 32 accepted encounters, 4 lane switches, arriving with 68 energy; keyboard pause and retry pass; no runtime errors. Evidence .godot/summer_verify/1232_1770145, frames at 400/800/1200 m and finish. The 1200 m frame shows a rugbrød in the bus lane beside a barrier while the rider drafts in the bike lane, which is the intended risk/reward read. This is an automated look-ahead driver, not a human difficulty assessment; only 4 lane switches were needed, so whether the ramp actually feels challenging to a person remains unverified.

Long MCP verification calls time out before this probe completes; read results.json from the matching summer_verify directory rather than retrying.

## Offscreen spawning pass — 5 September 2026

Nothing is created inside the player's field of view. `presentation_layout.gd` owns the one horizon figure: `view_ahead()` is the 60 m the frame covers at 12 px/m, and `art_horizon()` adds the widest sprite half-width for a 67.08 m gap at which a bus's leading pixel can first touch the frame. Both spawners are placed beyond it and are stepped offscreen before they are visible.

Traffic spawns at 118 m (`spawn_lead_seconds` 1.5 s against a 33.6 m/s worst-case closing speed of boost plus an oncoming car). `run_controller` clamps that up to `minimum_spawn_distance()` at load, so lowering `pixels_per_metre` cannot silently pull spawns back into the frame. Pickups spawn from 80.04 m out in 8 m steps, staying nearer than the traffic band so a newly accepted vehicle does not immediately invalidate a reserved corridor.

Previously pickups were placed at 24/32/48 m, all inside the 60 m frame, so rugbrød and Danishes materialised in plain sight. Traffic was already offscreen at 78 m but had only 0.33 s of lead at full closing speed.

Evidence: 81/81 model checks passed, zero runtime errors (.godot/summer_verify/1232_806049 and 1232_738795). New checks `traffic_never_spawns_in_view`, `food_never_spawns_in_view` and `traffic_spawn_lead_time` drive both spawners over a seeded 3000-tick stretch and assert the narrowest recorded spawn gap stays beyond `art_horizon()`. Seeded full-route A/B at 14.4 m/s: pickups placed unchanged at 14 rugbrød and 4 Danishes, deferred opportunities down from 19 to 8, traffic accepted 22 to 20 and rejected 3 to 5. A 900-frame ride with the real collision loop spawned 4 actors, each first appearing at screen x 1800 or beyond against a 960 px frame edge. Human review of approach pacing remains useful; these are automated measurements, not a difficulty assessment.

## Historical baseline evidence (not current gameplay results)

# Three-minute commute verification — 5 September 2026
## Reproduce
Run gameplay_probe.txt through Summer MCP RunVerification (max_seconds25) for runner_checks.gd and start/pause/retry checks.
Run commute_keyboard_probe.txt (max_seconds180) for the full traffic commute. It uses real key events, a look-ahead test driver and 4x simulation speed. The test deadline ignores game time scaling. This is an automated walkthrough, not a human difficulty assessment.
Run parallax_probe.txt (max_seconds30) for quick taps, native-rate desktop frame timings and raw-pixel comparisons at tile boundaries.
## Evidence
- 42 model checks passed with no runtime errors: .godot/summer_verify/21112_8115974. Baseline no-collision ride:175.699s,26 effort transitions, minimum energy19.875.
- Full keyboard traffic run: .godot/summer_verify/21112_8842151; success at1500m in181.511 game seconds (107.728s wall time),49 accepted encounters,16 lane switches, pause and retry passed; no runtime errors.
- Rendering/input probe: .godot/summer_verify/21112_8999916; 1ms key tap detected, stationary rendered frame unchanged, maximum mean RGB difference across 0.1m tile-boundary movement0.01741 (<0.035). Captured both sides of240/480/960/1200m and university sign.
- Desktop hidden-renderer measurement at normal game time:30fps,median33.157ms,p9535.535ms. This is not a Uno Q benchmark.
## Coverage and limitations
Energy hysteresis/smoothing, drafting gaps, exhaustion, per-actor penalties, lethal cooldown, swept collisions, any-lane arrival and before/after-finish collisions, persistence/corrupt saves, pause/retry, all authored patterns across five lanes and2.7/5.4/9/12/14.4m/s.
The18s route graph is a sampled guard, not a proof for arbitrary changing speeds or player decisions. Earlier greedy keyboard drivers crashed; the passing driver favours bike/pedestrian lanes and plans6s ahead. Accelerated probes initially timed out because the test Timer inherited time scale; the saved driver fixes that.
Flicker was not reproduced as a deterministic old-build failure. The new renderer separates the chroma shader, uses city mipmaps and continuous tile identities; captures show no tile jumps or static flicker. Human review of movement remains useful.
## Handoff
Open scenes/cycling/CyclingGame.tscn (now the entry scene). Enter/Space/J start and retry; W/S or arrows move; Escape/L pause. Preserve local pre-existing project feature update,MainMenu edits and backup.
Physical device playtest belongs to teammates. No new hardware export or deployment performed; the prior build ZIP is stale. Web export is separate.

## Audio and city-details pass — September 5
- audio_probe.txt (RunVerification max_seconds45): 21/21 passed, zero errors. Evidence .godot/summer_verify/21112_10547714.
- runner_checks.gd via current-scene probe: 42/42 passed, zero errors. Evidence .godot/summer_verify/21112_11387140.
- audio_commute_probe.txt (max_seconds240): full 1500m arrival in181.511 game seconds at4x simulation,135.12 wall seconds,49 encounters,16 lane switches,2 bells,maximum4 traffic voices. Keyboard pause and retry passed, music remained stopped, zero errors. Evidence .godot/summer_verify/21112_11019388.
- Earlier normal-speed test driver crashed at832.414m/95.9 game seconds; it did not complete. Evidence .godot/summer_verify/21112_10672686. Do not present accelerated success as a completed normal-speed human playtest.
- city_audio_visual_probe.txt (max_seconds40): quick-tap input, static frame stability and all10 tested tile/marker boundaries passed. Largest mean RGB change0.0187603 (<0.035). Evidence .godot/summer_verify/21112_11268821. Plaques captured at180/640/1390m.
- Hidden desktop render performance:28fps,median35.506ms,p9537.906ms. The60fps target is not established by this measurement.
- Engine software mix recorded via AudioEffectRecord using Dummy output driver: full ride -29.3 LUFS and -13.7dBFS true peak;45-second mono preview -29.4 LUFS and -11.1dBFS true peak. No measured clipping. This is NOT physical speaker/headphone listening.
- Old live session had a Windows WASAPI device-invalidated error. Restarted game: zero console/debugger/script errors; remaining warnings are existing time-display integer division, Sfx parameter shadowing, and editor focus.
- Perceptual audition on laptop speakers/headphones and a final audit for intelligible speech, incidental music/horns in field recordings remain unverified. Street ambience is low-passed to suppress speech; no claim that filtering proves every voice is unintelligible.
- Capture file generated by the full probe: user://cycling-full-commute.wav. Long MCP verification calls may time out before the child completes; inspect the matching .godot/summer_verify directory for results.json before retrying.
- CC0 author/source/licence and edit records ship in assets/cycling/audio. Export preset now includes those text files; no export/deployment was run. Local changes are not pushed.
