extends CharacterBody2D
# Critter King boss. Invulnerable except to head-stomps (jump on his head while
# falling). He paces the arena and periodically telegraphs a charge-dash. Three
# stomps defeat him; he enrages (faster, more frequent charges) with each hit.
# Beating him advances the game, which (being the last room) shows the Win screen.

const GRAVITY := 1100.0
const DISPLAY_H := 84.0
const MAX_HP := 3
const STOMP_BOUNCE := -440.0     # pop the player gets after stomping the crown

const PATROL_SPEED := 62.0
const CHARGE_SPEED := 220.0
const WALK_FPS := 5.0

enum State { PATROL, TELEGRAPH, CHARGE, RECOVER, DEAD }

var hp := MAX_HP
var dir := -1
var state := State.PATROL
var state_time := 0.0
var invuln := 0.0
var walk_time := 0.0

var walk_frames: Array[Texture2D] = []
var charge_tex: Texture2D
var hurt_tex: Texture2D
var base_scale := Vector2.ONE

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	GameManager.play_boss()        # swap to the battle theme when the boss room loads
	Sfx.play("boss_intro")         # dramatic reveal sting on entry
	walk_frames = [
		_load_tex("res://assets/sprites/boss_walk1.png"),
		_load_tex("res://assets/sprites/boss_walk2.png"),
	]
	charge_tex = _load_tex("res://assets/sprites/boss_charge.png")
	hurt_tex = _load_tex("res://assets/sprites/boss_hurt.png")

	sprite.centered = true
	sprite.texture = walk_frames[0]
	var canvas := walk_frames[0].get_size()
	base_scale = Vector2.ONE * (DISPLAY_H / canvas.y)
	sprite.scale = base_scale
	sprite.offset = Vector2(0, -canvas.y / 2.0)        # feet (canvas bottom) at the origin

	# Build the collider from the sprite's actual opaque bounds so the hitbox
	# matches what you see (the rounded body is wider than a fixed heuristic).
	# Sprite is feet-anchored, so the canvas bottom maps to local y = 0.
	if $CollisionShape2D.shape is RectangleShape2D:
		var r := ($CollisionShape2D.shape as RectangleShape2D).duplicate() as RectangleShape2D
		var img := walk_frames[0].get_image()
		if img != null and img.is_compressed():
			img.decompress()
		var used := img.get_used_rect() if img != null else Rect2i()
		if used.size.x > 0 and used.size.y > 0:
			var sc := DISPLAY_H / canvas.y
			var top_l := (used.position.y - canvas.y) * sc
			var bot_l := (used.position.y + used.size.y - canvas.y) * sc
			r.size = Vector2(used.size.x * sc, bot_l - top_l)
			$CollisionShape2D.position = Vector2(0, (top_l + bot_l) / 2.0)
		else:
			# Fallback if the texture is not imported yet.
			r.size = Vector2(DISPLAY_H * 0.74, DISPLAY_H - 8.0)
			$CollisionShape2D.position = Vector2(0, -(DISPLAY_H - 8.0) / 2.0)
		$CollisionShape2D.shape = r

	_enter_patrol()

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t := load(path)
		if t is Texture2D:
			return t as Texture2D
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return ImageTexture.create_from_image(img)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if invuln > 0.0:
		invuln -= delta

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	state_time -= delta
	match state:
		State.PATROL:
			velocity.x = dir * _enraged(PATROL_SPEED)
			if is_on_wall():
				dir *= -1
			if state_time <= 0.0:
				_enter_telegraph()
		State.TELEGRAPH:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			dir = -1 if _player_x() < global_position.x else 1     # face the player
			if state_time <= 0.0:
				state = State.CHARGE
				state_time = 1.6
		State.CHARGE:
			velocity.x = dir * _enraged(CHARGE_SPEED)
			if is_on_wall() or state_time <= 0.0:
				state = State.RECOVER
				state_time = 0.6
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if state_time <= 0.0:
				_enter_patrol()

	move_and_slide()
	_animate(delta)

func _enter_patrol() -> void:
	state = State.PATROL
	state_time = maxf(0.9, 2.6 - float(MAX_HP - hp) * 0.5)

func _enter_telegraph() -> void:
	state = State.TELEGRAPH
	state_time = maxf(0.4, 0.75 - float(MAX_HP - hp) * 0.12)

# Speed scales up as he loses health (enrage).
func _enraged(base: float) -> float:
	return base * (1.0 + float(MAX_HP - hp) * 0.28)

func _player_x() -> float:
	var ps := get_tree().get_first_node_in_group("player")
	return (ps as Node2D).global_position.x if ps else global_position.x

func _animate(delta: float) -> void:
	var flash := invuln > 0.0 and int(invuln * 12.0) % 2 == 0
	sprite.modulate = Color(1, 0.5, 0.5) if flash else Color(1, 1, 1)
	if state == State.TELEGRAPH or state == State.CHARGE:
		sprite.texture = charge_tex
	else:
		walk_time += delta * WALK_FPS * (1.0 + float(MAX_HP - hp) * 0.3)
		sprite.texture = walk_frames[int(walk_time) % walk_frames.size()]
	sprite.flip_h = dir < 0

# Player landed on the crown (see player._resolve_enemy_collisions). Always bounce
# the player off; register a hit only if we are not currently in i-frames.
func on_stomped() -> float:
	if state == State.DEAD:
		return 0.0
	if invuln <= 0.0:
		_take_hit()
	return STOMP_BOUNCE

func _take_hit() -> void:
	hp -= 1
	invuln = 0.8
	velocity.x = -dir * 80.0          # small recoil
	if hp <= 0:
		_die()

func _die() -> void:
	state = State.DEAD
	Sfx.play("boss_win")           # victory fanfare on defeat (Sfx autoload survives the scene change)
	velocity = Vector2.ZERO
	sprite.texture = hurt_tex
	remove_from_group("enemy")
	collision_layer = 0
	$CollisionShape2D.set_deferred("disabled", true)
	var tw := create_tween()
	tw.tween_property(sprite, "scale", base_scale * Vector2(1.3, 0.25), 0.25)
	tw.tween_interval(0.4)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.4)
	await tw.finished
	GameManager.next_level()
