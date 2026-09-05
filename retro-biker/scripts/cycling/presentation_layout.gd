extends RefCounted
## One projection for art and debug geometry. Simulation remains metres/lane units.
const WIDTH: float = 960.0
const HEIGHT: float = 540.0
const CITY_HEIGHT: float = 81.0
const LANE_HEIGHT: float = 91.8
const PLAYER_X: float = 240.0
const GROUND_FRACTION: float = 0.78
## Half-width of the widest actor art (bus), so spawners can reason about the
## first pixel that can touch the frame rather than the sprite centre.
const WIDEST_ART_HALF: float = 85.0
static func lane_top(lane: int) -> float:
	return CITY_HEIGHT + float(lane) * LANE_HEIGHT
static func lane_y(lane: float) -> float:
	return CITY_HEIGHT + (clampf(lane,0.0,4.0) + GROUND_FRACTION) * LANE_HEIGHT
static func world_x(distance: float, camera_distance: float, pixels_per_metre: float) -> float:
	return PLAYER_X + (distance-camera_distance)*pixels_per_metre
## Metres of road ahead of the rider that the frame covers.
static func view_ahead(pixels_per_metre: float) -> float:
	return (WIDTH-PLAYER_X)/pixels_per_metre
## Gap at which the leading pixel of the widest art can first enter the frame.
## Spawning at or below this distance makes an entity appear out of nothing.
static func art_horizon(pixels_per_metre: float) -> float:
	return view_ahead(pixels_per_metre)+WIDEST_ART_HALF/pixels_per_metre
static func contact_rect(distance: float, lane: float, size: Vector2, camera_distance: float, ppm: float) -> Rect2:
	var extent := Vector2(size.x*ppm,size.y*LANE_HEIGHT)
	return Rect2(Vector2(world_x(distance,camera_distance,ppm),lane_y(lane))-extent*0.5,extent)
