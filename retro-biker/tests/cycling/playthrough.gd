extends SceneTree
var checks: Dictionary = {}
var game
func _initialize() -> void:
	call_deferred("play")
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func frames(count: int) -> void:
	for i in count: await physics_frame
func play() -> void:
	game = load("res://scenes/cycling/CyclingGame.tscn").instantiate()
	game.score_path = "user://playthrough.json"
	root.add_child(game)
	await frames(3)
	key(KEY_ENTER,true)
	await frames(3)
	key(KEY_ENTER,false)
	game.traffic.enabled = false
	game.food.enabled = false
	checks.keyboard_start = game.state == game.RunState.RUNNING
	key(KEY_K,true)
	await frames(30)
	checks.keyboard_boost = game.rider.boost_left > 1.3 and game.rider.speed == 21.6 and game.rider.energy == 80.0
	key(KEY_ESCAPE,true)
	await frames(1)
	key(KEY_ESCAPE,false)
	var before: float = game.rider.boost_left
	await frames(20)
	checks.keyboard_pause = game.rider.boost_left == before and game.state == game.RunState.PAUSED
	key(KEY_ENTER,true)
	await frames(3)
	key(KEY_ENTER,false)
	await frames(125)
	checks.held_key_no_repeat = game.rider.energy == 80.0 and game.rider.boost_left == 0.0
	key(KEY_K,false)
	key(KEY_UP,true)
	await frames(15)
	key(KEY_UP,false)
	checks.keyboard_lane = game.rider.lane == 2 and game.rider.lane_position == 2.0
	# Real physics frames: spend remaining energy repeatedly, then recover.
	for i in 4:
		key(KEY_K,true)
		await frames(121)
		key(KEY_K,false)
		await frames(1)
	checks.repeated_exhaustion = game.rider.recovering and game.rider.speed == 7.2
	await frames(122)
	checks.recovery_walkthrough = not game.rider.recovering and game.rider.energy >= 23.0
	game.set_physics_process(false)
	# Deterministic full-route comparison using the same runtime simulation.
	var runs: Dictionary = {}
	for mode in ["cruise", "exhaustion", "food_assisted"]:
		game.start_run()
		game.traffic.enabled = false
		game.food.enabled = mode == "food_assisted"
		var recoveries: int = 0
		var boosts: int = 0
		var was_recovering: bool = false
		for tick in 12000:
			if mode != "cruise" and game.rider.boost_ready():
				game.rider.boost_input(false)
				if game.rider.boost_input(true): boosts += 1
			game.simulate(1.0/60.0)
			if game.rider.recovering and not was_recovering: recoveries += 1
			was_recovering = game.rider.recovering
			if game.state != game.RunState.RUNNING: break
		runs[mode] = {"seconds":game.elapsed,"boosts":boosts,"recoveries":recoveries,"energy":game.rider.energy,"finished":game.state == game.RunState.SUCCESS}
	checks.food_reduces_exhaustion = runs.food_assisted.recoveries < runs.exhaustion.recoveries
	# Measure actual spawn cadence and reservations with live seeded traffic.
	var traffic_runs: Array = []
	for seed_value in [20260905, 17, 99]:
		game.start_run()
		game.traffic.enabled = true
		game.food.enabled = true
		game.traffic.rng.seed = seed_value
		var bread_count: int = 0
		var pastry_count: int = 0
		var last_bread: float = -1.0
		var last_pastry: float = -1.0
		var bread_max_gap: float = 0.0
		var pastry_max_gap: float = 0.0
		# Feed the directors a moving rider; collision behaviour covered separately.
		for tick in 6000:
			game.elapsed = tick/60.0
			game.previous_distance = game.distance
			game.distance = tick*14.4/60.0
			game.traffic.step(1.0/60.0,game.elapsed,game.distance,3,game.rider.contact_size)
			var old_bread: float = game.food.next_bread
			var old_pastry: float = game.food.next_pastry
			game.food.step(1.0/60.0,game)
			if game.food.next_bread > old_bread + 1.0:
				bread_count += 1
				if last_bread >= 0.0: bread_max_gap = maxf(bread_max_gap,game.elapsed-last_bread)
				last_bread = game.elapsed
			if game.food.next_pastry > old_pastry + 1.0:
				pastry_count += 1
				if last_pastry >= 0.0: pastry_max_gap = maxf(pastry_max_gap,game.elapsed-last_pastry)
				last_pastry = game.elapsed
		traffic_runs.append({"seed":seed_value,"bread":bread_count,"pastries":pastry_count,"max_bread_gap":bread_max_gap,"max_pastry_gap":pastry_max_gap,"deferred":game.food.deferred_opportunities,"traffic_accepted":game.traffic.accepted,"traffic_rejected":game.traffic.rejected})
	checks.seeded_pickup_cadence = true
	for run_data in traffic_runs:
		checks.seeded_pickup_cadence = checks.seeded_pickup_cadence and run_data.max_bread_gap <= 8.02 and run_data.max_pastry_gap <= 24.02 and run_data.bread > run_data.pastries
	var failures: Array = []
	for label in checks:
		if not checks[label]: failures.append(label)
	print(JSON.stringify({"checks":checks,"failures":failures,"balance":runs,"traffic":traffic_runs}))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
