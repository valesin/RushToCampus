extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -560.0
const GRAVITY := 1100.0

const KNOCKBACK_UP := -320.0      # upward pop when hit
const KNOCKBACK_SIDE := 200.0     # pushed away from the enemy
const KNOCKBACK_TIME := 0.18      # brief control lock so the knockback registers
const IFRAME_TIME := 1.2          # invincibility after a hit

const DISPLAY_H := 56.0           # on-screen character height
const RUN_FPS := 10.0             # run-cycle speed at full run speed

const COYOTE_TIME := 0.10   # grace window to still jump just after leaving a ledge

var kill_y := 100000.0
var dead := false
var invincible := false
var knockback_time := 0.0
var coyote := 0.0

# Frame animation state.
var idle_tex: Texture2D
var jump_tex: Texture2D
var run_frames: Array[Texture2D] = []
var base_scale := Vector2.ONE
var run_time := 0.0
var land_squash := 0.0
var was_airborne := false
var _last_run_idx := -1

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("player")
	idle_tex = _load_tex("res://assets/sprites/player_idle.png")
	jump_tex = _load_tex("res://assets/sprites/player_jump.png")
	run_frames = [
		_load_tex("res://assets/sprites/player_run1.png"),
		_load_tex("res://assets/sprites/player_run2.png"),
		_load_tex("res://assets/sprites/player_run3.png"),
	]

	sprite.centered = true
	sprite.texture = idle_tex
	var canvas := idle_tex.get_size()                 # all frames share this size
	base_scale = Vector2.ONE * (DISPLAY_H / canvas.y)
	sprite.scale = base_scale
	sprite.offset = Vector2(0, -canvas.y / 2.0)        # anchor feet (canvas bottom) at the node origin

	# Collider: standing-body sized, bottom resting at the feet (origin).
	if shape.shape is RectangleShape2D:
		var body_h := DISPLAY_H - 4.0
		var body_w := DISPLAY_H * 0.40
		var r := (shape.shape as RectangleShape2D).duplicate() as RectangleShape2D
		r.size = Vector2(body_w, body_h)
		shape.shape = r
		shape.position = Vector2(0, -body_h / 2.0)

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
		coyote = maxf(0.0, coyote - delta)
	else:
		coyote = COYOTE_TIME

	if knockback_time > 0.0:
		# Keep the knockback velocity; ignore input for a moment.
		knockback_time -= delta
	else:
		if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote > 0.0):
			velocity.y = JUMP_VELOCITY
			coyote = 0.0
			Sfx.play("jump")
		var dir := Input.get_axis("move_left", "move_right")
		velocity.x = dir * SPEED
		if dir != 0.0:
			sprite.flip_h = dir < 0.0

	move_and_slide()
	_resolve_enemy_collisions()
	_animate(delta)

	if global_position.y > kill_y:
		_fall_off()

# After move_and_slide(): use the real collision normals to tell a stomp (we
# landed on the enemy's top) from a body hit (we touched its side/underside).
# Because move_and_slide is swept, this stays correct even at high fall speed.
func _resolve_enemy_collisions() -> void:
	# One frame can report several contacts with the SAME enemy (top + side).
	# Resolve each enemy exactly once: if ANY contact is a top hit, it's a stomp;
	# otherwise it's a body hit. This prevents stomping AND taking damage together.
	var top := {}        # instance_id -> true if any top contact
	var hit := {}        # instance_id -> enemy node
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var enemy = c.get_collider()
		if enemy == null or not enemy.is_in_group("enemy"):
			continue
		var id := enemy.get_instance_id()
		hit[id] = enemy
		if c.get_normal().y < -0.5:
			top[id] = true

	for id in hit:
		var enemy = hit[id]
		if top.has(id) and enemy.has_method("on_stomped"):
			var pop: float = enemy.on_stomped()
			if pop < 0.0:
				velocity.y = pop
				land_squash = 1.0
				Sfx.play("stomp")
				continue        # stomped -> never also take damage from it
		take_damage(enemy.global_position)

# Picks the frame for the current state and adds a feet-planted landing squash.
func _animate(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor and was_airborne:
		land_squash = 1.0
		Sfx.play("land", -4.0)
	was_airborne = not on_floor
	land_squash = maxf(0.0, land_squash - delta * 6.0)

	if not on_floor:
		sprite.texture = jump_tex
		run_time = 0.0
	elif absf(velocity.x) > 20.0:
		run_time += delta * RUN_FPS * (absf(velocity.x) / SPEED)
		var idx := int(run_time) % run_frames.size()
		if idx != _last_run_idx:
			_last_run_idx = idx
			if idx == 0 or idx == 2:
				Sfx.play("footstep", -12.0, randf_range(0.95, 1.08))
		sprite.texture = run_frames[idx]
	else:
		sprite.texture = idle_tex
		run_time = 0.0
		_last_run_idx = -1

	# Landing pop. Sprite is feet-anchored, so this squashes toward the ground.
	sprite.scale = base_scale * Vector2(1.0 + 0.18 * land_squash, 1.0 - 0.22 * land_squash)

# Called by an enemy's hitbox. Lose a heart in place: knock back, blink, and
# stay invincible briefly so the player can recover and keep playing.
func take_damage(source_pos: Vector2) -> void:
	if dead or invincible:
		return
	if GameManager.lose_life():
		dead = true
		_die_throes()
		return
	Sfx.play("hurt")
	var dir_x := signf(global_position.x - source_pos.x)
	if dir_x == 0.0:
		dir_x = 1.0
	velocity.y = KNOCKBACK_UP
	velocity.x = dir_x * KNOCKBACK_SIDE
	knockback_time = KNOCKBACK_TIME
	_blink()

# Classic pop-up-and-tumble death so you can watch yourself go before the Game
# Over screen (GameManager holds the scene change for GAME_OVER_DELAY seconds).
func _die_throes() -> void:
	Sfx.play("death")
	velocity = Vector2.ZERO
	var y0 := position.y
	var move := create_tween()
	move.tween_property(self, "position:y", y0 - 48.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	move.tween_property(self, "position:y", y0 + 260.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var spin := create_tween()
	spin.tween_property(sprite, "rotation", deg_to_rad(160.0), 1.35)

# Called by a bounce pad: launch straight up regardless of floor state.
func bounce(strength: float) -> void:
	if dead:
		return
	velocity.y = strength
	land_squash = 1.0
	Sfx.play("bounce")

# Fell off the bottom of the level: lose a heart and respawn at the start.
func _fall_off() -> void:
	if dead:
		return
	Sfx.play("death")
	if GameManager.lose_life():
		dead = true
		return
	get_tree().reload_current_scene()

func _blink() -> void:
	invincible = true
	var blinks := 6
	var step := IFRAME_TIME / (blinks * 2.0)
	var tween := create_tween()
	tween.set_loops(blinks)
	tween.tween_property(sprite, "modulate:a", 0.25, step)
	tween.tween_property(sprite, "modulate:a", 1.0, step)
	await tween.finished
	sprite.modulate.a = 1.0
	invincible = false
