extends Area2D
# Spinning sawblade hazard: rotates constantly and damages the player on contact.
# Non-stompable (not in the "enemy" group) — it hurts from every side.

const SPIN_SPEED := 9.0   # rad/sec

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	SpriteUtil.apply(sprite, "res://assets/sprites/sawblade.png", Color(0.72, 0.74, 0.8), 44, 44)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	sprite.rotation += SPIN_SPEED * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(global_position)
