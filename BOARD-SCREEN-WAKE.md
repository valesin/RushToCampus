# Waking the Uno Q screen

The 7″ DSI panel sometimes stays dark even when the game is running and the OS
thinks the display is on. Software shows backlight at max, DRM `connected` /
`enabled`, and the game window on `:0` — and the panel is still black.

**Do not restart `lightdm` to fix this.** That was tried once here and made a
working screen go dark again. Use the gentle wake below.

## Gentle wake (preferred)

With the board plugged in over USB-C:

```bash
adb shell 'export DISPLAY=:0 XAUTHORITY=/home/arduino/.Xauthority
xset s off -dpms
xset dpms force on
xrandr --output DSI-1 --off
sleep 1
xrandr --output DSI-1 --auto
sleep 1
xset dpms force on
xrandr | head -8
'
```

You want to see `DSI-1 connected 800x480` (or similar) afterward.

If the game was stopped somehow, start it **without** touching the display manager:

```bash
adb shell "arduino-app-cli app start user:bikergame"
```

## If gentle wake isn’t enough

1. **Power-cycle the board** — unplug USB-C, wait a few seconds, plug back in.
   The last shipped game should auto-start (see `BOARD-BOOT.md`). Wait ~1 minute.
2. Reseat the **DSI ribbon** to the 7″ panel if power-cycle still leaves it dark.
3. Confirm the game is actually running:
   ```bash
   adb shell "arduino-app-cli app list" | grep user:bikergame
   adb shell "docker stats --no-stream"
   ```
   CPU on `bikergame-game_runner-1` means it’s rendering even if the panel looks off.

## What not to do

- **Don’t** `systemctl restart lightdm` (or otherwise reboot the desktop) just to
  wake the panel — it often blanks a screen that was already recoverable with
  `xrandr`.
- **Don’t** assume you need Wi‑Fi or App Lab for the display. Wake and play are
  local / USB.

## Quick checklist

| Symptom | Likely cause | Fix |
|---|---|---|
| Black screen, game `running` | DSI panel asleep / stuck | Gentle `xrandr` wake above |
| Black screen after “fixing display” | `lightdm` was restarted | Gentle wake; avoid another lightdm restart |
| Still black after wake + power-cycle | Cable / panel hardware | Reseat DSI ribbon |
| App not `running` | Game not started | `arduino-app-cli app start user:bikergame` |
