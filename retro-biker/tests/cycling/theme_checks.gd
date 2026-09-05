extends SceneTree
var checks: Dictionary = {}
var game
var capture_path: String = ""

func _initialize() -> void:
	call_deferred("run_checks")

func frames(count: int) -> void:
	for i in count: await physics_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func tap(code: Key) -> void:
	key(code,true)
	await frames(2)
	key(code,false)
	await frames(2)

func click_toggle() -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = Vector2(480,382)
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)

func capture(name: String) -> void:
	if capture_path.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_path+"/"+name+".png")

func run_checks() -> void:
	if not OS.get_cmdline_user_args().is_empty(): capture_path = OS.get_cmdline_user_args()[0]
	game = load("res://scenes/cycling/CyclingGame.tscn").instantiate()
	game.score_path = "user://theme_checks.json"
	root.add_child(game)
	await frames(4)
	var view = game.presentation
	var sound = game.cycling_audio
	checks.default_original = not view.clean_theme
	checks.assets_loaded = view.clean_art.city != null and view.clean_art.materials != null and view.clean_art.details != null and view.clean_art.frames.size() == 2
	checks.shared_75_25 = view.Layout.CITY_HEIGHT == 135 and view.Layout.LANE_HEIGHT == 81
	checks.all_audio_loaded = sound.streams.size() == 14
	await tap(KEY_ENTER)
	game.traffic.enabled = false
	game.food.enabled = false
	checks.start = game.state == game.RunState.RUNNING
	checks.toggle_hidden_running = not view.theme_button.visible
	view.toggle_theme()
	checks.no_switch_outside_pause = not view.clean_theme
	await tap(KEY_K)
	await tap(KEY_ESCAPE)
	var snapshot: Array = [game.distance,game.elapsed,game.rider.energy,game.rider.boost_left,game.rider.lane_position]
	await click_toggle()
	checks.pause_button_switch = view.clean_theme and game.state == game.RunState.PAUSED
	checks.run_preserved_on_switch = snapshot == [game.distance,game.elapsed,game.rider.energy,game.rider.boost_left,game.rider.lane_position]
	checks.hud_unchanged = view.layers[5].material == null
	checks.paused_audio = sound.cycling_pov.stream_paused
	await capture("pause-colourful")
	await tap(KEY_ENTER)
	checks.resume = game.state == game.RunState.RUNNING and view.clean_theme
	await tap(KEY_UP)
	await frames(16)
	checks.lane_change_audio = sound.lane_change_count == 1 and game.rider.lane == 2
	checks.pov_running = sound.cycling_pov.playing
	key(KEY_DOWN,true)
	await frames(30)
	checks.held_lane_single_sound = sound.lane_change_count == 2
	key(KEY_DOWN,false)
	await tap(KEY_ESCAPE)
	await click_toggle()
	checks.switch_back = not view.clean_theme and view.layers[3].material == view.original_materials[3]
	await click_toggle()
	await tap(KEY_ENTER)
	sound.hit(false)
	checks.minor_impact_retained = sound.impact.stream == sound.streams.bump
	sound.hit(true)
	checks.major_impact_new = sound.impact.stream == sound.streams.crash and not sound.cycling_pov.playing
	game.start_run()
	checks.restart_keeps_theme = view.clean_theme and sound.lane_change_count == 0
	game.set_physics_process(false)
	game.traffic.enabled = false
	game.food.enabled = false
	for item in [["bus",0,34.0],["car",1,20.0],["car",2,47.0],["cyclist",3,37.0],["pedestrian",4,22.0],["barrier",4,50.0]]:
		game.traffic.actors.append(game.traffic.make_actor(item[0],item[1],item[2]))
	game.food.items.append({"kind":"bread","lane":3,"distance":16.0,"amount":20.0})
	game.food.items.append({"kind":"pastry","lane":2,"distance":30.0,"amount":30.0})
	await capture("staged-colourful")
	view.debug_contacts = true
	await capture("staged-colourful-contacts")
	view.debug_contacts = false
	view.set_clean_theme(false)
	await capture("staged-illustrated")
	view.set_clean_theme(true)
	game.distance = 1200
	game.previous_distance = 1200
	await capture("staged-campus")
	var failures: Array = []
	for label in checks:
		if not checks[label]: failures.append(label)
	print(JSON.stringify({"checks":checks,"count":checks.size(),"failures":failures}))
	# Allow the final diagnostic frame to complete, then use normal engine shutdown.
	await frames(10)
	quit(0 if failures.is_empty() else 1)
