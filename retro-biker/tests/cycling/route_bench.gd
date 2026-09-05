extends SceneTree
## Equivalence + timing harness for traffic_director.has_route.
##
## Holds a verbatim copy of the pre-optimisation algorithm as the reference, so
## the optimised implementation can be proven to answer identically on every
## scenario before its speedup is believed. Excluded from exports (tests/*).
##
## Run: <engine> --headless --disable-crash-handler --path <project> -s res://tests/cycling/route_bench.gd

const Director = preload("res://scripts/cycling/traffic_director.gd")
const Actor = preload("res://scripts/cycling/traffic_actor.gd")

const KINDS: Array[String] = ["bus", "car", "cyclist", "pedestrian", "barrier"]

## Verbatim pre-optimisation has_route. Do not "clean up" — its value is being
## an untouched reference.
func reference_has_route(director, candidates: Array, rider_distance: float, rider_lane: int, speed_value: float, rider_size: Vector2, pickup_distance: float = -1.0, pickup_lane: int = -1) -> bool:
	var reachable: Array[int] = [rider_lane]
	var dt: float = 0.20
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
					half += director.contact_margin
					if Actor.swept_contact(start, end, half):
						safe = false
						break
				if safe and not following.has(lane_to):
					following.append(lane_to)
		if pickup_lane >= 0:
			if t0 <= pickup_time and t1 > pickup_time:
				if not reachable.has(pickup_lane) or not following.has(pickup_lane): return false
				following.assign([pickup_lane])
		if following.is_empty():
			return false
		reachable = following
	return true

func _initialize() -> void:
	var director = Director.new()
	var rng := RandomNumberGenerator.new()
	var rider_size := Vector2(5.0, 0.32)

	var scenarios: Array = []
	# Spread of actor counts: the logged board hitch was 4-5 actors, but the
	# director allows up to maximum_actors, which is where it gets worst.
	for actor_count in [2, 5, 10, 18, 24]:
		for variant in 8:
			rng.seed = hash([actor_count, variant])
			var candidates: Array = []
			for i in actor_count:
				candidates.append(director.make_actor(
					KINDS[rng.randi_range(0, KINDS.size() - 1)],
					rng.randi_range(0, 4),
					rng.randf_range(20.0, 160.0)))
			# Exercise the pickup branch on half the variants.
			var pickup_distance: float = -1.0
			var pickup_lane: int = -1
			if variant % 2 == 1:
				pickup_distance = rng.randf_range(40.0, 140.0)
				pickup_lane = rng.randi_range(0, 4)
			scenarios.append({
				"candidates": candidates,
				"rider_lane": rng.randi_range(0, 4),
				"pickup_distance": pickup_distance,
				"pickup_lane": pickup_lane,
				"actor_count": actor_count,
			})

	var mismatches: int = 0
	var reference_us: int = 0
	var optimised_us: int = 0
	var checked: int = 0
	var worst_reference_us: int = 0
	var worst_optimised_us: int = 0

	for scenario in scenarios:
		for speed_value in director.CHECK_SPEEDS:
			var t0: int = Time.get_ticks_usec()
			var expected: bool = reference_has_route(director, scenario.candidates, 0.0,
				scenario.rider_lane, speed_value, rider_size,
				scenario.pickup_distance, scenario.pickup_lane)
			var t1: int = Time.get_ticks_usec()
			var actual: bool = director.has_route(scenario.candidates, 0.0,
				scenario.rider_lane, speed_value, rider_size,
				scenario.pickup_distance, scenario.pickup_lane)
			var t2: int = Time.get_ticks_usec()
			reference_us += t1 - t0
			optimised_us += t2 - t1
			worst_reference_us = maxi(worst_reference_us, t1 - t0)
			worst_optimised_us = maxi(worst_optimised_us, t2 - t1)
			checked += 1
			if expected != actual:
				mismatches += 1
				print("MISMATCH actors=%d rider_lane=%d speed=%.2f pickup=%.1f/%d expected=%s actual=%s" % [
					scenario.actor_count, scenario.rider_lane, speed_value,
					scenario.pickup_distance, scenario.pickup_lane, expected, actual])

	# One realistic full spawn evaluation: 7 speeds + 7 per food item, which is
	# what actually lands inside a single physics tick on the board.
	var full: Array = []
	rng.seed = 4242
	for i in 5:
		full.append(director.make_actor(KINDS[rng.randi_range(0, KINDS.size() - 1)], rng.randi_range(0, 4), rng.randf_range(20.0, 160.0)))
	var spawn_reference_us: int = 0
	var spawn_optimised_us: int = 0
	for pass_index in 2:
		var t0: int = Time.get_ticks_usec()
		for speed_value in director.CHECK_SPEEDS:
			reference_has_route(director, full, 0.0, 3, speed_value, rider_size)
		for speed_value in director.CHECK_SPEEDS:
			reference_has_route(director, full, 0.0, 3, speed_value, rider_size, 90.0, 2)
		var t1: int = Time.get_ticks_usec()
		for speed_value in director.CHECK_SPEEDS:
			director.has_route(full, 0.0, 3, speed_value, rider_size)
		for speed_value in director.CHECK_SPEEDS:
			director.has_route(full, 0.0, 3, speed_value, rider_size, 90.0, 2)
		var t2: int = Time.get_ticks_usec()
		spawn_reference_us = t1 - t0
		spawn_optimised_us = t2 - t1

	print("ROUTE_BENCH checked=%d mismatches=%d" % [checked, mismatches])
	print("ROUTE_BENCH total   reference=%.1fms optimised=%.1fms speedup=%.1fx" % [
		reference_us / 1000.0, optimised_us / 1000.0,
		float(reference_us) / maxf(1.0, float(optimised_us))])
	print("ROUTE_BENCH worst   reference=%.1fms optimised=%.1fms" % [
		worst_reference_us / 1000.0, worst_optimised_us / 1000.0])
	print("ROUTE_BENCH spawn   reference=%.1fms optimised=%.1fms speedup=%.1fx" % [
		spawn_reference_us / 1000.0, spawn_optimised_us / 1000.0,
		float(spawn_reference_us) / maxf(1.0, float(spawn_optimised_us))])
	print("ROUTE_BENCH RESULT=%s" % ("PASS" if mismatches == 0 else "FAIL"))
	director.free()
	quit()
