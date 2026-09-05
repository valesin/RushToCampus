# Late for Lecture — three-minute Copenhagen commute
Approved update: a 1,500 metre student ride ending at university; target roughly three minutes, not a countdown. Laptop-first testing; teammates own Arduino deployment. Web export is separate.
## Gameplay
Five fixed lanes: bus, car, car, bike, pedestrian. Up/down or W/S moves one lane per press in 0.18 seconds. Enter/Space/J starts, confirms and retries; Escape/L pauses. Handheld bindings remain A=J, C=L.
Base speed 12 m/s. Pedalling drains 5 energy/s until 20%; recovery adds 10/s until 60%. Headwind adds -3/s, tailwind +3/s. Drafting uses -1/s pedalling or +12/s recovering and removes the headwind energy penalty.
Pedalling targets 65–100% speed according to energy; recovery targets 60%. Wind multipliers remain calm 1, head .75, tail 1.2 and sheltered head .9. Acceleration 3 m/s², deceleration 4 m/s². Cyclists travel 7.8 m/s. Draft gap is 2–6 clear metres between hitboxes.
Minor hits cost 20 energy and halve speed for .8 s, once per actor with 1 s minor cooldown. Vehicles/barriers remain lethal. Collisions up to arrival take priority; later collisions are ignored. Arrival from any lane freezes the run and shows journey time. Local best distance preserved.
## Presentation
960×540 with five 70px road bands from y190. Rider/cyclist widths82px, car110, bus170, pedestrian40, barrier55. Lower contact hitboxes scale independently.
Transparent district atlas progresses waterfront → residences/cafes → campus approach → university. Sky, buildings and roadside move at 5%,25%,100% of road speed. Stable global tile identity, interpolated scroll distance, city mipmaps. Chroma key is restricted to traffic. Signs at1000m and1300m.
## Team boundaries
Continue codex/copenhagen-cycling-runner. Keep platformer progression, pre-existing MainMenu edits and backup intact. No hardware deployment or merge. Fresh export is required before teammates deploy; previous ZIP predates this update.
## Verification
See tests/cycling/README.md. Measured traffic commute 3:01 with real keyboard event injection at accelerated simulation speed; baseline collision-free model 2:55. Physical device readability and frame rate remain for teammates to verify.

## Copenhagen soundscape — September 5 audio pass
No template music or platformer effects in cycling. CyclingAudio owns ambience, speed-linked mechanism/tyres, wind/shelter, four positional traffic voices, per-actor bells and physical collision foley. Pause freezes audio; retry resets it. Three-second district crossfades share city tile boundaries. CC0 sources and edited previews are credited under assets/cycling/audio; see .summer/audio-bible.md.
Added decorative railings, moored boats, bridge lamps, bicycles, bus stops and Danish street plaques above the lanes. No gameplay tuning changed.
Audio probe:21 checks pass. Model regression:42 checks pass. Full keyboard run:1500m in181.511 game seconds at4x simulation,49 encounters,16 switches; earlier1x driver crashed at832m. Hidden renderer28fps,median35.506ms,p9537.906ms. Software audio recording passes peak checks; speaker/headphone listening and speech-fragment audit remain unverified. No new export, push, merge or hardware deployment.
