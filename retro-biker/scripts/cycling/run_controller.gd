extends Node2D
const RiderScript = preload("res://scripts/cycling/rider.gd")
const WindScript = preload("res://scripts/cycling/wind_controller.gd")
const DirectorScript = preload("res://scripts/cycling/traffic_director.gd")
const ActorScript = preload("res://scripts/cycling/traffic_actor.gd")
const PresentationScript = preload("res://scripts/cycling/presentation.gd")
const AudioScript = preload("res://scripts/cycling/cycling_audio.gd")
const FoodScript = preload("res://scripts/cycling/food_director.gd")
var food = FoodScript.new()
var cycling_audio

enum RunState { READY, RUNNING, PAUSED, CRASHED, RESULTS, SUCCESS }
@export var score_path: String = "user://cycling_best.json"
@export var route_length: float = 1500.0
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
	add_child(food)
	traffic.food = food
	presentation = PresentationScript.new()
	presentation.name = "Presentation"
	presentation.game = self
	add_child(presentation)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	best_distance = read_best(score_path)
	rider.reset()
	traffic.reset()
	food.reset()
	GameManager.stop_music()
	cycling_audio = AudioScript.new()
	cycling_audio.name = "CyclingAudio"
	cycling_audio.game = self
	add_child(cycling_audio)

func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func start_run() -> void:
	rider.reset()
	wind.reset()
	traffic.reset()
	food.reset()
	distance = 0.0
	previous_distance = 0.0
	elapsed = 0.0
	crash_left = 0.0
	last_hit = ""
	state = RunState.RUNNING
	if cycling_audio != null: cycling_audio.reset()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("cycling_boost"):
		rider.boost_input(false)
	if state == RunState.RUNNING and event.is_action_pressed("cycling_boost") and not event.is_echo():
		rider.boost_input(true)
		get_viewport().set_input_as_handled()
	# Consume distinct key edges too, so a quick tap between physics ticks is not lost.
	if state == RunState.RUNNING and not event.is_echo():
		if event.is_action_pressed("cycling_up"):
			rider.lane_input(-1)
		elif event.is_action_pressed("cycling_down"):
			rider.lane_input(1)
		elif event.is_action_released("cycling_up") or event.is_action_released("cycling_down"):
			if not Input.is_action_pressed("cycling_up") and not Input.is_action_pressed("cycling_down"):
				rider.lane_input(0)
	if event.is_action_pressed("cycling_confirm") and not event.is_echo():
		if state == RunState.READY or state == RunState.RESULTS or state == RunState.SUCCESS:
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
	var leader = traffic.find_leader(distance, rider.lane_position, rider.transition_left > 0.0, rider.contact_size.x)
	rider.sheltered = leader != null
	var values: Vector2 = wind.values(rider.sheltered)
	var lead_speed: float = leader.definition.speed if leader != null else -1.0
	rider.step(delta, values.x, values.y, lead_speed)
	previous_distance = distance
	var travel_delta: float = minf(delta, maxf(0.0, route_length - distance) / maxf(rider.speed, 0.01))
	if travel_delta < delta:
		elapsed -= delta - travel_delta
		wind.elapsed -= delta - travel_delta
		rider.lane_position = lerpf(rider.previous_lane_position, rider.lane_position, travel_delta / delta)
	distance += rider.speed * travel_delta
	traffic.step(travel_delta, elapsed, distance, rider.lane, rider.contact_size)
	for actor in traffic.actors:
		var start := Vector2(actor.previous_distance - previous_distance, actor.definition.lane - rider.previous_lane_position)
		var end := Vector2(actor.distance - distance, actor.definition.lane - rider.lane_position)
		var half: Vector2 = (actor.definition.contact_size + rider.contact_size) * 0.5
		if ActorScript.swept_contact(start, end, half):
			contact(actor)
			if state != RunState.RUNNING:
				break

	if state == RunState.RUNNING:
		food.step(travel_delta, self)

	if state == RunState.RUNNING and distance >= route_length - 0.0001:
		distance = route_length
		state = RunState.SUCCESS
		best_distance = maxf(best_distance, distance)
		save_best()
		if cycling_audio != null: cycling_audio.stop_motion()

func contact(actor) -> void:
	if actor.lethal():
		last_hit = actor.definition.kind.to_upper()
		state = RunState.CRASHED
		crash_left = 0.6
		if distance > best_distance:
			best_distance = distance
			save_best()
		if cycling_audio != null: cycling_audio.hit(true)
	elif not actor.encountered:
		actor.encountered = true
		if rider.minor_hit():
			last_hit = "BUMP — KEEP RIDING"
			if cycling_audio != null: cycling_audio.hit(false)

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
