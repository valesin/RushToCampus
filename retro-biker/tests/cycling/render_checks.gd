extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var game = load("res://scenes/cycling/CyclingGame.tscn").instantiate()
	game.score_path = "user://render_test.json"
	root.add_child(game)
	await process_frame
	game.start_run()
	game.set_physics_process(false)
	game.rider.energy = 40.0
	game.food.items.append({"kind":"bread","lane":3,"distance":23.0,"amount":20.0})
	game.food.items.append({"kind":"pastry","lane":2,"distance":43.0,"amount":30.0})
	await process_frame
	await RenderingServer.frame_post_draw
	var path: String = OS.get_cmdline_user_args()[0]
	root.get_texture().get_image().save_png(path + "/food-readability.png")
	game.rider.energy = 0.0
	game.rider.step(0.5,1.0,-4.0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path + "/recovery-hud.png")
	game.queue_free()
	await process_frame
	quit()
