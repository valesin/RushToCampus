extends RefCounted
const Rider = preload("res://scripts/cycling/rider.gd")
const Wind = preload("res://scripts/cycling/wind_controller.gd")
static func run(game) -> Dictionary:
	var c: Dictionary = {}
	var r = Rider.new()
	r.reset()
	r.step(10.0,1.0,0.0)
	c.cruise_no_energy_change = r.speed == 14.4 and r.energy == 100.0
	r.energy = 19.99
	c.boost_threshold = not r.boost_input(true) and r.energy == 19.99
	r.boost_input(false)
	r.energy = 20.0
	c.boost_spends_immediately = r.boost_input(true) and r.energy == 0.0
	c.boost_no_stacking = not r.boost_input(true)
	var full_boost: bool = true
	for i in 120:
		r.step(1.0/60.0,1.1,-4.0,7.8)
		full_boost = full_boost and is_equal_approx(r.speed,21.6) and not r.recovering
	c.last_energy_full_two_seconds = full_boost and r.boost_left == 0.0
	r.step(1.0/60.0,1.0,-4.0)
	c.recovery_starts_after_boost = r.recovering and r.speed == 7.2
	r.boost_input(false)
	c.recovery_cannot_boost = not r.boost_input(true)
	r.add_food(20.0)
	for i in 118: r.step(1.0/60.0,1.0,-4.0)
	c.food_does_not_shorten_recovery = r.recovering and r.energy > 44.0
	r.step(1.0/60.0,1.0,-4.0)
	c.recovery_restores_exact_25_ignores_wind = not r.recovering and is_equal_approx(r.energy,45.0)
	r.step(1.0/60.0,1.0,0.0)
	c.recovery_returns_to_cruise = r.speed == 14.4
	r.reset()
	r.energy = 20.0
	r.boost_input(true)
	r.step(1.0,1.0,0.0)
	r.add_food(20.0)
	r.step(1.0,1.0,0.0)
	r.step(0.01,1.0,0.0)
	c.food_averts_recovery = not r.recovering and r.energy == 20.0
	c.held_boost_does_not_repeat = not r.boost_input(true)
	r.boost_input(false)
	c.no_boost_cooldown = r.boost_input(true)
	r.minor_hit()
	r.step(0.1,1.0,0.0)
	c.boost_collision_slowdown_no_energy_cost = r.speed == 10.8 and r.energy == 0.0
	r.add_food(200.0)
	c.food_cap = r.energy == 100.0
	r.reset()
	r.step(1.0,1.1,0.0)
	c.tailwind_cruise_only = is_equal_approx(r.speed,15.84) and r.energy == 100.0
	r.boost_input(true)
	r.step(0.1,1.1,0.0)
	c.tailwind_boost_exact = r.speed == 21.6
	r.free()
	var w = Wind.new()
	w.elapsed = 11.99
	c.warning_two_seconds = w.warning() == "HEADWIND APPROACHING"
	w.elapsed = 12.0
	c.headwind_starts_at_12 = w.phase() == "HEADWIND"
	w.elapsed = 19.999
	c.headwind_full_eight = w.phase() == "HEADWIND"
	w.elapsed = 20.0
	c.headwind_ends_at_20 = w.phase() == "CALM"
	w.free()
	game.start_run()
	game.food.enabled = false
	game.traffic.enabled = false
	game.rider.boost_input(true)
	game.simulate(0.25)
	game.state = game.RunState.PAUSED
	var timer: float = game.rider.boost_left
	var energy: float = game.rider.energy
	game.simulate(1.0)
	c.pause_freezes_boost_energy = game.rider.boost_left == timer and game.rider.energy == energy
	game.start_run()
	c.restart_clears_timers_food = game.rider.boost_left == 0.0 and game.rider.recovery_left == 0.0 and game.food.items.is_empty()
	game.food.items.append({"kind":"bread","lane":3,"distance":0.2,"amount":20.0,"low_lane":3,"high_lane":3})
	game.rider.energy = 20.0
	game.rider.boost_input(true)
	game.simulate(1.0/60.0)
	c.runtime_swept_bread = game.rider.energy == 20.0 and game.food.items.is_empty() and game.food.feedback == "RUGBRØD +20"
	game.food.items.append({"kind":"pastry","lane":3,"distance":game.distance+0.2,"amount":30.0,"low_lane":3,"high_lane":3})
	game.simulate(1.0/60.0)
	c.runtime_pastry = game.rider.energy == 50.0
	game.start_run()
	game.traffic.actors.append(game.traffic.make_actor("cyclist",3,9.0))
	game.rider.boost_input(true)
	for i in 30: game.simulate(1.0/60.0)
	c.boost_no_collision_immunity = game.rider.slowdown_left > 0.0 and game.rider.energy == 80.0
	game.start_run()
	game.traffic.actors.append(game.traffic.make_actor("cyclist",3,9.0))
	game.rider.lane_input(0)
	game.rider.lane_input(-1)
	game.rider.boost_input(true)
	for i in 90: game.simulate(1.0/60.0)
	c.clear_lane_overtakes = game.distance > game.traffic.actors[0].distance and game.rider.slowdown_left == 0.0
	game.start_run()
	c.bread_schedule = game.food.next_bread >= 6.0 and game.food.next_bread <= 8.0
	c.pastry_schedule = game.food.next_pastry >= 18.0 and game.food.next_pastry <= 24.0
	c.safe_bread_spawn = game.food.spawn_food("bread",game)
	var hazard = game.traffic.make_actor("car",3,90.0)
	c.future_hazard_rejected = not game.food.traffic_clear([hazard],0.0)
	game.start_run()
	game.traffic.actors.append(game.traffic.make_actor("barrier",3,48.0))
	game.traffic.actors.append(game.traffic.make_actor("barrier",4,48.0))
	for lane_id in [3,4]:
		for at in [24.0,32.0,64.0,80.0,96.0]: game.traffic.actors.append(game.traffic.make_actor("barrier",lane_id,at))
	c.unsafe_pickup_rejected = not game.food.spawn_food("bread",game)
	game.start_run()
	game.rider.energy = 0.0
	game.rider.boost_left = 1.0/60.0
	game.food.items.append({"kind":"bread","lane":3,"distance":0.2,"amount":20.0})
	game.simulate(1.0/60.0)
	game.simulate(1.0/60.0)
	c.final_boost_frame_food_averts_recovery = not game.rider.recovering and game.rider.energy == 20.0
	game.start_run()
	game.rider.energy = 0.0
	game.simulate(0.5)
	var recovery_timer: float = game.rider.recovery_left
	var recovery_energy: float = game.rider.energy
	game.state = game.RunState.PAUSED
	game.simulate(2.0)
	c.pause_freezes_recovery = game.rider.recovery_left == recovery_timer and game.rider.energy == recovery_energy
	game.start_run()
	game.rider.energy = 1.0
	game.wind.elapsed = 13.0
	game.simulate(0.25)
	game.simulate(0.25)
	c.headwind_zero_enters_recovery = game.rider.recovering and game.rider.speed == 7.2
	var wind_rider = Rider.new()
	wind_rider.reset()
	for i in 480: wind_rider.step(1.0/60.0,1.0,-4.0)
	c.headwind_eight_seconds_costs_32 = is_equal_approx(wind_rider.energy,68.0)
	wind_rider.free()
	return c
