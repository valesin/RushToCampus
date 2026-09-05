extends Node2D
# Parses the current ASCII level into instanced Block / Player / Critter / Door
# scenes, then configures the camera.

const TILE := 32
# Base (zoom 1.0) half-viewport in pixels: 640x360 / 2.
const VIEW_HALF_W := 320.0
const VIEW_HALF_H := 180.0
# Camera zoom: < 1.0 shows MORE of the world (zoomed out).
const ZOOM := 0.6

# Skip template hazards / pickups / platforms while we rebuild as a bike game.
const HIDE_OBSTACLES := true
# Bottom band of the screen (WALK sidewalk). Player feet sit on the
# terracotta bike pavement just above this.
const WALK_HEIGHT_FRAC := 0.30

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
	var spawn_x := TILE * 2.0

	for y in range(rows):
		var line: String = lines[y]
		cols = maxi(cols, line.length())
		for x in range(line.length()):
			var c := line[x]
			var pos := Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
			match c:
				"#":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/Block.tscn", pos)
				"P":
					spawn_x = pos.x
					player = _spawn("res://scenes/Player.tscn", pos)
				"G":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/Critter.tscn", pos)
				"D":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/Door.tscn", pos)
				"-":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/MovingPlatformH.tscn", pos)
				"|":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/MovingPlatformV.tscn", pos)
				"/":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/SlopeUp.tscn", pos)
				"\\":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/SlopeDown.tscn", pos)
				"o":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/BouncePad.tscn", pos)
				"x":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/CrumbleBlock.tscn", pos)
				"^":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/Spike.tscn", pos)
				"s":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/Sawblade.tscn", pos)
				"B":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/Boss.tscn", pos)
				"c":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/Coin.tscn", pos)
				"h":
					if not HIDE_OBSTACLES:
						_spawn("res://scenes/Heart.tscn", pos)
				_:
					pass

	var level_w := cols * TILE
	var level_h := rows * TILE
	var view_w := VIEW_HALF_W / ZOOM * 2.0
	var view_h := VIEW_HALF_H / ZOOM * 2.0
	var half_w := view_w * 0.5
	var half_h := view_h * 0.5
	# Bike pavement sits just above the sidewalk at the bottom of the screen.
	var bike_y := level_h - view_h * WALK_HEIGHT_FRAC

	if HIDE_OBSTACLES:
		_add_invisible_floor(level_w, bike_y)
		if player != null:
			player.position = Vector2(spawn_x, bike_y)
	elif player != null:
		var buddy := _spawn("res://scenes/SideCharacter.tscn", player.position + Vector2(48, 64))
		if buddy != null and buddy.has_method("face"):
			buddy.face(1)

	if player != null and "kill_y" in player:
		player.kill_y = level_h + 200.0

	camera.zoom = Vector2(ZOOM, ZOOM)
	camera.target = player
	camera.min_x = half_w
	camera.max_x = maxf(half_w, level_w - half_w)
	# Anchor so the level's bottom row sits at the bottom of the screen.
	camera.fixed_y = level_h - half_h
	_fit_background(view_w, view_h)

func _fit_background(view_w: float, view_h: float) -> void:
	var bg := get_node_or_null("Camera2D/Background") as Sprite2D
	if bg == null or bg.texture == null:
		return
	var sz := bg.texture.get_size()
	if sz.x <= 0.0 or sz.y <= 0.0:
		return
	# Cover the camera view and pin the art's bottom edge to the sidewalk.
	var s := maxf(view_w / sz.x, view_h / sz.y)
	bg.centered = false
	bg.scale = Vector2(s, s)
	bg.position = Vector2(-view_w * 0.5, view_h * 0.5 - sz.y * s)

func _add_invisible_floor(width: float, y: float) -> void:
	var body := StaticBody2D.new()
	body.name = "BikeLaneFloor"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(width * 0.5, y)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width + 400.0, 32.0)
	shape.shape = rect
	shape.position = Vector2(0, 16.0)
	body.add_child(shape)
	entities.add_child(body)

func _spawn(scene_path: String, pos: Vector2) -> Node2D:
	if not ResourceLoader.exists(scene_path):
		return null
	var packed: PackedScene = load(scene_path)
	var inst := packed.instantiate() as Node2D
	inst.position = pos
	entities.add_child(inst)
	return inst
