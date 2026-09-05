extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scenes/cycling/CyclingGame.tscn").instantiate()
	game.score_path = "user://web_export_verification.json"
	root.add_child(game)
	await process_frame
	var checks: Dictionary = load("res://tests/cycling/runner_checks.gd").run(game)
	var failures: Array = []
	for label in checks:
		if not checks[label]: failures.append(label)
	print(JSON.stringify({"checks": checks, "count": checks.size(), "failures": failures}))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
