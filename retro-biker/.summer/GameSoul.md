# Late for Lecture — Copenhagen cycling runner
Approved design: endless side-view student commute scored by distance, matching the team's muted Copenhagen art reference.
## Core loop
Five fixed lanes top-to-bottom: bus, car, car, bike, pedestrian. Joystick up/down switches one lane per press. Automatic pedalling. A starts/confirms/retries; C pauses. B and horizontal joystick unused.
Cyclists travel right with the player. Cars, buses and pedestrians travel left; roadworks stay fixed in world space.
Headwind drains energy, tailwind replenishes it. Draft behind another cyclist in bike lane to shelter and match speed. Zero energy slows but never stops.
Cyclist and pedestrian contact: 20 energy penalty, 0.8 seconds half speed, one-second minor-hit cooldown, once per actor. Cars, buses and solid barriers end the run, even during cooldown.
Distance score and local best. No campus countdown, finish line, upgrades, quests, multiplayer or online leaderboard.
## Implementation
Dedicated scenes/cycling/CyclingGame.tscn and scripts/cycling modules. Keep original platformer scenes and global progression untouched. Generated two-frame cyclist/pedestrian/vehicle/roadworks atlases and Copenhagen facades provide early animation; separate production artwork can replace these without changing gameplay.
960x540 viewport scaling, compatibility renderer, ETC2/ASTC, 60fps cap; Linux arm64 export with separate PCK.
## Verification
Automated input and model probes plus real rendered frames; actual Uno Q screen/controller playtest required before claiming hardware readiness.
