extends RefCounted
var definition: Resource
var distance: float = 0.0
var previous_distance: float = 0.0
var encountered: bool = false
## Gap ahead of the rider this actor was placed at. Spawners keep it beyond the
## frame, so nothing is ever created inside the player's field of view.
var spawn_gap: float = 0.0
var audio_generation: int = 0
var bell_played: bool = false
var visual: Node2D

func configure(spec: Resource, at_distance: float) -> void:
	audio_generation += 1
	bell_played = false
	definition = spec
	distance = at_distance
	previous_distance = distance
	encountered = false

func step(delta: float) -> void:
	previous_distance = distance
	distance += definition.speed * delta

func lethal() -> bool:
	return definition.kind in ["car", "bus", "barrier"]

## Swept relative point against a Minkowski-expanded rectangle.
## X is metres; Y is lane coordinates. Also catches crossing during lane changes.
static func swept_contact(start: Vector2, end: Vector2, half_size: Vector2) -> bool:
	var movement: Vector2 = end - start
	var entry: float = 0.0
	var leave: float = 1.0
	for axis in range(2):
		if absf(movement[axis]) < 0.000001:
			if absf(start[axis]) > half_size[axis]:
				return false
		else:
			var a: float = (-half_size[axis] - start[axis]) / movement[axis]
			var b: float = (half_size[axis] - start[axis]) / movement[axis]
			entry = maxf(entry, minf(a, b))
			leave = minf(leave, maxf(a, b))
			if entry > leave:
				return false
	return true
