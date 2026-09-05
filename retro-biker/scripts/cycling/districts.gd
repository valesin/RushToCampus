extends RefCounted
## One route vocabulary for audible districts and stable visual tiles.
const TILE_WIDTH: float = 720.0
const BUILDING_RATE: float = 0.25
static func visual_district(tile: int) -> int:
	if tile < 2: return 0
	if tile < 4: return 1
	if tile < 5: return 2
	return 3
static func at_distance(distance: float, pixels_per_metre: float = 12.0) -> int:
	var tile: int = int(floor((distance * pixels_per_metre * BUILDING_RATE + 240.0) / TILE_WIDTH))
	return mini(visual_district(tile), 2)
