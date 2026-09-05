extends SceneTree
const Layout = preload("res://scripts/cycling/presentation_layout.gd")
var checks: Dictionary = {}
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var game = load("res://scenes/cycling/CyclingGame.tscn").instantiate()
	game.score_path = "user://visual_checks.json"
	root.add_child(game)
	await process_frame
	game.start_run()
	game.set_physics_process(false)
	game.traffic.enabled = false
	game.food.enabled = false
	checks.layout_85_15 = Layout.CITY_HEIGHT == 81.0 and is_equal_approx(Layout.LANE_HEIGHT*5,459.0)
	checks.horizontal_scale_preserved = game.pixels_per_metre == 12.0 and Layout.PLAYER_X == 240.0
	checks.layer_separation = game.presentation.layers.size() == 6
	checks.native_sprite_widths = game.presentation.ART_WIDTHS == {"player":82.0,"cyclist":82.0,"car":110.0,"bus":170.0,"pedestrian":40.0,"barrier":55.0}
	var aligned: bool = true
	for lane in 5:
		var rect: Rect2 = Layout.contact_rect(0,lane,Vector2(13,0.4),0,12)
		aligned = aligned and rect.position.y >= Layout.lane_top(lane) and rect.end.y <= Layout.lane_top(lane)+Layout.LANE_HEIGHT
	checks.contacts_inside_lane_bands = aligned
	checks.continuous_projection = is_equal_approx(Layout.lane_y(2.5),(Layout.lane_y(2)+Layout.lane_y(3))*0.5)
	checks.bottom_lane_visible = Layout.lane_y(4)+0.2*Layout.LANE_HEIGHT < 540.0
	var path: String = OS.get_cmdline_user_args()[0]
	# Staged diagnostic: all traffic kinds, plus both pickups, through real renderer.
	for item in [["bus",0,34.0],["car",1,20.0],["car",2,47.0],["cyclist",3,37.0],["pedestrian",4,22.0],["barrier",4,50.0]]:
		game.traffic.actors.append(game.traffic.make_actor(item[0],item[1],item[2]))
	game.food.items.append({"kind":"bread","lane":3,"distance":16.0,"amount":20.0})
	game.food.items.append({"kind":"pastry","lane":2,"distance":30.0,"amount":30.0})
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path+"/staged-all-lanes.png")
	game.presentation.debug_contacts = true
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path+"/collision-projection.png")
	game.presentation.debug_contacts = false
	# Native rendering at material and district boundaries; two adjacent frames each.
	for boundary in [512.0/12.0, 480.0, 960.0, 1200.0]:
		for side in [-0.01,0.01]:
			game.distance = boundary+side
			game.previous_distance = game.distance
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(path+"/seam-%s-%s.png" % [str(boundary).replace(".","_"),"before" if side<0 else "after"])
	# Use an empty scene for a normal-rate renderer timing sample.
	game.traffic.reset()
	game.food.reset()
	var times: Array[float] = []
	var before: int = Time.get_ticks_usec()
	for i in 90:
		await process_frame
		var now: int = Time.get_ticks_usec()
		times.append((now-before)/1000.0)
		before = now
	times.sort()
	var failures: Array = []
	for label in checks:
		if not checks[label]: failures.append(label)
	print(JSON.stringify({"checks":checks,"failures":failures,"render_frame_median_ms":times[45],"render_frame_p95_ms":times[85]}))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
