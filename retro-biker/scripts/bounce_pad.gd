extends StaticBody2D
# Solid pad that launches anything able to bounce(). A top Area2D (mask 2) detects
# the player landing and calls player.bounce(strength). The player's bounce()
# method is added separately in player.gd.

@export var strength: float = -820.0

func _ready() -> void:
	SpriteUtil.apply($Sprite2D, "res://assets/sprites/bounce.png", Color(0.95, 0.35, 0.55), 32, 14)
	$BounceZone.body_entered.connect(_on_zone_entered)

func _on_zone_entered(body: Node) -> void:
	if body.has_method("bounce"):
		body.bounce(strength)
