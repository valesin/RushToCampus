extends Node
@export var base_speed: float = 8.0
@export var lane_change_seconds: float = 0.18
@export var minimum_energy_multiplier: float = 0.6
@export var minor_energy_loss: float = 20.0
@export var contact_size: Vector2 = Vector2(1.5, 0.32)
var lane: int = 3
var lane_position: float = 3.0
var previous_lane_position: float = 3.0
var source_lane: int = 3
var transition_left: float = 0.0
var input_armed: bool = true
var energy: float = 100.0
var speed: float = 8.0
var slowdown_left: float = 0.0
var cooldown_left: float = 0.0
var sheltered: bool = false

func reset() -> void:
	lane = 3
	source_lane = 3
	lane_position = 3.0
	previous_lane_position = 3.0
	transition_left = 0.0
	input_armed = false
	energy = 100.0
	speed = base_speed
	slowdown_left = 0.0
	cooldown_left = 0.0
	sheltered = false

func lane_input(direction: int) -> void:
	if direction == 0:
		input_armed = true
		return
	if not input_armed:
		return
	input_armed = false
	if transition_left > 0.0:
		return
	var destination: int = clampi(lane + direction, 0, 4)
	if destination == lane:
		return
	source_lane = lane
	lane = destination
	transition_left = lane_change_seconds
	sheltered = false

func step(delta: float, wind_multiplier: float, energy_rate: float, lead_speed: float = -1.0) -> void:
	previous_lane_position = lane_position
	transition_left = maxf(0.0, transition_left - delta)
	var progress: float = 1.0 - transition_left / lane_change_seconds
	lane_position = lerpf(float(source_lane), float(lane), smoothstep(0.0, 1.0, progress))
	energy = clampf(energy + energy_rate * delta, 0.0, 100.0)
	speed = base_speed * wind_multiplier * lerpf(minimum_energy_multiplier, 1.0, energy / 100.0)
	if slowdown_left > 0.0:
		speed *= 0.5
	if lead_speed >= 0.0:
		speed = minf(speed, lead_speed)
	slowdown_left = maxf(0.0, slowdown_left - delta)
	cooldown_left = maxf(0.0, cooldown_left - delta)

func minor_hit() -> bool:
	if cooldown_left > 0.0:
		return false
	energy = maxf(0.0, energy - minor_energy_loss)
	slowdown_left = 0.8
	cooldown_left = 1.0
	return true
