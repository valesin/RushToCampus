extends Node
const Actor = preload("res://scripts/cycling/traffic_actor.gd")
const Definition = preload("res://scripts/cycling/traffic_definition.gd")
const Layout = preload("res://scripts/cycling/presentation_layout.gd")
## Fastest closing traffic (car); with boost speed it bounds the approach rate.
const MAX_ONCOMING_SPEED: float = 12.0
@export var seed_value: int = 20260905
@export var maximum_actors: int = 24
@export var spawn_distance: float = 118.0
## Seconds an actor is simulated offscreen before its art can enter the frame.
@export var spawn_lead_seconds: float = 1.5
@export var safe_start_seconds: float = 5.0
@export var initial_interval: float = 5.0
@export var final_interval: float = 2.2
## A rejected pattern retries shortly instead of forfeiting its whole slot,
## which would otherwise swallow the density ramp.
@export var retry_seconds: float = 1.0
## Extra clearance folded into every route check. Shrinks with route progress,
## so identical traffic demands better timing near university. The route
## guarantee itself never relaxes; only the comfort inside it does.
const MARGIN_START := Vector2(1.0, 0.15)
const MARGIN_END := Vector2(0.5, 0.075)
var contact_margin: Vector2 = MARGIN_START
var food
const CHECK_SPEEDS: Array[float] = [3.6, 7.2, 7.8, 10.8, 14.4, 15.84, 21.6]
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
	contact_margin = MARGIN_START
	accepted = 0
	rejected = 0

## Spawn gap that keeps every actor offscreen for spawn_lead_seconds even when
## the rider boosts into oncoming traffic. Guards the projection against a
## pixels_per_metre change silently pulling spawns back into the frame.
func minimum_spawn_distance(pixels_per_metre: float, top_rider_speed: float) -> float:
	return Layout.art_horizon(pixels_per_metre)+(top_rider_speed+MAX_ONCOMING_SPEED)*spawn_lead_seconds

func make_actor(kind: String, lane_id: int, at_distance: float):
	var spec = Definition.new()
	spec.kind = kind
	spec.lane = lane_id
	match kind:
		"bus":
			spec.speed = -10.0
			spec.contact_size = Vector2(13.0, 0.40)
		"car":
			spec.speed = -12.0
			spec.contact_size = Vector2(8.0, 0.36)
		"cyclist":
			spec.speed = 7.8
			spec.contact_size = Vector2(5.0, 0.30)
		"pedestrian":
			spec.speed = -1.4
			spec.contact_size = Vector2(2.0, 0.28)
		_:
			spec.speed = 0.0
			spec.contact_size = Vector2(4.0, 0.36)
	var actor = pool.pop_back() if not pool.is_empty() else Actor.new()
	actor.configure(spec, at_distance)
	return actor

## progress is the fraction of the route covered, not elapsed time, so a
## boosting rider cannot outrun their own difficulty curve.
func step(delta: float, elapsed: float, rider_distance: float, rider_lane: int, rider_size: Vector2, progress: float = 0.0) -> void:
	var ramp: float = clampf(progress, 0.0, 1.0)
	# Set before any route check this frame, including the pickup corridors
	# food_director validates through has_route.
	contact_margin = MARGIN_START.lerp(MARGIN_END, ramp)
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
	next_spawn = elapsed + lerpf(initial_interval, final_interval, ramp)
	var pattern: Array = PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
	if actors.size() + pattern.size() > maximum_actors:
		next_spawn = elapsed + retry_seconds
		return
	var candidate: Array = []
	for item in pattern:
		var gap: float = spawn_distance + float(item[2])
		var actor = make_actor(item[0], item[1], rider_distance + gap)
		actor.spawn_gap = gap
		candidate.append(actor)
	var combined: Array = actors + candidate
	# Conservative checks at exhausted/headwind, calm, and full/tailwind speeds.
	# Runtime movement is continuous; graph edges use the same swept hit test.
	var safe: bool = true
	for speed_value in CHECK_SPEEDS:
		if not has_route(combined, rider_distance, rider_lane, speed_value, rider_size):
			safe = false
			break
	if safe and food != null:
		safe = food.traffic_clear(candidate, rider_distance)
		for item in food.items:
			if item.distance <= rider_distance: continue
			for speed_value in CHECK_SPEEDS:
				if not has_route(combined, rider_distance, rider_lane, speed_value, rider_size, item.distance, item.lane):
					safe = false
					break
	if safe:
		actors.append_array(candidate)
		accepted += 1
	else:
		pool.append_array(candidate)
		rejected += 1
		next_spawn = elapsed + retry_seconds

func has_route(candidates: Array, rider_distance: float, rider_lane: int, speed_value: float, rider_size: Vector2, pickup_distance: float = -1.0, pickup_lane: int = -1) -> bool:
	var reachable: Array[int] = [rider_lane]
	var dt: float = 0.20 # slightly slower than actual lane transition: safety margin
	var pickup_time: float = (pickup_distance - rider_distance) / speed_value
	for tick in range(maxi(90, int(ceil(pickup_time / dt)) + 10)):
		var t0: float = tick * dt
		var t1: float = t0 + dt
		var following: Array[int] = []
		for lane_from in reachable:
			for lane_to in range(maxi(0, lane_from - 1), mini(4, lane_from + 1) + 1):
				if pickup_lane >= 0 and t0 <= pickup_time and t1 > pickup_time and (lane_from != pickup_lane or lane_to != pickup_lane): continue
				var safe: bool = true
				for actor in candidates:
					var start := Vector2(actor.distance - rider_distance + (actor.definition.speed - speed_value) * t0, actor.definition.lane - lane_from)
					var end := Vector2(actor.distance - rider_distance + (actor.definition.speed - speed_value) * t1, actor.definition.lane - lane_to)
					var half: Vector2 = (actor.definition.contact_size + rider_size) * 0.5
					# Extra margin covers smooth lane interpolation and human timing.
					half += contact_margin
					if Actor.swept_contact(start, end, half):
						safe = false
						break
				if safe and not following.has(lane_to):
					following.append(lane_to)
		if pickup_lane >= 0:
			if t0 <= pickup_time and t1 > pickup_time:
				# Require a settled lane on both sides of the pickup crossing.
				if not reachable.has(pickup_lane) or not following.has(pickup_lane): return false
				following.assign([pickup_lane])
		if following.is_empty():
			return false
		reachable = following
	return true

func find_leader(rider_distance: float, lane_position: float, transitioning: bool, rider_width: float = 5.0):
	if transitioning or absf(lane_position - 3.0) > 0.01:
		return null
	var nearest = null
	var gap_best: float = 7.0
	for actor in actors:
		var gap: float = actor.distance - rider_distance - (actor.definition.contact_size.x + rider_width) * 0.5
		if actor.definition.kind == "cyclist" and actor.definition.lane == 3 and gap >= 2.0 and gap <= 6.0 and gap < gap_best:
			gap_best = gap
			nearest = actor
	return nearest
