# Rush to Campus

You are late. Campus is 1.5 km away down a Copenhagen street, and the street is
full of buses, cars, pedestrians and other cyclists who are all having a better
morning than you. Pick a lane, keep your legs turning, and try to arrive.

It is a five lane endless-runner that ends somewhere: the route has a finish
line, a clean line through it takes about a minute and three quarters, and a
real ride with traffic in the way lands closer to two and a quarter. Built with
[Summer Engine](https://github.com/SummerEngine) and shipped on an
[Arduino Uno Q](UNO-Q-PLAYBOOK.md) handheld with one joystick and three buttons.

## The ride

Five lanes, and they are not equal. From the top: bus, car, car, bike path,
pavement. You start on the bike path, which is the safe one, and almost
everything worth having is somewhere else.

- **Buses, cars and barriers end your run.** Cyclists and pedestrians only bump
  you, which halves your speed for a moment and costs you the time.
- **Energy is the whole game.** You start at 100. A boost spends 20 of it and
  buys you two seconds at 21.6 m/s instead of the usual 14.4. Run yourself to
  zero and you get two seconds of freewheeling at half pace while you get 25
  back, which is the worst possible thing to happen in traffic.
- **Wind rolls through in phases** of calm, headwind, calm, tailwind, announced
  two seconds before they land. Headwind drains 4 energy a second. Tailwind
  gives you a tenth more speed for free.
- **Drafting is the reward for nerve.** Sit 2 to 6 m behind a cyclist in the
  bike path and you gain 5 energy a second and stop paying for the headwind
  entirely. You also inherit their speed, so a slow wheel is a cage.
- **Food is the other half.** Rugbrød is worth 20 energy and a Danish is worth
  30, and both prefer the lanes you should not be in. Rugbrød lands in the bus
  lane five times as often as on the pavement, and Danishes lean far harder
  again, so the good one is usually sitting in the worst place on the street.

Traffic thickens as you get closer. Patterns arrive every 5 seconds at the start
line and every 2.2 by the time you can see the university, and the clearance
built into the safety check shrinks along the way, so the same bus feels ruder
at 1300 m than it did at 200.

It is still always survivable, though, and that part is not a vibe. Before any
group of vehicles is allowed onto the street, the game searches an 18 second
window for a line through it, at seven different riding speeds, and throws the
whole pattern away if even one of them has no answer. Pickups get the same
treatment: a rugbrød is only placed if there is a safe way in and a safe way
back out. You can absolutely be killed by your own decisions. You cannot be
killed by a layout that was never possible.

## Controls

On the handheld:

| Input | Does |
|---|---|
| Joystick up / down | Change lane, one press per lane |
| A | Start, confirm, retry |
| B | Boost |
| C | Pause, or back out of a menu |

On a keyboard, `W`/`S` or the arrow keys steer, `J` confirms, `K` boosts and `L`
pauses. `Enter`, `Space` and `Escape` work too. Every screen is reachable
without a mouse, because nobody holding the handheld has one.

## Play it on the handheld

The board is an Arduino Uno Q, which runs the game on its Linux side as an
Arduino App Lab app. Two documents cover it end to end:

- [CONNECTING-TO-THE-BOARD.md](CONNECTING-TO-THE-BOARD.md) for plugging it in
  and the one time setup in App Lab.
- [UNO-Q-PLAYBOOK.md](UNO-Q-PLAYBOOK.md) for the project settings the board
  needs, the Linux arm64 export preset, and how deploys actually work.

Short version: export the `Linux arm64 (Uno Q)` preset as release, push the zip
over USB-C, and the installer turns it into an app that also becomes the boot
app. The game holds 60 fps at 960x540 on the board, and every deploy after the
first takes about half a minute.

If the screen is black or you want to know how it auto-starts, that is
[BOARD-SCREEN-WAKE.md](BOARD-SCREEN-WAKE.md) and
[BOARD-BOOT.md](BOARD-BOOT.md).

## Play it on a desktop

Open `retro-biker/` as a project in Summer Engine and press play. It is a
standard Godot 4.7 Mono project, and the `.godot/` cache plus the `*.import`
sidecars are deliberately not committed, so the first open spends a while
reimporting the art and audio before anything will run.

The game boots to the menu, which is also where the look toggle lives. There
are two complete art treatments, Colourful and Illustrated, and the button
switches between them without leaving the screen.

## What is in the repo

```
retro-biker/
  scenes/cycling/     the run itself
  scripts/cycling/    rider, traffic, food, wind, audio, presentation
  scripts/            menu and result screens, autoloads, platformer leftovers
  assets/cycling/     city art, street art, CC0 audio with credits
  tests/cycling/      headless check suites and probes
  export_presets.cfg  Linux arm64 for the board, Web for the browser
```

The run is one scene with a script per concern instead of a node tree per
concern. `run_controller.gd` owns the simulation and steps everything in
`_physics_process`; `traffic_director.gd` decides what appears and proves it is
survivable; `food_director.gd` reserves corridors for pickups; `rider.gd` holds
energy, boost and lane state; `presentation.gd` draws the whole street in
immediate mode across six layers and interpolates the scroll between physics
ticks so the city does not judder.

A word on `retro-biker/README.md`: this started life as a platformer template,
and that file still describes it. The platformer scenes and scripts are along
for the ride in the same project. The cycling game is what boots.

## Tests

The suites are headless GDScript, so they run without a window and without a
person:

```bash
<engine> --headless --path retro-biker -s res://tests/cycling/web_checks.gd
```

That prints one JSON blob with 96 model checks in it, covering energy
transitions, drafting, collisions, persistence, the difficulty ramp and the
promise that no impossible pattern can spawn. `route_bench.gd` is a second
harness that keeps a copy of the old route search next to the current one and
asserts they answer identically, which is what makes it safe to optimise a
function the whole difficulty model depends on.

`tests/cycling/README.md` is the running log of what has actually been measured,
including the parts that have not been: speaker listening and a human opinion on
whether the difficulty ramp is any fun are both still open.

## Credits

Audio is CC0, with per file sources, licences and edit notes in
`retro-biker/assets/cycling/audio/CREDITS.md`. The city and street art are
generated atlases layered with procedural sky, markings and signage, described
in `retro-biker/assets/cycling/README.md`. Code is under the licence in
`retro-biker/LICENSE`.
