extends Node2D
# Parses the current ASCII level into instanced Block / Player / Critter / Door
# scenes, then configures the camera.

const TILE := 32
# Base (zoom 1.0) half-viewport in pixels: 640x360 / 2.
const VIEW_HALF_W := 320.0
const VIEW_HALF_H := 180.0
# Camera zoom: < 1.0 shows MORE of the world (zoomed out).
const ZOOM := 0.6

@onready var entities: Node2D = $Entities
@onready var camera = $Camera2D

func _ready() -> void:
	GameManager.play_game()
	var path := GameManager.get_current_level_path()
	var text := ""
	if FileAccess.file_exists(path):
		text = FileAccess.get_file_as_string(path)
	else:
		push_error("Level file not found: " + path)
	_build(text)

func _build(text: String) -> void:
	var lines := text.replace("\r", "").split("\n")
	var rows := lines.size()
	var cols := 0
	var player: Node2D = null

	for y in range(rows):
		var line: String = lines[y]
		cols = maxi(cols, line.length())
		for x in range(line.length()):
			var c := line[x]
			var pos := Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
			match c:
				"#":
					_spawn("res://scenes/Block.tscn", pos)
				"P":
					player = _spawn("res://scenes/Player.tscn", pos)
				"G":
					_spawn("res://scenes/Critter.tscn", pos)
				"D":
					_spawn("res://scenes/Door.tscn", pos)
				"-":
					_spawn("res://scenes/MovingPlatformH.tscn", pos)
				"|":
					_spawn("res://scenes/MovingPlatformV.tscn", pos)
				"/":
					_spawn("res://scenes/SlopeUp.tscn", pos)
				"\\":
					_spawn("res://scenes/SlopeDown.tscn", pos)
				"o":
					_spawn("res://scenes/BouncePad.tscn", pos)
				"x":
					_spawn("res://scenes/CrumbleBlock.tscn", pos)
				"^":
					_spawn("res://scenes/Spike.tscn", pos)
				"s":
					_spawn("res://scenes/Sawblade.tscn", pos)
				"B":
					_spawn("res://scenes/Boss.tscn", pos)
				"c":
					_spawn("res://scenes/Coin.tscn", pos)
				"h":
					_spawn("res://scenes/Heart.tscn", pos)
				_:
					pass

	var level_w := cols * TILE
	var level_h := rows * TILE

	if player != null and "kill_y" in player:
		player.kill_y = level_h + 200.0

	# When zoomed out the camera sees more world, so the clamp half-extents
	# grow by 1/ZOOM.
	camera.zoom = Vector2(ZOOM, ZOOM)
	var half_w := VIEW_HALF_W / ZOOM
	var half_h := VIEW_HALF_H / ZOOM
	camera.target = player
	camera.min_x = half_w
	camera.max_x = maxf(half_w, level_w - half_w)
	# Anchor so the level's bottom row sits at the bottom of the screen
	# (empty space shows as "sky" above, not void below).
	camera.fixed_y = level_h - half_h

func _spawn(scene_path: String, pos: Vector2) -> Node2D:
	if not ResourceLoader.exists(scene_path):
		return null
	var packed: PackedScene = load(scene_path)
	var inst := packed.instantiate() as Node2D
	inst.position = pos
	entities.add_child(inst)
	return inst
