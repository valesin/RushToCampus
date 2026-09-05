# Platform Quest — 2D Platformer Template

A complete, playable side-scrolling 2D platformer built with **[Summer Engine](https://github.com/SummerEngine)** (Godot 4.6 / Mono). Use it as a starting point for your own Summer Engine project — it's a full vertical slice you can rip apart, reskin, or extend.

Everything here is hand-rollable: sprites are drawn procedurally by small PowerShell scripts in `tools/`, and the music/SFX were generated through Summer Studio. No paid or third-party assets.

## What's inside

- **Main menu** with splash art, plus themed **Game Over** and **You Win!** screens.
- **4 levels** of increasing complexity, then a **boss room**.
- A **boss** — the "Critter King", a big stompable enemy that paces the arena, telegraphs charge-dashes, enrages as it loses health, and takes 3 stomps to beat.
- **Grid / tile-based levels** authored as plain-text ASCII maps (see below) — dead simple to edit or generate.
- **Dynamic platforms & hazards**: moving platforms, slopes, bounce pads, crumbling blocks, spikes, sawblades.
- **Pickups**: animated coins (with a HUD counter) and hearts that restore health.
- **Stomp combat**: jump on enemies to defeat them; get hit from the side and you lose a heart (3-heart health, i-frames, knockback).
- **HUD** with hearts + coin count, and a full **music + SFX** layer (menu / gameplay / boss tracks, footsteps, jumps, stomps, pickups, etc.).

## Controls

| Action | Keys |
|--------|------|
| Move   | `A` / `D` or `←` / `→` |
| Jump   | `Space`, `W`, or `↑` |

Jump on an enemy's head to stomp it. Reach the door `D` to finish a level; beat the boss to win.

## How the level system works

Levels are **32×32-pixel grids** stored as text files in `levels/` (`level_01.txt` … `level_04.txt`). Each character is one tile. [`scripts/level_loader.gd`](scripts/level_loader.gd) reads the current level and instances the matching scene at each cell, then sets up the camera bounds.

Tile legend:

| Char | Tile | Char | Tile |
|:---:|------|:---:|------|
| `.` | empty (sky) | `o` | bounce pad |
| `#` | solid block / ground | `x` | crumbling block |
| `P` | player spawn | `^` | spike |
| `G` | critter (walking enemy) | `s` | sawblade |
| `D` | exit door | `B` | boss |
| `-` | horizontal moving platform | `c` | coin |
| `\|` | vertical moving platform | `h` | heart |
| `/` | slope up | `\` | slope down |

**To add a level:** drop a new `levels/level_05.txt` and add its path to the `level_files` array in [`scripts/game_manager.gd`](scripts/game_manager.gd). **To add a new tile type:** make a scene for it and add a `match` case in `level_loader.gd`.

## Project structure

```
project.godot        # Godot 4.6 project (boots to scenes/MainMenu.tscn)
levels/              # ASCII level maps
scenes/              # Player, enemies, platforms, pickups, UI, boss, menus
scripts/             # GDScript: player controller, enemies, level loader, GameManager autoload, HUD, audio
assets/sprites/      # procedurally generated PNGs
assets/audio/        # generated music + SFX
tools/               # PowerShell scripts that draw the sprites & splash art
```

`GameManager` (autoload) owns lives, coins, level progression, and music; `Sfx` (autoload) is a pooled one-shot sound player.

## Using it in Summer Engine

Create a new project from this template in Summer Engine, or clone the repo and open the folder — it's a standard Godot 4.6 (Mono) project. On first open, Godot re-imports the assets (the `.godot/` cache and `*.import` files are intentionally gitignored), then just press play.
