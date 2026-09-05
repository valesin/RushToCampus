extends SceneTree

func _initialize() -> void:
	call_deferred("_go")

func _go() -> void:
	var packed := load("res://assets/sidecharacter_Animation_Walking_withSkin.glb") as PackedScene
	var inst := packed.instantiate()
	root.add_child(inst)
	await process_frame
	inst.scale = Vector3.ONE * 100.0
	await process_frame
	print("ROOT=", inst.name, " class=", inst.get_class())
	var mesh_i: MeshInstance3D = inst.find_child("char1", true, false) as MeshInstance3D
	print("MESH=", mesh_i)
	if mesh_i:
		print("AABB_LOCAL=", mesh_i.get_aabb())
		print("GLOBAL=", mesh_i.global_transform)
		print("MESH_RES=", mesh_i.mesh)
		if mesh_i.mesh:
			print("SURFACES=", mesh_i.mesh.get_surface_count())
			for s in mesh_i.mesh.get_surface_count():
				print("SURF", s, " mat=", mesh_i.mesh.surface_get_material(s))
		print("MAT_OVERRIDE=", mesh_i.material_override)
		print("SKIN=", mesh_i.skin)
		print("SKELETON=", mesh_i.get_skeleton_path() if mesh_i.has_method("get_skeleton_path") else mesh_i.skeleton)
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		print("ANIMS=", ap.get_animation_list())
		ap.play(ap.get_animation_list()[0])
		await process_frame
		await process_frame
		print("AFTER_ANIM_AABB=", mesh_i.get_aabb() if mesh_i else null)
		print("AFTER_ANIM_GLOBAL=", mesh_i.global_transform if mesh_i else null)
	quit(0)
