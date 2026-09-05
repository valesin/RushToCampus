# Starting the game on the Uno Q

How the game boots and how to get it running again. No App Lab click-through needed
once a game has been shipped.

## After a deploy

The ship step **starts the game for you**. Look at the board’s screen — you should
already be in the game (or on its title screen).

You do **not** need to open Arduino App Lab and press Run.

## After power-off / unplug

The last game that was shipped is the **boot app**. Power-cycling the board (unplug
USB-C, wait a few seconds, plug back in) should bring that game up by itself.

Give the board about a **minute** after power-up before expecting USB/`adb` or the
display to be ready.

## If it isn’t running

Ask Claude (or run yourself over USB):

```bash
adb shell "arduino-app-cli app start user:rushtocampus"
```

To check status:

```bash
adb devices
adb shell "arduino-app-cli app list" | grep user:rushtocampus
```

`running` means the app containers are up. If the screen is still black, that’s a
display issue — see `BOARD-SCREEN-WAKE.md`, not a missing start.

## Controls (this game)

- **Joystick up / down** — change lane  
- **A** — confirm / start  
- **B** — boost (2 seconds, costs 20 energy)  
- **C** — pause  

(Joystick left/right are unused in the cycling runner.)

## What not to do

- Don’t restart `lightdm` or reboot the desktop session just to “start” the game —
  that tears down the display and often leaves the panel dark.
- Don’t assume a black screen means the game isn’t running — check `app list` first.
