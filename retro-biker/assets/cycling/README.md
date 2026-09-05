# Cycling artwork
city-districts.png is a generated RGBA atlas with real transparency. Source 1536×1024; row regions in presentation.gd: waterfront y0..300, residences y300..560, approach y560..780, campus y780..1024. Regions share a rendered baseline at y190. Mipmaps are generated once at load for stable minification.
The previous copenhagen-buildings.png remains as a reference and is no longer rendered.
traffic-frame-1/2.png are registered magenta-keyed prototype atlases. Chroma shader is applied only to the traffic canvas. Rider cadence follows travelled speed; other actors use their own cadence. Production sprites can replace these with transparent artwork.
Widths at960×540: rider/cyclist82,car110,bus170,pedestrian40,barrier55. Bottom-centre anchors; collision dimensions independent of source-image bounds. TrafficDefinition.visual_scene still supports Node2D replacements.
Sky/clouds, road markings, planters and university signs are separate procedural layers. Existing music and Sfx are reused. Bespoke cycling/traffic audio remains a future audio pass.
