extends Area2D

var used := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	SpriteUtil.apply_fitted(sprite, collider, "res://assets/sprites/door.png", Color(0.2, 0.7, 0.3), 46, 4.0, 4.0)
	body_entered.connect(_on_body_entered)
	_snap_to_ground()

# The door is a static Area2D (it doesn't fall like the player/enemies), so rest
# its base on the first solid surface directly below its spawn cell.
func _snap_to_ground() -> void:
	await get_tree().physics_frame  # wait until the level's blocks exist in the physics space
	var space := get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 4000), 1)
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return
	var half_h := 23.0
	if collider.shape is RectangleShape2D:
		half_h = (collider.shape as RectangleShape2D).size.y * 0.5
	global_position.y = hit.position.y - half_h

func _on_body_entered(body: Node) -> void:
	if used:
		return
	if body.is_in_group("player"):
		used = true
		Sfx.play("level_complete")
		GameManager.next_level()
