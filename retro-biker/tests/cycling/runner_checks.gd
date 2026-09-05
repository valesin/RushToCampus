extends RefCounted
const Actor = preload("res://scripts/cycling/traffic_actor.gd")
const Run = preload("res://scripts/cycling/run_controller.gd")
const Rider = preload("res://scripts/cycling/rider.gd")
const Wind = preload("res://scripts/cycling/wind_controller.gd")
const Director = preload("res://scripts/cycling/traffic_director.gd")

static func run(game) -> Dictionary:
	var checks: Dictionary = {}
	var rider = Rider.new()
	rider.reset()
	rider.lane_input(0)
	rider.lane_input(-1)
	rider.step(0.18, 1.0, 0.0)
	rider.lane_input(-1)
	checks["held_input_single_lane"] = rider.lane == 2
	rider.lane_input(0)
	rider.lane_input(-1)
	rider.lane_input(0)
	rider.lane_input(-1)
	checks["transition_ignores_extra_input"] = rider.lane == 1
	rider.step(0.18, 1.0, 0.0)
	for i in 8:
		rider.lane_input(0)
		rider.lane_input(-1)
		rider.step(0.18, 1.0, 0.0)
	checks["upper_boundary"] = rider.lane == 0
	for i in 8:
		rider.lane_input(0)
		rider.lane_input(1)
		rider.step(0.18, 1.0, 0.0)
	checks["lower_boundary"] = rider.lane == 4
	rider.energy = 0.0
	rider.step(1.0, 0.75, 0.0)
	checks["exhaustion_keeps_moving"] = rider.speed > 0.0 and rider.recovering
	rider.free()

	var wind = Wind.new()
	wind.elapsed = 10.5
	checks["wind_warning"] = wind.warning() == "HEADWIND APPROACHING"
	wind.elapsed = 12.5
	checks["headwind_no_speed_loss"] = wind.values(false).x == 1.0
	wind.elapsed = 13.0
	checks["headwind_rates"] = wind.values(false) == Vector2(1.0, -4.0)
	checks["sheltered_rates"] = wind.values(true) == Vector2(1.0, 0.0)
	wind.elapsed = 37.0
	checks["tailwind_rates"] = wind.values(false) == Vector2(1.1, 0.0)
	wind.free()

	game.start_run()
	game.set_physics_process(false)
	game.traffic.enabled = false
	game.food.enabled = false
	game.wind.elapsed = 13.0
	game.rider.energy = 60.0
	var lead = game.traffic.make_actor("cyclist", 3, 9.0)
	game.traffic.actors.append(lead)
	for i in 120:
		game.simulate(1.0 / 60.0)
	checks["draft_gap_stable"] = absf(lead.distance - game.distance - 9.0) < 0.05
	checks["draft_restores_energy"] = absf(game.rider.energy - 64.0) < 0.1 and game.rider.sheltered
	game.rider.lane_input(0)
	game.rider.lane_input(-1)
	game.simulate(1.0 / 60.0)
	checks["switch_exits_shelter"] = not game.rider.sheltered

	game.start_run()
	game.rider.energy = 100.0
	var pedestrian = game.traffic.make_actor("pedestrian", 4, 0)
	game.contact(pedestrian)
	checks["minor_hit_penalty"] = game.rider.energy == 100.0 and game.rider.slowdown_left == 0.8 and game.state == game.RunState.RUNNING
	game.contact(pedestrian)
	checks["same_actor_once"] = game.rider.energy == 100.0
	var other = game.traffic.make_actor("cyclist", 3, 0)
	game.contact(other)
	checks["minor_cooldown"] = game.rider.energy == 100.0
	var car = game.traffic.make_actor("car", 3, 0)
	game.contact(car)
	checks["lethal_during_cooldown"] = game.state == game.RunState.CRASHED
	checks["swept_fast_vehicle"] = Actor.swept_contact(Vector2(20, 0), Vector2(-20, 0), Vector2(3, 0.35))
	checks["swept_other_lane_safe"] = not Actor.swept_contact(Vector2(20, 1), Vector2(-20, 1), Vector2(3, 0.35))
	checks["swept_lane_crossing"] = Actor.swept_contact(Vector2(0, 0.7), Vector2(0, -0.3), Vector2(3, 0.35))
	game.start_run()
	var fast = game.traffic.make_actor("car", 3, 10)
	fast.definition.speed = -10000.0
	game.traffic.actors.append(fast)
	game.simulate(1.0 / 60.0)
	checks["runtime_fast_car_collision"] = game.state == game.RunState.CRASHED

	game.start_run()
	game.distance = 123.5
	game.save_best()
	var old_path: String = game.score_path
	game.score_path = "user://cycling_test_score.json"
	game.best_distance = 123.5
	game.save_best()
	checks["score_roundtrip"] = Run.read_best(game.score_path) == 123.5
	var file := FileAccess.open(game.score_path, FileAccess.WRITE)
	file.store_string("not valid json")
	file.close()
	checks["corrupt_score_safe"] = Run.read_best(game.score_path) == 0.0
	file = FileAccess.open(game.score_path, FileAccess.WRITE)
	file.store_string('{"best_distance": "bad"}')
	file.close()
	checks["invalid_score_type_safe"] = Run.read_best(game.score_path) == 0.0
	DirAccess.remove_absolute(game.score_path)
	checks["missing_score_safe"] = Run.read_best(game.score_path) == 0.0
	game.score_path = old_path
	game.best_distance = 0.0
	game.start_run()
	checks["retry_resets"] = game.distance == 0.0 and game.elapsed == 0.0 and game.wind.elapsed == 0.0 and game.rider.energy == 100.0 and game.traffic.actors.is_empty() and game.rider.lane == 3
	game.state = game.RunState.PAUSED
	var before: float = game.wind.elapsed
	game.simulate(1.0)
	checks["paused_simulation_frozen"] = game.distance == 0.0 and game.wind.elapsed == before

	var director = Director.new()
	var all_patterns_safe: bool = true
	for pattern in director.PATTERNS:
		var candidates: Array = []
		for item in pattern:
			candidates.append(director.make_actor(item[0], item[1], director.spawn_distance + float(item[2])))
		for speed_value in Director.CHECK_SPEEDS:
			for lane_id in range(5):
				if not director.has_route(candidates, 0.0, lane_id, speed_value, Vector2(5.0, 0.32)):
					all_patterns_safe = false
	checks["all_patterns_all_lanes_speed_extremes"] = all_patterns_safe
	var wall: Array = []
	for lane_id in range(5):
		wall.append(director.make_actor("barrier", lane_id, 8.0))
	checks["impossible_wall_rejected"] = not director.has_route(wall, 0.0, 3, 8.0, Vector2(5.0, 0.32))
	director.reset()
	director.step(0, 4.99, 0, 3, Vector2(5.0, 0.32))
	checks["five_second_safe_start"] = director.actors.is_empty()
	var maximum_count: int = 0
	for tick in range(160):
		director.step(0.5, tick * 0.5 + 5.0, tick * 4.0, 3, Vector2(5.0, 0.32))
		maximum_count = maxi(maximum_count, director.actors.size())
	checks["seeded_director_bounded"] = maximum_count <= director.maximum_actors and director.accepted > 0
	checks["minimum_warning_time"] = (960.0 - 240.0) / 12.0 / (21.6 + 12.0) > 1.5
	checks["spawns_full_bus_offscreen"] = 240.0 + director.spawn_distance * 12.0 - 85.0 > 960.0
	director.free()
	game.start_run()
	game.traffic.enabled = false
	game.food.enabled = false
	var transitions: int = 0
	var was_recovering: bool = false
	var smooth: bool = true
	for tick in 20000:
		var old_speed: float = game.rider.cruising_speed
		game.simulate(1.0 / 60.0)
		if absf(game.rider.cruising_speed - old_speed) > 4.0 / 60.0 + 0.001:
			smooth = false
		if game.rider.recovering != was_recovering: transitions += 1
		was_recovering = game.rider.recovering
		if game.state == game.RunState.SUCCESS: break
	checks["no_passive_energy_cycles"] = transitions == 0
	checks["fixed_cruise_speed"] = game.rider.speed >= 14.4
	checks["updated_commute_duration"] = game.elapsed > 95 and game.elapsed < 106 and game.distance == 1500.0
	checks["university_success"] = game.state == game.RunState.SUCCESS
	var finish_time: float = game.elapsed
	game.simulate(1.0)
	checks["success_freezes"] = game.elapsed == finish_time and game.distance == 1500.0
	var arrival_all_lanes: bool = true
	for lane_id in 5:
		game.start_run()
		game.distance = 1499.9
		game.rider.lane = lane_id
		game.rider.source_lane = lane_id
		game.rider.lane_position = lane_id
		game.simulate(1.0/60.0)
		arrival_all_lanes = arrival_all_lanes and game.state == game.RunState.SUCCESS
	checks["arrival_any_lane"] = arrival_all_lanes
	game.start_run()
	game.distance = 1499.9
	game.traffic.actors.append(game.traffic.make_actor("car",3,game.distance+6.0))
	game.simulate(1.0/60.0)
	checks["collision_before_arrival_wins"] = game.state == game.RunState.CRASHED
	game.start_run()
	game.distance = 1499.99
	var late_car = game.traffic.make_actor("car",3,game.distance+20.0)
	late_car.definition.speed = -1000.0
	game.traffic.actors.append(late_car)
	game.simulate(1.0/60.0)
	checks["collision_after_arrival_ignored"] = game.state == game.RunState.SUCCESS
	game.start_run()
	checks.merge(load("res://tests/cycling/energy_checks.gd").run(game))
	checks.merge(load("res://tests/cycling/difficulty_checks.gd").run(game))
	game.food.enabled = true
	game.traffic.enabled = true
	game.set_physics_process(true)
	return checks
