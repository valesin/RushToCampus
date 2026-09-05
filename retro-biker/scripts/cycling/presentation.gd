extends Node2D
## Prototype presentation. Replace visuals independently of collision definitions.
var game
var font: Font = ThemeDB.fallback_font
var city_texture: Texture2D
var atlas_frames: Array[Texture2D] = []
const REGIONS: Dictionary = {
	"player": Rect2(106, 90, 350, 365),
	"cyclist": Rect2(583, 91, 359, 365),
	"car": Rect2(992, 246, 520, 205),
	"bus": Rect2(40, 628, 680, 198),
	"pedestrian": Rect2(754, 548, 200, 325),
	"barrier": Rect2(1076, 607, 382, 257)
}
const ART_WIDTHS: Dictionary = {"player": 58.0, "cyclist": 58.0, "car": 60.0, "bus": 112.0, "pedestrian": 29.0, "barrier": 37.0}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	city_texture = load("res://assets/cycling/copenhagen-buildings.png")
	for path in ["res://assets/cycling/traffic-frame-1.png", "res://assets/cycling/traffic-frame-2.png"]:
		var texture := load(path) as Texture2D
		if texture != null:
			atlas_frames.append(texture)
	if atlas_frames.size() != 2:
		atlas_frames.clear()
	var key_material := ShaderMaterial.new()
	key_material.shader = load("res://scripts/cycling/chroma_key.gdshader")
	material = key_material

func sprite_art(kind: String, at: Vector2) -> void:
	if atlas_frames.is_empty():
		return
	var region: Rect2 = REGIONS[kind]
	var width: float = ART_WIDTHS[kind]
	var height: float = width * region.size.y / region.size.x
	var frame: int = int(game.elapsed * (4.0 if kind in ["player", "cyclist", "pedestrian"] else 2.0)) % 2
	draw_texture_rect_region(atlas_frames[frame], Rect2(at - Vector2(width / 2.0, height), Vector2(width, height)), region)

const INK := Color("#eee4cd")
const MUTED := Color("#b6b3a4")
const GOLD := Color("#dfb552")
const GREEN := Color("#a9c495")
const LANE_Y: Array[float] = [273.0, 330.0, 387.0, 444.0, 510.0]
const LABELS: Array[String] = ["BUS", "CAR", "CAR", "BIKE", "WALK"]
const BUILDINGS: Array[Color] = [Color("#9e7758"), Color("#b59461"), Color("#637c83"), Color("#aa7053"), Color("#b4a486"), Color("#8b9389")]

func text(at: Vector2, message: String, size: int = 16, tint: Color = INK) -> void:
	draw_string(font, at, message, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, tint)

func lane_y(value: float) -> float:
	var low: int = clampi(int(floor(value)), 0, 4)
	return lerpf(LANE_Y[low], LANE_Y[mini(4, low + 1)], value - low)

func _draw() -> void:
	if game == null:
		return
	draw_rect(Rect2(0, 0, 960, 540), Color("#a6aba6"))
	_draw_city()
	_draw_road()
	# Render in lane order; lower contact points correctly overlap upper sprites.
	for lane_id in range(5):
		for actor in game.traffic.actors:
			if actor.definition.lane == lane_id:
				_draw_actor(actor)
		if int(round(game.rider.lane_position)) == lane_id:
			_draw_player()
	_draw_hud()
	_draw_overlay()

func _draw_city() -> void:
	if city_texture != null:
		var width: float = 720.0
		var offset: float = fposmod(game.distance * 1.6, width)
		for tile in range(-1, 3):
			var rect := Rect2(tile * width - offset, 66, width, 166)
			draw_texture_rect(city_texture, rect, false)
		draw_rect(Rect2(0, 225, 960, 8), Color("#535951"))
		return
	draw_rect(Rect2(0, 66, 960, 160), Color("#b7bab2"))
	for cloud in range(5):
		var x: float = fposmod(cloud * 237.0 - game.distance * 0.3, 1200.0) - 120.0
		draw_circle(Vector2(x, 91), 46, Color("#c7c8be"))
		draw_circle(Vector2(x + 48, 98), 40, Color("#c7c8be"))
	var offset: float = fposmod(game.distance * 1.6, 92.0)
	for i in range(-1, 12):
		var x: float = i * 92.0 - offset
		var h: float = 85.0 + (posmod(i, 4) * 13.0)
		var top: float = 226.0 - h
		draw_rect(Rect2(x + 2, top, 88, h), BUILDINGS[posmod(i, BUILDINGS.size())])
		draw_colored_polygon(PackedVector2Array([Vector2(x, top), Vector2(x + 46, top - 25), Vector2(x + 92, top)]), Color("#54554c"))
		for row in range(3):
			for col in range(4):
				var p := Vector2(x + 10 + col * 20, top + 12 + row * 24)
				draw_rect(Rect2(p, Vector2(10, 15)), Color("#ded7bf"))
				draw_rect(Rect2(p + Vector2(2, 2), Vector2(6, 11)), Color("#4c6164"))
		draw_rect(Rect2(x + 10, 207, 67, 17), Color("#55584b"))
		text(Vector2(x + 15, 220), ["KAFFE", "CYKLER", "BAGERI"][posmod(i, 3)], 11)
	draw_rect(Rect2(0, 225, 960, 8), Color("#535951"))

func _draw_road() -> void:
	var colors: Array[Color] = [Color("#55564f"), Color("#484c49"), Color("#51534d"), Color("#995f4b"), Color("#9c998b")]
	for i in range(5):
		var top: float = 233.0 + i * 58.0
		draw_rect(Rect2(0, top, 960, 58 if i < 4 else 75), colors[i])
		draw_line(Vector2(0, top), Vector2(960, top), Color("#c2b9a1"), 2)
		text(Vector2(15, top + 35), LABELS[i], 16, Color("#c8bda2"))
		var offset: float = fposmod(game.distance * game.pixels_per_metre, 96.0)
		for dash in range(-1, 12):
			var x: float = dash * 96.0 - offset
			if i < 4:
				draw_line(Vector2(x, top + 54), Vector2(x + 40, top + 54), Color("#b4a98b"), 2)
			else:
				draw_line(Vector2(x, top), Vector2(x - 10, 540), Color("#827e70"), 1)
				draw_line(Vector2(0, 521), Vector2(960, 521), Color("#827e70"), 1)

func _draw_player() -> void:
	var x: float = 240.0
	var y: float = lane_y(game.rider.lane_position)
	if game.rider.sheltered:
		draw_colored_polygon(PackedVector2Array([Vector2(x - 30, y - 8), Vector2(x + 72, y - 8), Vector2(x + 72, y - 45), Vector2(x - 30, y - 30)]), Color(0.66, 0.8, 0.57, 0.20))
	if game.rider.cooldown_left <= 0.0 or int(game.elapsed * 14.0) % 2 == 0:
		sprite_art("player", Vector2(x, y))
	draw_line(Vector2(x, y + 5), Vector2(x + 20, y + 5), GOLD, 3)

func _draw_actor(actor) -> void:
	var x: float = 240.0 + (actor.distance - game.distance) * game.pixels_per_metre
	var y: float = lane_y(float(actor.definition.lane))
	if actor.definition.visual_scene != null:
		if not is_instance_valid(actor.visual):
			actor.visual = actor.definition.visual_scene.instantiate()
			add_child(actor.visual)
		actor.visual.position = Vector2(x, y)
		return
	if not atlas_frames.is_empty():
		sprite_art(actor.definition.kind, Vector2(x, y))
		return
	match actor.definition.kind:
		"cyclist":
			draw_bike(Vector2(x, y), GREEN, false)
		"pedestrian":
			draw_circle(Vector2(x, y - 35), 6, Color("#d3bba0"))
			draw_line(Vector2(x, y - 27), Vector2(x, y - 13), Color("#3e5661"), 12)
			draw_line(Vector2(x, y - 13), Vector2(x - 10, y), INK, 3)
			draw_line(Vector2(x, y - 13), Vector2(x + 7, y), INK, 3)
			text(Vector2(x - 11, y - 47), "<", 15)
		"barrier":
			draw_rect(Rect2(x - 16, y - 29, 32, 20), Color("#d3c4a7"))
			for k in range(3):
				draw_line(Vector2(x - 13 + k * 11, y - 11), Vector2(x - 5 + k * 11, y - 27), Color("#ae593f"), 5)
			draw_line(Vector2(x - 13, y - 10), Vector2(x - 13, y), INK, 3)
			draw_line(Vector2(x + 13, y - 10), Vector2(x + 13, y), INK, 3)
		_:
			var is_bus: bool = actor.definition.kind == "bus"
			var width: float = 108.0 if is_bus else 52.0
			var height: float = 43.0 if is_bus else 27.0
			var tint: Color = GOLD if is_bus else Color("#91a0a0")
			draw_rect(Rect2(x - width / 2, y - height, width, height - 6), tint)
			draw_rect(Rect2(x - width / 2 + 4, y - height + 4, width - 8, 13), Color("#34454a"))
			draw_circle(Vector2(x - width * 0.32, y - 5), 7, Color("#272e2e"))
			draw_circle(Vector2(x + width * 0.32, y - 5), 7, Color("#272e2e"))
			draw_line(Vector2(x - width / 2, y - 13), Vector2(x - width / 2 + 3, y - 13), INK, 4)
			text(Vector2(x - 9, y - height - 5), "<", 16)
			if is_bus:
				text(Vector2(x - 15, y - 12), "5A", 12, Color("#34372f"))

func draw_bike(at: Vector2, jacket: Color, player: bool) -> void:
	var rear: Vector2 = at + Vector2(-18, -10)
	var front: Vector2 = at + Vector2(19, -10)
	for wheel in [rear, front]:
		draw_circle(wheel, 10, Color("#303735"))
		draw_arc(wheel, 9, 0, TAU, 20, INK, 1.4)
		var spin: float = game.distance * 2.0
		draw_line(wheel - Vector2(cos(spin), sin(spin)) * 8, wheel + Vector2(cos(spin), sin(spin)) * 8, MUTED, 1)
	var pedal: Vector2 = at + Vector2(-1, -10)
	var saddle: Vector2 = at + Vector2(-8, -24)
	var handle: Vector2 = at + Vector2(12, -28)
	draw_polyline(PackedVector2Array([rear, saddle, pedal, rear, handle, front, pedal, handle]), jacket, 2)
	draw_line(saddle + Vector2(-5, 0), saddle + Vector2(5, 0), INK, 3)
	draw_line(handle, handle + Vector2(7, -3), INK, 2)
	draw_line(at + Vector2(-9, -33), at + Vector2(-1, -45), jacket, 10)
	draw_circle(at + Vector2(4, -51), 5, Color("#d8bda0"))
	draw_line(at + Vector2(-1, -43), handle, jacket, 4)
	draw_line(at + Vector2(-8, -30), at + Vector2(2, -22), Color("#303f44"), 5)
	draw_line(at + Vector2(2, -22), pedal, Color("#303f44"), 4)
	if player:
		draw_rect(Rect2(at + Vector2(-18, -44), Vector2(8, 15)), Color("#4c5144"))

func _draw_hud() -> void:
	draw_rect(Rect2(0, 0, 960, 66), Color("#2a3637"))
	text(Vector2(20, 24), "LATE FOR LECTURE", 17, GOLD)
	text(Vector2(20, 48), "COPENHAGEN / ENDLESS COMMUTE", 11, MUTED)
	text(Vector2(285, 25), "%04d m" % int(game.distance), 23)
	text(Vector2(286, 48), "BEST  %d m" % int(maxf(game.best_distance, game.distance)), 12, MUTED)
	text(Vector2(480, 23), "ENERGY  %d%%" % int(game.rider.energy), 14)
	draw_rect(Rect2(480, 35, 160, 10), Color("#58605a"))
	draw_rect(Rect2(480, 35, 160 * game.rider.energy / 100.0, 10), GREEN if game.rider.sheltered else GOLD)
	text(Vector2(685, 25), game.wind.phase(), 17)
	var detail: String = game.wind.warning()
	if game.rider.sheltered:
		detail = "SHELTERED"
	elif game.rider.cooldown_left > 0.0:
		detail = "BUMP — KEEP RIDING"
	text(Vector2(685, 48), detail, 11, GREEN if game.rider.sheltered else MUTED)

func _draw_overlay() -> void:
	if game.state == game.RunState.RUNNING:
		return
	if game.state == game.RunState.CRASHED:
		draw_rect(Rect2(0, 0, 960, 540), Color(0.65, 0.2, 0.12, 0.18))
		return
	draw_rect(Rect2(0, 66, 960, 474), Color(0.06, 0.1, 0.11, 0.70))
	draw_rect(Rect2(185, 140, 590, 270), Color("#293638"))
	draw_rect(Rect2(185, 140, 590, 270), GOLD, false, 2)
	match game.state:
		game.RunState.READY:
			text(Vector2(225, 189), "LATE FOR LECTURE", 31, GOLD)
			text(Vector2(225, 225), "How far can you ride through Copenhagen?", 18)
			text(Vector2(225, 264), "UP / DOWN or W / S — switch lanes", 17)
			text(Vector2(225, 293), "Follow bikes for shelter. Avoid cars and barriers.", 16, MUTED)
			text(Vector2(225, 345), "ENTER / SPACE  START     ESC  PAUSE", 20, GOLD)
			text(Vector2(225, 384), "Click the game to focus  |  Handheld: A start / C pause", 12, MUTED)
		game.RunState.PAUSED:
			text(Vector2(225, 202), "TAKE A BREATHER", 30, GOLD)
			text(Vector2(225, 266), "Distance, traffic and wind are paused.", 18)
			text(Vector2(225, 342), "ENTER / SPACE / ESC  RESUME", 21, GOLD)
		game.RunState.RESULTS:
			text(Vector2(225, 193), "END OF THE ROAD", 30, GOLD)
			text(Vector2(225, 244), "%d METRES    /    BEST %d" % [int(game.distance), int(game.best_distance)], 25)
			text(Vector2(225, 285), "Watch out for " + game.last_hit.to_lower() + " traffic.", 16, MUTED)
			text(Vector2(225, 343), "ENTER / SPACE  RIDE AGAIN", 23, GOLD)
			if game.score_write_error:
				text(Vector2(225, 384), "Best score could not be saved on this device.", 12, MUTED)
