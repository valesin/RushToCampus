extends Node
@export var section_seconds: float = 12.0
@export var warning_seconds: float = 2.0
@export var head_seconds: float = 8.0
const SECTIONS: Array[String] = ["CALM", "HEADWIND", "CALM", "TAILWIND"]
var elapsed: float = 0.0

func reset() -> void:
	elapsed = 0.0

func step(delta: float) -> void:
	elapsed += delta

func section_time() -> float:
	var time: float = fmod(elapsed, section_seconds * 3.0 + head_seconds)
	for i in 4:
		var duration: float = head_seconds if i == 1 else section_seconds
		if time < duration: return time
		time -= duration
	return 0.0

func index() -> int:
	var time: float = fmod(elapsed, section_seconds * 3.0 + head_seconds)
	for i in 4:
		var duration: float = head_seconds if i == 1 else section_seconds
		if time < duration: return i
		time -= duration
	return 0

func phase() -> String:
	return SECTIONS[index()]

func warning() -> String:
	var duration: float = head_seconds if index() == 1 else section_seconds
	if section_time() >= duration - warning_seconds:
		return SECTIONS[(index() + 1) % 4] + " APPROACHING"
	return ""

func values(sheltered: bool) -> Vector2:
	match phase():
		"HEADWIND": return Vector2(1.0, 0.0 if sheltered else -4.0)
		"TAILWIND": return Vector2(1.1, 0.0)
	return Vector2(1.0, 0.0)
