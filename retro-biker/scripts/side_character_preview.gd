extends Node3D
# Boots walk/run clips on the imported side-character GLBs.

func _ready() -> void:
	_play_first($Walker, true)
	_play_first($Runner, true)
	# Simple ground plane so feet have something to sit on.
	var ground: MeshInstance3D = $Ground
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(10, 10)
	ground.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.2, 0.24)
	ground.material_override = mat

func _play_first(root: Node, loop: bool) -> void:
	if root == null:
		return
	var players: Array[AnimationPlayer] = []
	_collect(root, players)
	for ap in players:
		var names := ap.get_animation_list()
		if names.is_empty():
			continue
		var clip := StringName(names[0])
		# Prefer named walk/run clips when present.
		for n in names:
			var s := String(n).to_lower()
			if "walk" in s or "run" in s:
				clip = StringName(n)
				break
		if loop:
			var anim := ap.get_animation(clip)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
		ap.play(clip)

func _collect(n: Node, out: Array[AnimationPlayer]) -> void:
	if n is AnimationPlayer:
		out.append(n as AnimationPlayer)
	for c in n.get_children():
		_collect(c, out)
