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
@export var route_length: float = 1500.0
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
## Slack on the route search's per-step actor filter, in metres. Comfortably
## above the float32 rounding inside swept_contact, far below a contact size.
const ROUTE_FILTER_EPSILON: float = 0.001
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

const ROAD_PATTERNS: Array = [
	[["bus",0,0.0],["car",1,18.0]],
	[["car",1,0.0],["car",2,22.0]],
	[["bus",0,0.0],["car",2,20.0]]
]

func route_progress(rider_distance: float) -> float:
	return clampf(rider_distance / maxf(1.0,route_length),0.0,1.0)

func spawn_interval(rider_distance: float) -> float:
	return lerpf(initial_interval,final_interval,route_progress(rider_distance))

func choose_pattern(rider_distance: float) -> Array:
	var road_weight: float = lerpf(0.15,0.80,route_progress(rider_distance))
	var choices: Array = ROAD_PATTERNS if rng.randf() < road_weight else PATTERNS
	return choices[rng.randi_range(0,choices.size()-1)]

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

func step(delta: float, elapsed: float, rider_distance: float, rider_lane: int, rider_size: Vector2) -> void:
	# Set before any route check this frame, including the pickup corridors
	# food_director validates through has_route. Shares route_progress with the
	# interval and pattern ramps so difficulty has one basis, not three.
	contact_margin = MARGIN_START.lerp(MARGIN_END, route_progress(rider_distance))
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
	next_spawn = elapsed + spawn_interval(rider_distance)
	var pattern: Array = choose_pattern(rider_distance)
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
	# Per-actor values that the tick and lane loops cannot change, lifted out of
	# them. Reading them back through actor.definition once per lane pair per
	# tick, as this search used to, is most of what it spends its time on.
	var count: int = candidates.size()
	var offsets := PackedFloat64Array()
	var closing := PackedFloat64Array()
	var lanes := PackedFloat64Array()
	offsets.resize(count)
	closing.resize(count)
	lanes.resize(count)
	var halves: Array[Vector2] = []
	halves.resize(count)
	for i in count:
		var actor = candidates[i]
		var definition = actor.definition
		offsets[i] = actor.distance - rider_distance
		closing[i] = definition.speed - speed_value
		lanes[i] = definition.lane
		var half: Vector2 = (definition.contact_size + rider_size) * 0.5
		# Extra margin covers smooth lane interpolation and human timing.
		half += contact_margin
		halves[i] = half
	var near: Array[int] = []
	for tick in range(maxi(90, int(ceil(pickup_time / dt)) + 10)):
		var t0: float = tick * dt
		var t1: float = t0 + dt
		# swept_contact is a slab test, so an actor whose x span already misses
		# the rider's box across this step cannot contact it whichever lanes are
		# tried. The lane pair never moves that x span, so this runs once per
		# tick instead of once per lane pair, and the epsilon keeps it a superset
		# of the exact test it stands in for.
		near.clear()
		for i in count:
			var from_x: float = offsets[i] + closing[i] * t0
			var to_x: float = offsets[i] + closing[i] * t1
			var reach: float = halves[i].x + ROUTE_FILTER_EPSILON
			if minf(from_x, to_x) - reach <= 0.0 and maxf(from_x, to_x) + reach >= 0.0:
				near.append(i)
		var following: Array[int] = []
		for lane_from in reachable:
			for lane_to in range(maxi(0, lane_from - 1), mini(4, lane_from + 1) + 1):
				if pickup_lane >= 0 and t0 <= pickup_time and t1 > pickup_time and (lane_from != pickup_lane or lane_to != pickup_lane): continue
				var safe: bool = true
				for i in near:
					var start := Vector2(offsets[i] + closing[i] * t0, lanes[i] - lane_from)
					var end := Vector2(offsets[i] + closing[i] * t1, lanes[i] - lane_to)
					if Actor.swept_contact(start, end, halves[i]):
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
