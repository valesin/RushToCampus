# Cycling audio credits
The original recordings in the first table below are published under CC0 1.0: https://creativecommons.org/publicdomain/zero/1.0/
Downloaded September 5, 2026 as Freesound high-quality MP3 previews; original WAV downloads were not used.
The edited Ogg derivatives are redistributed with the same CC0 dedication. No template music is used in cycling.

| Recording | Author | Source | Game use |
|---|---|---|---|
| freewheel.wav | stib | https://freesound.org/people/stib/sounds/494328/ | Mechanism, freewheel, filtered chain texture and slowed short bump foley |
| Bicycle_Bell.wav | nikiforov5000 | https://freesound.org/people/nikiforov5000/sounds/330956/ | Nearby cyclist bell |
| Car passing by.wav | 961_Studios | https://freesound.org/people/961_Studios/sounds/244407/ | Car loop excerpt; recorded in Argentina, not Copenhagen |
| Bus Passing.wav | Hupguy | https://freesound.org/people/Hupguy/sounds/138247/ | Bus engine/pass texture |
| Pedestrian street cph.wav | Matmorfus | https://freesound.org/people/Matmorfus/sounds/236946/ | Copenhagen street rumble; low-passed at 400 Hz to suppress speech detail |
| Wind(leaves).WAV | o_ciz | https://freesound.org/people/o_ciz/sounds/475448/ | Wind and filtered tyre-road foley |
| City park Ørstedsparken lake distant traffic birds autumn 1.WAV | Matmorfus | https://freesound.org/people/Matmorfus/sounds/493936/ | Copenhagen birds for waterfront and campus |

Tyre, chain, and impact textures are foley derivatives, not separate literal recordings. Exact source offsets, processing, and download URLs are recorded in sources.json. Loops use a 200 ms wrap crossfade; one-shots use short edge fades. Assets are 44.1 kHz Ogg Vorbis, with stereo district beds and mono movement/actor effects.

Perceptual review on laptop speakers/headphones is still required; low-pass filtering is not a proof that every spoken fragment is unintelligible.


## User-supplied additions (September 5, 2026)
These supplied ElevenLabs files are separate from the CC0 recordings above; no new license is asserted here.
- lane-change.ogg: a_bike_shifting_lane_#2-1788613078860.mp3. The (1) file is byte-identical and omitted. One second, short edge fades; accepted lane changes only.
- cycling-pov.ogg: AMBUrbn-POV_cycling_through_-Elevenlabs.mp3. 20-second input, one-second wrapped crossfade produces a 19-second loop; +8 dB preprocessing gain, quiet speed-following in-game layer.
- crash.ogg: VEHCar-Car_crash_into_ditch-Elevenlabs.mp3. Two seconds; -6 dB preprocessing gain and edge fades. Used for lethal collisions; original bump retained for minor impacts.
All converted with FFmpeg/libvorbis quality 4, retaining 48 kHz stereo. Audio additions apply to both visual themes and obey pause/reset.
