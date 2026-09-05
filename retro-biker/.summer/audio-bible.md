# Audio Bible — Late for Lecture
Approved September 5, 2026. Realistic, slightly heightened Copenhagen; no music, dialogue, or musical arrival stings. Existing 1500 m commute and gameplay tuning unchanged.

## Layers and events
- Waterfront, busy street, campus: 29.8 second stereo loops with 3 second linear gain crossfades. Shared districts.gd selects the district under the rider: at default scale the transitions are 400 m and 880 m; university frontage follows the existing visual tile identity.
- Tyres/mechanism follow actual speed; recovering reduces chain volume and adds quiet freewheel. Drafting reduces wind by 9 dB with a bounded half-second response. Wind follows the existing wind transition.
- Up to four nearest/prioritised vehicle/cyclist voices. Relative position drives gain and right-to-left panning. Lane separation attenuates 2.5 dB per lane. No positional ambience horns.
- Cyclist bells: within 14 m ahead in the rider's lane, once per actor lifetime, global 2 second cooldown. Actor generation keys prevent reused pool instances inheriting voices.
- Minor bump once on accepted collision; lethal bump immediately stops movement and ducks ambience 10 dB for 1.2 seconds. Arrival stops movement and leaves campus ambience. No template Sfx calls.
- Pause suspends all voices and mix timers. Retry clears voices, actor ownership, effects, cooldowns, and district state.

## Implementation
CyclingAudio is scene-local. Runtime buses: CyclingAmbience, CyclingRider, CyclingTraffic, CyclingInterface; four child traffic buses own panners. Remove owned buses on scene exit. No persistent project bus changes.
GameManager.stop_music stops playback and clears current track, so separately launched platformer music can restart normally.
Assets and provenance: assets/cycling/audio/CREDITS.md and sources.json. 11 compact CC0 derivatives. Prepared clips peak-normalized to -5.04 dBFS before Vorbis encoding; runtime groups add 10 dB to the individual voice settings to improve laptop audibility. Measured full-run software mix: -29.3 LUFS, -13.7 dBFS true peak; mono preview -29.4 LUFS, -11.1 dBFS true peak. No new audio UI.

## City details
Decorative waterfront railing, moored boat, bridge lamps, parked bicycles, bus stop, and Danish street plaques remain above y190. Direction markers at 1000/1300 m are preserved. Shared stable tile identities and 5/25/100 percent parallax remain.

## Verification
tests/cycling/audio_probe.txt covers resource loading, music removal, shelter/recovery, bells, pooling, traffic cap/pan, crossfade, collisions, pause/retry and arrival.
tests/cycling/audio_commute_probe.txt runs real keyboard events at 4x simulation and records the software mix. Verification uses the Dummy output driver: recording the mix is not physical speaker/headphone verification.
