extends RefCounted
static func run(game) -> Dictionary:
	var checks: Dictionary = {}
	var rider = load("res://scripts/cycling/rider.gd").new()
	rider.reset()
	rider.energy = 99
	rider.sheltered = true
	rider.step(2,1,-4,7.8)
	checks.draft_caps_at_100 = rider.energy == 100
	rider.energy = 50
	rider.sheltered = false
	rider.step(1,1,0)
	checks.no_draft_no_regeneration = rider.energy == 50
	rider.boost_input(false)
	rider.boost_input(true)
	rider.sheltered = true
	rider.step(1,1,-4,7.8)
	checks.draft_does_not_refund_boost = rider.energy == 30
	rider.free()
	var director = load("res://scripts/cycling/traffic_director.gd").new()
	checks.progressive_spawn_interval = director.spawn_interval(0) > director.spawn_interval(750) and director.spawn_interval(750) > director.spawn_interval(1500)
	checks.difficulty_clamped = director.spawn_interval(-1) == 5.0 and is_equal_approx(director.spawn_interval(2000),2.2)
	var vehicle_counts: Array[int] = []
	for distance in [0,750,1500]:
		director.rng.seed = 17
		var count: int = 0
		for i in 500:
			for item in director.choose_pattern(distance):
				if item[0] in ["car","bus"]: count += 1
		vehicle_counts.append(count)
	checks.more_motor_vehicles_near_finish = vehicle_counts[0] < vehicle_counts[1] and vehicle_counts[1] < vehicle_counts[2]
	var routes_safe: bool = true
	for pattern in director.ROAD_PATTERNS:
		var candidates: Array = []
		for item in pattern: candidates.append(director.make_actor(item[0],item[1],78.0+item[2]))
		for lane in 5:
			for speed in director.CHECK_SPEEDS:
				routes_safe = routes_safe and director.has_route(candidates,0,lane,speed,Vector2(5,0.32))
		candidates.clear()
	checks.new_road_patterns_have_escape_routes = routes_safe
	director.free()
	return checks
