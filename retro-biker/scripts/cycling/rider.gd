extends Node
@export var base_speed: float = 14.4
@export var lane_change_seconds: float = 0.18
@export var contact_size: Vector2 = Vector2(5.0, 0.32)
const BOOST_SPEED: float = 21.6
const BOOST_SECONDS: float = 2.0
const BOOST_COST: float = 20.0
const RECOVERY_SPEED: float = 7.2
const RECOVERY_SECONDS: float = 2.0
var boost_left: float = 0.0
var recovery_left: float = 0.0
var boost_armed: bool = true
var recovering: bool = false
var target_speed: float = 14.4
var cruising_speed: float = 14.4
var animation_phase: float = 0.0
var energy_change: float = 0.0
var lane: int = 3
var lane_position: float = 3.0
var previous_lane_position: float = 3.0
var source_lane: int = 3
var transition_left: float = 0.0
var input_armed: bool = true
var energy: float = 100.0
var speed: float = 14.4
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
	cruising_speed = base_speed
	target_speed = base_speed
	recovering = false
	boost_left = 0.0
	recovery_left = 0.0
	boost_armed = not Input.is_action_pressed("cycling_boost")
	animation_phase = 0.0
	energy_change = 0.0
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
	# Resolve a completed boost only on the next step, after contacts/food for
	# its final movement segment have been collected by the run controller.
	if boost_left <= 0.0 and not recovering and energy <= 0.0:
		recovering = true
		recovery_left = RECOVERY_SECONDS
	energy_change = 0.0
	if recovering:
		var recovering_delta: float = minf(delta, recovery_left)
		energy_change = 25.0 / RECOVERY_SECONDS
		energy = minf(100.0, energy + energy_change * recovering_delta)
		recovery_left = maxf(0.0, recovery_left - delta)
		target_speed = RECOVERY_SPEED
		if recovery_left < 0.000001:
			recovery_left = 0.0
			recovering = false
	elif boost_left > 0.0:
		target_speed = BOOST_SPEED
		boost_left = maxf(0.0, boost_left - delta)
		if boost_left < 0.000001: boost_left = 0.0
		energy_change = 0.0 if sheltered else minf(0.0, energy_rate)
		energy = maxf(0.0, energy + energy_change * delta)
	else:
		target_speed = base_speed * wind_multiplier
		energy_change = 0.0 if sheltered else minf(0.0, energy_rate)
		energy = maxf(0.0, energy + energy_change * delta)
	cruising_speed = target_speed
	speed = cruising_speed
	if slowdown_left > 0.0:
		speed *= 0.5
	if lead_speed >= 0.0 and target_speed != BOOST_SPEED:
		speed = minf(speed, lead_speed)
	animation_phase += delta * speed / base_speed * 6.0
	slowdown_left = maxf(0.0, slowdown_left - delta)
	cooldown_left = maxf(0.0, cooldown_left - delta)

func minor_hit() -> bool:
	if cooldown_left > 0.0:
		return false
	slowdown_left = 0.8
	cooldown_left = 1.0
	return true

func boost_input(pressed: bool) -> bool:
	if not pressed:
		boost_armed = true
		return false
	if not boost_armed: return false
	boost_armed = false
	if recovering or boost_left > 0.0 or energy < BOOST_COST: return false
	energy -= BOOST_COST
	boost_left = BOOST_SECONDS
	return true

func add_food(amount: float) -> void:
	energy = clampf(energy + amount, 0.0, 100.0)

func boost_ready() -> bool:
	return not recovering and boost_left <= 0.0 and energy >= BOOST_COST
