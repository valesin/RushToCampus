extends StaticBody2D

func _ready() -> void:
	SpriteUtil.apply($Sprite2D, "res://assets/sprites/ground.png", Color(0.55, 0.35, 0.2), 32, 32)
