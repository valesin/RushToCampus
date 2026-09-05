# Building for the Arduino Uno Q — the short version

Everything below comes from `github.com/SummerEngine/summer-uno-q` (`README.md` +
`SKILL.md`), stripped to what actually matters. The board's Linux side (a Qualcomm
chip) is what runs the game, so "exporting for the Arduino" means exporting a
**Linux arm64** build.

## The controller, decided up front

The handheld has **one joystick and three buttons, labeled A, B, C**. That's the
whole input surface — no keyboard, no mouse, no extra buttons. Every mechanic and
every menu has to work with just those four inputs. Under the hood the joystick
sends W/A/S/D (and arrow keys) and the buttons send J/K/L — but nobody should ever
see those letters. Anything written for a player — a hint, a menu label, a "press
X" prompt — says **joystick** and **A / B / C**, never the key names.

## Project settings the board needs (done once, right after creating the project)

These go in immediately, before any art or levels — changing them later means
re-checking everything that already looked fine.

In `project.godot`:

```ini
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/vram_compression/import_etc2_astc=true

[application]
run/max_fps=60

[display]
window/size/viewport_width=800
window/size/viewport_height=480
window/stretch/mode="viewport"
```

- **`gl_compatibility`**, not the default `forward_plus` — the desktop renderer does
  not run on this board.
- **800×480, `viewport` stretch** — the game always renders at this size and scales
  up to whatever screen is attached, so frame cost never depends on the monitor.
  Leaving it at screen resolution instead: ~38 fps at 1080p vs 60+ at 800×480.
  Pixel-art games can go lower (480×270).
- **`import_etc2_astc=true`** — the mobile texture format this GPU can read.
  Without it, textures look fine in the editor and show up pink or black on the
  actual board.
- **Never turn on `msaa_3d`** — it tanks performance on this GPU.

**3D games only**, five more lines under `[rendering]`:

```ini
lights_and_shadows/directional_shadow/size=1024
lights_and_shadows/directional_shadow/soft_shadow_filter_quality=0
scaling_3d/mode=0
scaling_3d/scale=0.7
shading/overrides/force_vertex_shading=true
```

Measured difference on a stock 3D scene: 34 fps without these lines, 82 fps with.
If a 3D game is still slow after this, the fix depends on *why* — see "Tuning"
below.

## Export settings (also done once, right after creating the project)

Add to `export_presets.cfg` (check whether a `[preset.0]` already exists — if so,
this becomes `[preset.1]` / `[preset.1.options]`, never overwrite the existing one):

```ini
[preset.0]
name="Linux arm64 (Uno Q)"
platform="Linux"
runnable=true
export_path="build/game-linux-arm64.zip"
script_export_mode=2

[preset.0.options]
binary_format/embed_pck=false
binary_format/architecture="arm64"
texture_format/s3tc_bptc=false
texture_format/etc2_astc=true
```

- **`architecture="arm64"`** — the board's chip, not x86_64.
- **`etc2_astc=true` / `s3tc_bptc=false`** — mobile texture formats. The desktop
  defaults are the exact opposite of these.
- **`embed_pck=false`** — the installer needs the game binary and its `.pck` data
  file as two separate files. One embedded file also risks tripping App Lab's
  100 MB per-file limit.
- Always export **release**, not debug — debug builds are bigger and slower, and
  this board has no headroom to spare.

## Controls, in code

- Add **W/A/S/D** (and arrow keys) to Godot's built-in `ui_up/down/left/right`, and
  **J** to `ui_accept`, so every menu is fully keyboard-navigable — there's no
  mouse in a player's hands. Every screen (title, pause, game over) must be
  playable start-to-finish with just WASD + J.
- Bindings: **joystick → W/A/S/D**, **button A → J**, **button B → K**,
  **button C → L**.
- Hide the mouse cursor in code, once, in an autoload:
  `Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)` — no project setting achieves
  this on the actual board, it has to be this line of code.

## Tuning performance (3D only, if it's still slow)

- The shadow-size settings above are what buys most of the performance — don't
  disable shadows instead, that looks worse and helps less.
- `scaling_3d` renders the 3D scene at 70% while keeping UI/text at full res —
  prefer this over lowering the whole design resolution again.
- `force_vertex_shading` changes the look the most for the least gain — the first
  thing to drop if lighting looks wrong.
- A `.glb`/`.gltf` model with a shadow-casting light needs
  `meshes/create_shadow_meshes=false` on that import, or the log floods with
  material errors and the scene crawls.
- Texture import settings (`compress/mode`, `mipmaps`, `size_limit`) shrink file
  size and load time — they don't buy frame rate, so don't reach for them when
  the actual complaint is a slow frame rate.
- If a scene draws thousands of tiny meshes (one draw call each), no setting here
  fixes that — it needs fewer draw calls/particles, not another settings pass.

## Getting it onto the board

**One-time, per board**, done in **Arduino App Lab** on this laptop with the board
plugged in over USB-C:
1. Open App Lab, plug the board in.
2. Give the board a name.
3. Skip Wi-Fi — the game doesn't need it.
4. Set a password — needed once more later, typed by hand in a terminal, never
   shared in chat.

**Every deploy**, two things get asked fresh — never guessed from a folder name:
- The game's **name** (becomes the app's name in App Lab, and the install slug —
  guessing wrong means a duplicate app instead of an update).
- An **icon emoji** (🎮 is a fine default).

**What actually happens on deploy:**
1. The game gets exported fresh on this laptop (never reuse an old zip, even if it
   looks current — a full export only takes 10–20 seconds).
2. It's pushed to the board over the same USB-C cable and installed as an app in
   Arduino App Lab.
3. First deploy also sets up the board itself (slower); later deploys are quick.
4. The game starts on the board whether or not a screen is attached — plug the
   board into a monitor (HDMI/DSI) to actually see and play it.
5. **Nothing counts as done until it's been played on the board itself**, on a
   screen, with hands on the controls. Running isn't the same as playtested.

**Removing a game from the board** (the container has to be removed too, or it
keeps ~325 MB pinned on the board's small disk):
```
adb shell "arduino-app-cli app stop user:<slug>; docker rm <slug>-game_runner-1; rm -rf /home/arduino/ArduinoApps/<slug>"
```

## Ground rules

- Don't hand-run `adb`/`docker`/`apt`/SSH commands on the board — only the deploy
  skill's own scripts touch the hardware. An improvised fix here can burn a whole
  day and looks, from the outside, like a game bug.
- Don't ship a 3D project still set to `forward_plus` — it looks fine in the editor
  and fails on the board.
- Don't export debug builds, and don't export x86_64 — the board is arm64 and
  rejects the wrong binary outright.
- A USB-C **data** cable, straight into the laptop, no hub. Give the board close to
  a minute after power-up before expecting it to show up.
- Multiple games can live on the board at once; deploying the same name again just
  updates that app in place.
- Controllers (the joystick + A/B/C buttons) arrive as ordinary keyboard events —
  no special input code needed beyond the bindings above.
