# Alternative theme and Windows stability

Pause and click LOOK to switch Illustrated / Colourful. Same run, HUD, controls, audio, actor sizes and collision dimensions. Selection survives restarting a run within the session and defaults to Colourful on a fresh launch.

Latest approved layout supersedes the earlier 85/15 specification: city 135px (25%), five equal 81px bands (75%). Both themes use presentation_layout.gd. Wider district crops show Copenhagen rooftops and landmarks. Horizontal gameplay stays X=240 and 12 pixels/metre.

Windows uses rendering/gl_compatibility/driver.windows=opengl3_angle. Reproduced 0xc0000005 at 0x7ffbd0facd0d in Intel igxelpgicd64.dll (offset 0x80cd0d), matching the user's crash image. ANGLE uses Direct3D 11 while retaining Compatibility rendering. Three consecutive theme walkthroughs exited 0 after this change. Linux/Uno Q and browser backends remain unchanged; hardware performance is not certified.

Checks: 77 gameplay and nine cadence/playthrough checks passed. theme_checks.gd adds 19 checks covering actual pause-button clicks, both directions, frozen state, resume/restart, asset loading and audio triggers. Run the latter with a rendering window, not headless, since it tests GUI clicks. Captures named staged-* are arranged diagnostics.

Commands from game directory:
    godot --headless --path . --script res://tests/cycling/web_checks.gd
    godot --headless --path . --script res://tests/cycling/playthrough.gd
    godot --path . --script res://tests/cycling/theme_checks.gd -- ABSOLUTE_CAPTURE_DIRECTORY

## Drafting and final approach update
Drafting behind a cyclist restores 5 energy/second during normal riding, capped at 100; boost does not receive a refund and timed recovery is unchanged. The HUD names the gain. Traffic frequency is now distance-based (5.0 seconds at start to 2.2 seconds at the finish), with dedicated car/bus patterns increasingly preferred (15% to 80%). The same escape-route, pickup-reservation and actor-limit gates apply. Updated verification: 84 gameplay checks and nine playthrough/cadence checks pass.
