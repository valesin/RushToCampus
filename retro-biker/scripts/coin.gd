extends Area2D
# Collectible coin. Spins (width pulse) and bobs via tweens; bumps the coin
# counter on pickup, then pops and fades.

const DISPLAY := 26.0

var base_scale := Vector2.ONE
var collected := false
var _spin: Tween
var _bob: Tween

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var tex := _load_tex("res://assets/sprites/coin.png")
	sprite.centered = true
	sprite.texture = tex
	var sz := tex.get_size()
	if sz.y > 0:
		base_scale = Vector2.ONE * (DISPLAY / sz.y)
	sprite.scale = base_scale
	body_entered.connect(_on_body_entered)
	# Spin: squash the width to near-zero and back so it reads as a rotating coin.
	_spin = create_tween().set_loops()
	_spin.tween_property(sprite, "scale:x", base_scale.x * 0.12, 0.4).set_trans(Tween.TRANS_SINE)
	_spin.tween_property(sprite, "scale:x", base_scale.x, 0.4).set_trans(Tween.TRANS_SINE)
	# Bob: gentle float.
	_bob = create_tween().set_loops()
	_bob.tween_property(sprite, "position:y", -4.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob.tween_property(sprite, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	GameManager.add_coin()
	Sfx.play("coin")
	_spin.kill()
	_bob.kill()
	set_deferred("monitoring", false)
	var t := create_tween()
	t.tween_property(sprite, "position:y", sprite.position.y - 18.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(sprite, "scale", base_scale * 1.5, 0.25)
	t.parallel().tween_property(sprite, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t := load(path)
		if t is Texture2D:
			return t as Texture2D
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return ImageTexture.create_from_image(img)
