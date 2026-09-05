extends Camera2D
# Follows `target` on x, locked on y, clamped to level bounds.
# The level loader sets target / min_x / max_x / fixed_y / zoom after build.

var target: Node2D = null
var min_x := 0.0
var max_x := 0.0
var fixed_y := 0.0

func _process(_delta: float) -> void:
	if target == null:
		return
	var x := clampf(target.global_position.x, min_x, maxf(min_x, max_x))
	global_position = Vector2(x, fixed_y)
