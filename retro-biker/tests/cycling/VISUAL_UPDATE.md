# Cycling presentation update

The boost baseline is fc06abf. Simulation, audio, spawn distances, player X=240, 12 pixels/metre and actor widths are unchanged. presentation_layout.gd owns the 960x540 projection: city y=0..81 and five 91.8-pixel bands, with continuous bottom-centred ground anchors. Curbs are inside the bands.

Six drawing layers separate cropped district facades, surfaces, street decorations, actors, food and HUD. District source crops are enlarged 1.5x and anchored at street level; upper floors are clipped. The translucent HUD uses a fading backdrop and compact icons. Its menu button toggles the existing pause state; keyboard controls remain unchanged.

Missing art was generated with the built-in image generation tool, using the approved mockup as a style reference only. No flattened reference is rendered. street-materials.png is a 1254-square atlas of weathered asphalt, terracotta and stone. Strips repeat with alternate mirroring. street-sprites.png is a 1254-square atlas keyed with street_key.gdshader; existing traffic animation remains intact.

Generation prompt briefs:
- Materials: three equal horizontal panels of seamless horizontally repeating illustrated asphalt, terracotta cycle-track and stone paving; weathered Copenhagen reference style; no objects, text or markings; opaque surfaces.
- Sprites: six isolated illustrated objects in two columns and three rows: rugbrod, Danish pastry, natural planting in a stone planter, cafe chair, granite curb, worn white bicycle and arrow decal; consistent weathered reference style.
- Sprite correction: preserve objects, arrangement and colours; replace the generated checkerboard background and gaps with solid #ff00ff for runtime keying.

Run from the game directory with Godot 4.7.2:

    godot --headless --path . --script res://tests/cycling/web_checks.gd
    godot --headless --path . --script res://tests/cycling/playthrough.gd
    godot --path . --script res://tests/cycling/visual_checks.gd -- ABSOLUTE_CAPTURE_DIRECTORY

Verified September 5, 2026: 77 gameplay checks, nine playthrough/cadence checks and seven presentation checks pass. Visual fixtures are staged diagnostics, not actual playthrough screenshots. Compatibility, ETC2 and the Uno Q export preset remain unchanged. Desktop native frame timing was median 33.23 ms, p95 34.887 ms over 90 frames; this does not establish Uno Q performance.
