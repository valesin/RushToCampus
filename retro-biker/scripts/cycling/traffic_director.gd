extends Node
const Actor = preload("res://scripts/cycling/traffic_actor.gd")
const Definition = preload("res://scripts/cycling/traffic_definition.gd")
@export var seed_value: int = 20260905
@export var maximum_actors: int = 24
@export var spawn_distance: float = 66.0
@export var safe_start_seconds: float = 5.0
@export var initial_interval: float = 5.0
@export var final_interval: float = 2.8
var actors: Array = []
var pool: Array = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var next_spawn: float = 5.0
var accepted: int = 0
var rejected: int = 0
var enabled: bool = true
## Authored combinations: actor kind, lane, longitudinal offset in metres.
const PATTERNS: Array = [
	[["cyclist", 3, 0.0]],
	[["car", 2, 0.0], ["pedestrian", 4, 8.0]],
	[["bus", 0, 0.0], ["car", 1, 15.0]],
	[["barrier", 3, 0.0], ["car", 1, 12.0]],
	[["barrier", 4, 0.0], ["cyclist", 3, 6.0]],
	[["car", 2, 0.0], ["barrier", 0, 15.0]],
	[["pedestrian", 4, 0.0], ["barrier", 2, 13.0]]
]

func reset() -> void:
	for actor in actors:
		if is_instance_valid(actor.visual):
			actor.visual.queue_free()
		actor.visual = null
		pool.append(actor)
	actors.clear()
	rng.seed = seed_value
	next_spawn = safe_start_seconds
	accepted = 0
	rejected = 0

func make_actor(kind: String, lane_id: int, at_distance: float):
	var spec = Definition.new()
	spec.kind = kind
	spec.lane = lane_id
	match kind:
		"bus":
			spec.speed = -10.0
			spec.contact_size = Vector2(9.0, 0.40)
		"car":
			spec.speed = -12.0
			spec.contact_size = Vector2(4.0, 0.36)
		"cyclist":
			spec.speed = 4.8
			spec.contact_size = Vector2(1.5, 0.30)
		"pedestrian":
			spec.speed = -1.4
			spec.contact_size = Vector2(0.7, 0.28)
		_:
			spec.speed = 0.0
			spec.contact_size = Vector2(2.0, 0.36)
	var actor = pool.pop_back() if not pool.is_empty() else Actor.new()
	actor.configure(spec, at_distance)
	return actor

func step(delta: float, elapsed: float, rider_distance: float, rider_lane: int, rider_size: Vector2) -> void:
	for actor in actors:
		actor.step(delta)
	for i in range(actors.size() - 1, -1, -1):
		if (actors[i].distance - rider_distance < -30.0 and actors[i].previous_distance - rider_distance < -30.0) or (actors[i].distance - rider_distance > 160.0 and actors[i].previous_distance - rider_distance > 160.0):
			var old = actors.pop_at(i)
			if is_instance_valid(old.visual):
				old.visual.queue_free()
			old.visual = null
			pool.append(old)
	if not enabled or elapsed < next_spawn:
		return
	next_spawn = elapsed + lerpf(initial_interval, final_interval, clampf(elapsed / 120.0, 0.0, 1.0))
	var pattern: Array = PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
	if actors.size() + pattern.size() > maximum_actors:
		return
	var candidate: Array = []
	for item in pattern:
		candidate.append(make_actor(item[0], item[1], rider_distance + spawn_distance + float(item[2])))
	var combined: Array = actors + candidate
	# Conservative checks at exhausted/headwind, calm, and full/tailwind speeds.
	# Runtime movement is continuous; graph edges use the same swept hit test.
	var safe: bool = true
	for speed_value in [1.8, 3.6, 8.0, 9.6]:
		if not has_route(combined, rider_distance, rider_lane, speed_value, rider_size):
			safe = false
			break
	if safe:
		actors.append_array(candidate)
		accepted += 1
	else:
		pool.append_array(candidate)
		rejected += 1

func has_route(candidates: Array, rider_distance: float, rider_lane: int, speed_value: float, rider_size: Vector2) -> bool:
	var reachable: Array[int] = [rider_lane]
	var dt: float = 0.20 # slightly slower than actual lane transition: safety margin
	for tick in range(90):
		var t0: float = tick * dt
		var t1: float = t0 + dt
		var following: Array[int] = []
		for lane_from in reachable:
			for lane_to in range(maxi(0, lane_from - 1), mini(4, lane_from + 1) + 1):
				var safe: bool = true
				for actor in candidates:
					var start := Vector2(actor.distance - rider_distance + (actor.definition.speed - speed_value) * t0, actor.definition.lane - lane_from)
					var end := Vector2(actor.distance - rider_distance + (actor.definition.speed - speed_value) * t1, actor.definition.lane - lane_to)
					var half: Vector2 = (actor.definition.contact_size + rider_size) * 0.5
					# Extra margin covers smooth lane interpolation and human timing.
					half += Vector2(1.0, 0.15)
					if Actor.swept_contact(start, end, half):
						safe = false
						break
				if safe and not following.has(lane_to):
					following.append(lane_to)
		if following.is_empty():
			return false
		reachable = following
	return true

func find_leader(rider_distance: float, lane_position: float, transitioning: bool):
	if transitioning or absf(lane_position - 3.0) > 0.01:
		return null
	var nearest = null
	var gap_best: float = 7.0
	for actor in actors:
		var gap: float = actor.distance - rider_distance
		if actor.definition.kind == "cyclist" and actor.definition.lane == 3 and gap >= 2.0 and gap <= 6.0 and gap < gap_best:
			gap_best = gap
			nearest = actor
	return nearest
