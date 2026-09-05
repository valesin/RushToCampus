extends Node2D
# Renders a 3D side-character GLB into the 2D platformer via a SubViewport.
# Default uses the walking clip; set use_run = true for the running model.

@export var use_run := false
@export var display_height := 48.0

const WALK_GLB := "res://assets/sidecharacter_Animation_Walking_withSkin.glb"
const RUN_GLB := "res://assets/sidecharacter_Animation_Running_withSkin.glb"
const MODEL_SCALE := 1.0

var _vp: SubViewport
var _sprite: Sprite2D
var _model: Node3D
var _facing := 1

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = true
	_sprite.position = Vector2(0, -display_height * 0.5)
	add_child(_sprite)

	_vp = SubViewport.new()
	_vp.size = Vector2i(128, 160)
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.own_world_3d = true
	add_child(_vp)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 50, 0)
	light.light_energy = 1.35
	light.shadow_enabled = false
	_vp.add_child(light)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-1.2, 1.8, 2.0)
	fill.light_energy = 0.75
	fill.omni_range = 10.0
	_vp.add_child(fill)

	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 28.0
	_vp.add_child(cam)
	# Tight profile framing so the character fills most of the viewport.
	cam.position = Vector3(2.6, 0.9, 0.0)
	cam.look_at(Vector3(0.0, 0.85, 0.0))

	var path := RUN_GLB if use_run else WALK_GLB
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("SideCharacter: failed to load " + path)
		return
	_model = packed.instantiate() as Node3D
	# Side-view for a 2D platformer (face +X / right).
	_model.rotation_degrees.y = -90.0
	_model.scale = Vector3.ONE * MODEL_SCALE
	_vp.add_child(_model)
	_play_anim(_model)

	await RenderingServer.frame_post_draw
	_sprite.texture = _vp.get_texture()
	var tex_h := float(_vp.size.y)
	_sprite.scale = Vector2.ONE * (display_height / tex_h)
	# Feet near the Node2D origin (Y+ is down in 2D).
	_sprite.position = Vector2(0, -display_height * 0.5)

func _play_anim(root: Node) -> void:
	var players: Array[AnimationPlayer] = []
	_collect(root, players)
	for ap in players:
		var names := ap.get_animation_list()
		if names.is_empty():
			continue
		var clip := StringName(names[0])
		for n in names:
			var s := String(n).to_lower()
			if (use_run and "run" in s) or (not use_run and "walk" in s):
				clip = StringName(n)
				break
		var anim := ap.get_animation(clip)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		ap.play(clip)

func _collect(n: Node, out: Array[AnimationPlayer]) -> void:
	if n is AnimationPlayer:
		out.append(n as AnimationPlayer)
	for c in n.get_children():
		_collect(c, out)

func face(dir: int) -> void:
	_facing = -1 if dir < 0 else 1
	if _sprite:
		_sprite.flip_h = _facing < 0
