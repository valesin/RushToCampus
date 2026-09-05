extends CharacterBody2D

const SPEED := 55.0
const GRAVITY := 1100.0
const DISPLAY_H := 34.0       # on-screen height
const WALK_FPS := 6.0         # waddle cadence

# Can the player kill a critter by jumping on its head? Flip to false to make
# critters un-stompable (landing on one then just hurts the player, like a side hit).
const STOMPABLE := true
const STOMP_BOUNCE := -480.0  # the player's pop after a successful stomp

var dir := -1
var dead := false
var walk_frames: Array[Texture2D] = []
var base_scale := Vector2.ONE
var walk_time := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var ledge_left: RayCast2D = $LedgeLeft
@onready var ledge_right: RayCast2D = $LedgeRight

func _ready() -> void:
	add_to_group("enemy")
	# Hug descending slopes/steps instead of launching off, and treat a 45° slope
	# as floor rather than a wall (otherwise is_on_wall flips us on the slant).
	floor_snap_length = 20.0
	floor_max_angle = deg_to_rad(50.0)
	walk_frames = [
		_load_tex("res://assets/sprites/critter_walk1.png"),
		_load_tex("res://assets/sprites/critter_walk2.png"),
	]
	sprite.centered = true
	sprite.texture = walk_frames[0]
	var canvas := walk_frames[0].get_size()
	base_scale = Vector2.ONE * (DISPLAY_H / canvas.y)
	sprite.scale = base_scale
	sprite.offset = Vector2(0, -canvas.y / 2.0)        # feet (canvas bottom) at the origin

	var body_h := DISPLAY_H - 6.0
	var body_w := DISPLAY_H * 0.78
	if $CollisionShape2D.shape is RectangleShape2D:
		var r := ($CollisionShape2D.shape as RectangleShape2D).duplicate() as RectangleShape2D
		r.size = Vector2(body_w, body_h)
		$CollisionShape2D.shape = r
		$CollisionShape2D.position = Vector2(0, -body_h / 2.0)   # bottom at feet

	# Ledge feelers just ahead of the body, crossing the floor surface at the feet.
	var ahead := body_w * 0.5 + 4.0
	ledge_left.position = Vector2(-ahead, -6.0)
	ledge_left.target_position = Vector2(0, 40.0)
	ledge_right.position = Vector2(ahead, -6.0)
	ledge_right.target_position = Vector2(0, 40.0)

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t := load(path)
		if t is Texture2D:
			return t as Texture2D
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return ImageTexture.create_from_image(img)

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		# Turn around at a ledge (no ground ahead in the travel direction).
		var ray := ledge_left if dir < 0 else ledge_right
		if not ray.is_colliding():
			dir *= -1

	velocity.x = dir * SPEED
	move_and_slide()

	# Turn around at a wall.
	if is_on_wall():
		dir *= -1

	# Waddle: alternate the two walk frames; frames face right, so flip when going left.
	walk_time += delta * WALK_FPS
	sprite.texture = walk_frames[int(walk_time) % walk_frames.size()]
	sprite.flip_h = dir < 0

# Called by the player when it lands on our head (see player._resolve_enemy_collisions).
# Returns the bounce velocity to give the player (negative). Returns 0.0 if we are
# not stompable, so the player treats the top contact as a body hit and takes damage.
func on_stomped() -> float:
	if dead or not STOMPABLE:
		return 0.0
	dead = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	collision_layer = 0                       # stop blocking the player as we squash
	$CollisionShape2D.set_deferred("disabled", true)
	var tw := create_tween()
	tw.tween_property(sprite, "scale", base_scale * Vector2(1.35, 0.2), 0.08)
	tw.tween_interval(0.18)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)
	return STOMP_BOUNCE
