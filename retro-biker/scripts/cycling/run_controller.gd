extends Node2D
const RiderScript = preload("res://scripts/cycling/rider.gd")
const WindScript = preload("res://scripts/cycling/wind_controller.gd")
const DirectorScript = preload("res://scripts/cycling/traffic_director.gd")
const ActorScript = preload("res://scripts/cycling/traffic_actor.gd")
const PresentationScript = preload("res://scripts/cycling/presentation.gd")
enum RunState { READY, RUNNING, PAUSED, CRASHED, RESULTS }
@export var score_path: String = "user://cycling_best.json"
@export var pixels_per_metre: float = 12.0
var state: RunState = RunState.READY
var rider = RiderScript.new()
var wind = WindScript.new()
var traffic = DirectorScript.new()
var presentation: Node2D
var distance: float = 0.0
var previous_distance: float = 0.0
var elapsed: float = 0.0
var best_distance: float = 0.0
var crash_left: float = 0.0
var last_hit: String = ""
var score_write_error: bool = false

func _ready() -> void:
	rider.name = "Rider"
	wind.name = "Wind"
	traffic.name = "Traffic"
	add_child(rider)
	add_child(wind)
	add_child(traffic)
	presentation = PresentationScript.new()
	presentation.name = "Presentation"
	presentation.game = self
	add_child(presentation)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	best_distance = read_best(score_path)
	rider.reset()
	traffic.reset()
	GameManager.play_game()

func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func start_run() -> void:
	rider.reset()
	wind.reset()
	traffic.reset()
	distance = 0.0
	previous_distance = 0.0
	elapsed = 0.0
	crash_left = 0.0
	last_hit = ""
	state = RunState.RUNNING
	Sfx.play("select")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cycling_confirm") and not event.is_echo():
		if state == RunState.READY or state == RunState.RESULTS:
			start_run()
		elif state == RunState.PAUSED:
			state = RunState.RUNNING
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("cycling_pause") and not event.is_echo():
		if state == RunState.RUNNING:
			state = RunState.PAUSED
		elif state == RunState.PAUSED:
			state = RunState.RUNNING
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if state == RunState.CRASHED:
		crash_left -= delta
		if crash_left <= 0.0:
			state = RunState.RESULTS
	elif state == RunState.RUNNING:
		var direction: int = int(Input.is_action_pressed("cycling_down")) - int(Input.is_action_pressed("cycling_up"))
		rider.lane_input(direction)
		simulate(delta)
	presentation.queue_redraw()

func simulate(delta: float) -> void:
	if state != RunState.RUNNING:
		return
	elapsed += delta
	wind.step(delta)
	var leader = traffic.find_leader(distance, rider.lane_position, rider.transition_left > 0.0)
	rider.sheltered = leader != null
	var values: Vector2 = wind.values(rider.sheltered)
	var lead_speed: float = leader.definition.speed if leader != null else -1.0
	rider.step(delta, values.x, values.y, lead_speed)
	previous_distance = distance
	distance += rider.speed * delta
	traffic.step(delta, elapsed, distance, rider.lane, rider.contact_size)
	for actor in traffic.actors:
		var start := Vector2(actor.previous_distance - previous_distance, actor.definition.lane - rider.previous_lane_position)
		var end := Vector2(actor.distance - distance, actor.definition.lane - rider.lane_position)
		var half: Vector2 = (actor.definition.contact_size + rider.contact_size) * 0.5
		if ActorScript.swept_contact(start, end, half):
			contact(actor)
			if state != RunState.RUNNING:
				break

func contact(actor) -> void:
	if actor.lethal():
		last_hit = actor.definition.kind.to_upper()
		state = RunState.CRASHED
		crash_left = 0.6
		if distance > best_distance:
			best_distance = distance
			save_best()
		Sfx.play("gameover")
	elif not actor.encountered:
		actor.encountered = true
		if rider.minor_hit():
			last_hit = "BUMP — KEEP RIDING"
			Sfx.play("hurt")

static func read_best(path: String) -> float:
	if not FileAccess.file_exists(path):
		return 0.0
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0.0
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return 0.0
	var parsed = parser.data
	if not parsed is Dictionary:
		return 0.0
	var value = parsed.get("best_distance", 0.0)
	if not (value is float or value is int):
		return 0.0
	return maxf(0.0, float(value)) if is_finite(float(value)) else 0.0

func save_best() -> void:
	var file := FileAccess.open(score_path, FileAccess.WRITE)
	score_write_error = file == null
	if file != null:
		file.store_string(JSON.stringify({"best_distance": best_distance}))
