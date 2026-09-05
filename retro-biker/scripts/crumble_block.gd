extends StaticBody2D
# Brick that falls away shortly after the player stands on it, then respawns.
# A top Area2D (mask 2) detects the player; collision is disabled then re-enabled.

@export var fuse: float = 0.4          # delay after touch before it drops
@export var respawn_time: float = 3.0

var _triggered := false
@onready var col: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	SpriteUtil.apply(sprite, "res://assets/sprites/crumble.png", Color(0.72, 0.58, 0.38), 32, 32)
	$TopZone.body_entered.connect(_on_top)

func _on_top(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	_crumble()

func _crumble() -> void:
	var shake := create_tween()
	for i in range(4):
		shake.tween_property(sprite, "position:x", 2.0, 0.05)
		shake.tween_property(sprite, "position:x", -2.0, 0.05)
	await get_tree().create_timer(fuse).timeout
	Sfx.play("crumble")
	col.set_deferred("disabled", true)
	sprite.modulate.a = 0.0
	await get_tree().create_timer(respawn_time).timeout
	col.set_deferred("disabled", false)
	sprite.position.x = 0.0
	var fade := create_tween()
	fade.tween_property(sprite, "modulate:a", 1.0, 0.3)
	_triggered = false
