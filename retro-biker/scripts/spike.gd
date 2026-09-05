extends Area2D
# Hazard tile: damages the player on contact, the same way enemies do.
# Non-solid (Area2D), so it sits in a cell and hurts whoever overlaps it.

func _ready() -> void:
	SpriteUtil.apply($Sprite2D, "res://assets/sprites/spike.png", Color(0.72, 0.74, 0.8), 32, 32)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(global_position)
