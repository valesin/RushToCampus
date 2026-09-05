extends Node
@export var section_seconds: float = 12.0
@export var warning_seconds: float = 2.0
@export var transition_seconds: float = 1.0
@export var calm_multiplier: float = 1.0
@export var head_multiplier: float = 0.75
@export var tail_multiplier: float = 1.2
@export var calm_energy_rate: float = 0.0
@export var head_energy_rate: float = -3.0
@export var tail_energy_rate: float = 3.0
@export var sheltered_energy_rate: float = 0.0
@export var sheltered_multiplier: float = 0.9
const SECTIONS: Array[String] = ["CALM", "HEADWIND", "CALM", "TAILWIND"]
var elapsed: float = 0.0

func reset() -> void:
	elapsed = 0.0

func step(delta: float) -> void:
	elapsed += delta

func index() -> int:
	return int(elapsed / section_seconds) % SECTIONS.size()

func phase() -> String:
	return SECTIONS[index()]

func warning() -> String:
	if fmod(elapsed, section_seconds) >= section_seconds - warning_seconds:
		return SECTIONS[(index() + 1) % SECTIONS.size()] + " APPROACHING"
	return ""

func values(sheltered: bool) -> Vector2:
	var current: Vector2 = _values_for(index(), sheltered)
	if elapsed < section_seconds:
		return current
	var previous: Vector2 = _values_for((index() + 3) % 4, sheltered)
	return previous.lerp(current, clampf(fmod(elapsed, section_seconds) / transition_seconds, 0.0, 1.0))

func _values_for(which: int, sheltered: bool) -> Vector2:
	match SECTIONS[which]:
		"HEADWIND":
			return Vector2(sheltered_multiplier, sheltered_energy_rate) if sheltered else Vector2(head_multiplier, head_energy_rate)
		"TAILWIND":
			return Vector2(tail_multiplier, tail_energy_rate)
	return Vector2(calm_multiplier, calm_energy_rate)
