extends SceneTree
var checks: Dictionary = {}
var manager
var capture_path: String = ""

func _initialize() -> void:
	call_deferred("run")

func frames(count: int = 5) -> void:
	for i in count:
		await process_frame
		await physics_frame

func tap(code: Key) -> void:
	for pressed: bool in [true,false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(3)

func capture(file_name: String) -> void:
	if capture_path.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_path + "/diagnostic-" + file_name + ".png")

func run() -> void:
	manager = root.get_node("GameManager")
	manager.cycling_score_path = "user://rush_test_best.json"
	DirAccess.remove_absolute(manager.cycling_score_path)
	if not OS.get_cmdline_user_args().is_empty(): capture_path = OS.get_cmdline_user_args()[0]
	change_scene_to_file("res://scenes/MainMenu.tscn")
	await frames()
	checks.fresh_colourful = manager.cycling_clean_theme
	checks.viewport = root.get_visible_rect().size == Vector2(960,540)
	await capture("start-colourful")
	await tap(KEY_S)
	await tap(KEY_J)
	checks.how_opens = current_scene.how_panel.visible
	await tap(KEY_L)
	checks.how_closes = not current_scene.how_panel.visible
	await tap(KEY_S)
	await tap(KEY_J)
	checks.start_theme_switch = not manager.cycling_clean_theme
	await capture("start-illustrated")
	await tap(KEY_S)
	await tap(KEY_J)
	checks.one_start = current_scene.name == "CyclingGame" and current_scene.state == current_scene.RunState.RUNNING
	var game = current_scene
	game.traffic.enabled = false
	game.food.enabled = false
	checks.theme_into_game = not game.presentation.clean_theme
	await tap(KEY_L)
	var paused_distance: float = game.distance
	await tap(KEY_S)
	await tap(KEY_J)
	checks.pause_theme_switch = game.presentation.clean_theme and manager.cycling_clean_theme
	checks.pause_freezes = game.distance == paused_distance
	await tap(KEY_L)
	game.rider.energy = 100.0
	game.food.items.clear()
	game.food.items.append({"kind":"bread","lane":game.rider.lane,"distance":game.distance,"amount":20.0})
	game.food.step(0.0,game)
	game.food.step(0.0,game)
	checks.food_full_energy_once = game.food.collected == 1 and game.rider.energy == 100.0
	# Stage arrival near the finish; this is a diagnostic, not a natural playthrough.
	game.distance = game.route_length - 0.01
	game.previous_distance = game.distance
	game.simulate(0.02)
	await frames()
	checks.win_screen = current_scene.name == "WinScreen"
	checks.result_stats = manager.cycling_last_result.food == 1 and manager.cycling_last_result.distance == 1500.0 and manager.cycling_last_result.elapsed > 0.0
	checks.first_record = manager.cycling_last_result.new_record
	checks.best_saved = manager.CyclingResults.read_best(manager.cycling_score_path) == 1500.0
	await capture("win-colourful")
	await tap(KEY_J)
	game = current_scene
	checks.retry_resets = game.food.collected == 0 and game.distance < 5.0 and game.navigate_results
	checks.retry_theme = game.presentation.clean_theme
	game.traffic.enabled = false
	game.food.enabled = false
	game.distance = game.route_length - 0.01
	game.previous_distance = game.distance
	game.simulate(0.02)
	await frames()
	checks.equal_not_record = not manager.cycling_last_result.new_record
	await tap(KEY_L)
	checks.return_menu = current_scene.name == "MainMenu"
	# Repeat both outcomes and scene teardown with the other theme.
	current_scene.switch_theme()
	await tap(KEY_J)
	game = current_scene
	game.traffic.enabled = false
	game.food.enabled = false
	game.distance = 420.0
	var actor = game.traffic.make_actor("car",1,420.0)
	game.contact(actor)
	actor = null
	checks.crash_delay = game.state == game.RunState.CRASHED
	await frames(45)
	checks.game_over = current_scene.name == "GameOver"
	checks.crash_stats = manager.cycling_last_result.distance == 420.0 and not manager.cycling_last_result.won and not manager.cycling_last_result.new_record
	checks.results_theme = not manager.cycling_clean_theme
	await capture("gameover-illustrated")
	var buses: int = AudioServer.bus_count
	for i in 3:
		await tap(KEY_J)
		game = current_scene
		game.state = game.RunState.RESULTS
		game.finish_result(false)
		await frames()
	checks.audio_cleanup = AudioServer.bus_count == buses
	await tap(KEY_L)
	checks.menu_theme_retained = not manager.cycling_clean_theme
	checks.transition_complete = not manager.cycling_transition_pending
	checks.save_failure_reported = not manager.CyclingResults.write_best(12.0,"user://missing-rush-folder/score.json")
	checks.best_reload = manager.CyclingResults.read_best(manager.cycling_score_path) == 1500.0
	DirAccess.remove_absolute(manager.cycling_score_path)
	var failed: int = 0
	for key: String in checks:
		print(("PASS " if checks[key] else "FAIL ") + key)
		if not checks[key]: failed += 1
	print("RUSH_CHECKS: %d passed, %d failed" % [checks.size()-failed,failed])
	await frames(10)
	quit(1 if failed else 0)
