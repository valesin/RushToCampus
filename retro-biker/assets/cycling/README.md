# Cycling asset handoff
The current build uses generated Copenhagen facades and two generated sprite atlas frames, with procedural road strips and fallback shapes. Atlas frames use a magenta chroma-key shader at runtime; they are not transparent PNGs. Both share bottom-centre region anchors in presentation.gd. Riders and pedestrians alternate at four frames/second; vehicle/roadworks lights at two frames/second. This is prototype artwork; a production pass should supply exact registered, transparent frames. Generated mockup screenshots are references, not runtime assets.
Supply:
- Separate seamless sky/buildings layers, no HUD or traffic baked in.
- Road strips for bus, car, bike and paved pedestrian lane.
- Transparent right-facing student cyclist and other cyclist (idle/pedal frames).
- Left-facing car, bus and pedestrian sprites; stationary roadworks.
- Cycling, wind, passing traffic and collision audio.
Use bottom-centre origins; keep wheels/feet on that baseline. Collision sizes are independent of art.
TrafficDefinition.visual_scene accepts a Node2D PackedScene with its origin at the bottom centre. Dimensions at 960x540: bike about 48x56px, car 52x27px, bus 108x43px, pedestrian 24x47px, barrier 32x29px.
Artwork folders and scripts are isolated from platformer files for team collaboration.
