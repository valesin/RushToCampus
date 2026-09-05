# Connecting to the Arduino Uno Q

Plain-language notes on getting the board talking to this laptop. Nothing here needs
`adb`, `docker`, or any command typed by hand — the actual deploy is handled by a Claude
Code skill (`ship-to-unoq`) that already lives on this machine. This file is just what a
human needs to know and do.

## 1. Plug it in

- Use a USB-C **data** cable (not a charge-only one), straight from the board into this
  laptop — no USB hub in between.
- After power-up, give the board about a minute before expecting the laptop to see it.

## 2. One-time setup (only needed once per board)

This part happens in an app called **Arduino App Lab**, on this laptop, with the board
plugged in:

1. Install and open Arduino App Lab, then plug the board in over USB-C.
2. Give the board a name.
3. Wi-Fi — you can skip this; the game doesn't need it.
4. Set a password — remember it, you'll type it once more later (Claude will ask you to
   type it yourself, in your own terminal, when it's needed — it never asks for it in
   chat).

Once that's done, the board remembers it — you won't redo this for future games.

## 3. How the game actually gets onto the board

When it's time to ship a build:

- Claude exports the game on this laptop (not on the board).
- The `ship-to-unoq` skill pushes it over the same USB-C cable and installs it as an app
  inside **Arduino App Lab** on the board (visible under "My Apps").
- The first deploy also sets up the board itself (this takes a bit longer); later
  deploys are quicker.
- The game starts on the board whether or not a screen is plugged into it — to actually
  see and play it, connect the board to a monitor (HDMI/DSI).

## 4. Controls, once it's running

The board's controls are a joystick and three buttons, labeled **A**, **B**, and **C**.
That's the entire input surface for the game — no keyboard, no mouse, no extra buttons.

## Related notes

- Starting / rebooting the game: `BOARD-BOOT.md`
- Black screen while the game is running: `BOARD-SCREEN-WAKE.md`

## What not to do

- Don't run `adb`, `docker`, or board commands by hand — ask Claude to do it through the
  `ship-to-unoq` skill instead, so nothing gets out of sync with what's actually on the
  board.
- Don't assume it's working until it's been played on the board itself, on a screen, with
  hands on the controls.
