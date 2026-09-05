extends Node2D
## Three independent canvases: city/road, keyed traffic, unkeyed interface.
const Layer = preload("res://scripts/cycling/presentation_layer.gd")
const Districts = preload("res://scripts/cycling/districts.gd")
const CityDetails = preload("res://scripts/cycling/city_details.gd")
var game
var font: Font = ThemeDB.fallback_font
var city_texture: Texture2D
var atlas_frames: Array[Texture2D] = []
var layers: Array[Node2D] = []
var render_distance: float = 0.0
var bread_style: StyleBoxFlat = food_bread_style()
const REGIONS: Dictionary = {
	"player": Rect2(106, 90, 350, 365),
	"cyclist": Rect2(583, 91, 359, 365),
	"car": Rect2(992, 246, 520, 205),
	"bus": Rect2(40, 628, 680, 198),
	"pedestrian": Rect2(754, 548, 200, 325),
	"barrier": Rect2(1076, 607, 382, 257)
}

const ART_WIDTHS: Dictionary = {"player":82.0,"cyclist":82.0,"car":110.0,"bus":170.0,"pedestrian":40.0,"barrier":55.0}
const LANE_Y: Array[float] = [244.0,314.0,384.0,454.0,524.0]
const INK := Color("#eee4cd")
const MUTED := Color("#b6b3a4")
const GOLD := Color("#dfb552")
const GREEN := Color("#a9c495")
const LABELS: Array[String] = ["BUS","CAR","CAR","BIKE","WALK"]
const CITY_REGIONS: Array[Rect2] = [Rect2(0,0,1536,300),Rect2(0,300,1536,260),Rect2(0,560,1536,220),Rect2(0,780,1536,244)]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var original := load("res://assets/cycling/city-districts.png") as Texture2D
	if original:
		var pixels := original.get_image()
		pixels.generate_mipmaps()
		city_texture = ImageTexture.create_from_image(pixels)
	for path in ["res://assets/cycling/traffic-frame-1.png","res://assets/cycling/traffic-frame-2.png"]:
		var texture := load(path) as Texture2D
		if texture:
			atlas_frames.append(texture)
	for i in 3:
		var layer := Layer.new()
		layer.host = self
		layer.layer_id = i
		add_child(layer)
		layers.append(layer)
	var key_material := ShaderMaterial.new()
	key_material.shader = load("res://scripts/cycling/chroma_key.gdshader")
	layers[1].material = key_material

func _process(_delta: float) -> void:
	render_distance = game.distance
	if game.state == game.RunState.RUNNING:
		render_distance = lerpf(game.previous_distance, game.distance, clampf(Engine.get_physics_interpolation_fraction(),0.0,1.0))
	for layer in layers:
		layer.queue_redraw()

func text(c: Node2D, at: Vector2, message: String, size: int = 18, tint: Color = INK) -> void:
	c.draw_string(font, at, message, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, tint)

func lane_y(value: float) -> float:
	return LANE_Y[0] + clampf(value,0.0,4.0)*70.0

func district(tile: int) -> int:
	return Districts.visual_district(tile)

func render_layer(c: Node2D, layer_id: int) -> void:
	match layer_id:
		0: draw_world(c)
		1: draw_traffic(c)
		2:
			draw_food(c)
			draw_hud(c)
			draw_overlay(c)

func draw_world(c: Node2D) -> void:
	c.draw_rect(Rect2(0,0,960,540),Color("#aab4b1"))
	# Sky moves at 5% of road velocity; global indices keep cloud identity stable.
	var sky_scroll: float = render_distance * game.pixels_per_metre * 0.05
	var cloud_first: int = int(floor(sky_scroll/240.0))
	for i in range(cloud_first,cloud_first+6):
		var x: float = i*240.0-sky_scroll
		c.draw_circle(Vector2(x,84),35,Color("#c2c8be"))
		c.draw_circle(Vector2(x+43,90),44,Color("#c2c8be"))
	if city_texture:
		var city_scroll: float = render_distance * game.pixels_per_metre * 0.25
		var first: int = int(floor(city_scroll/720.0))
		for tile in range(first,first+3):
			var left: float = tile*720.0-city_scroll
			var region: Rect2 = CITY_REGIONS[district(tile)]
			c.draw_texture_rect_region(city_texture,Rect2(left,70,720,120),region)
	c.draw_rect(Rect2(0,186,960,4),Color("#72776c"))
	var colors: Array[Color] = [Color("#55564f"),Color("#484c49"),Color("#51534d"),Color("#995f4b"),Color("#9c998b")]
	var road_scroll: float = render_distance * game.pixels_per_metre
	var dash_first: int = int(floor(road_scroll/96.0))
	for lane_id in 5:
		var top: float = 190.0+lane_id*70.0
		c.draw_rect(Rect2(0,top,960,70),colors[lane_id])
		c.draw_line(Vector2(0,top),Vector2(960,top),Color("#c2b9a1"),2)
		text(c,Vector2(12,top+43),LABELS[lane_id],18,Color("#c8bda2"))
		for dash in range(dash_first,dash_first+12):
			var x: float = dash*96.0-road_scroll
			if lane_id < 4:
				c.draw_line(Vector2(x,top+67),Vector2(x+40,top+67),Color("#b4a98b"),2)
			else:
				c.draw_line(Vector2(x,top),Vector2(x-10,540),Color("#827e70"),1)
	# Roadside planters move with the road, but stay out of the playable lanes.
	var prop_first: int = int(floor(road_scroll/360.0))
	for i in range(prop_first,prop_first+4):
		var x: float = i*360.0-road_scroll
		c.draw_rect(Rect2(x,178,30,10),Color("#665d49"))
		c.draw_circle(Vector2(x+15,171),12,Color("#6e8064"))
	CityDetails.draw(c,self)
	for sign_distance in [1000.0,1300.0]:
		var x: float = 240.0+(sign_distance-render_distance)*game.pixels_per_metre
		if x > -160 and x < 1120:
			c.draw_line(Vector2(x,140),Vector2(x,189),MUTED,3)
			c.draw_rect(Rect2(x-84,115,168,30),Color("#344a47"))
			text(c,Vector2(x-77,136),"UNIVERSITET "+str(int(game.route_length-sign_distance))+" m →",14)

func sprite_art(c: Node2D, kind: String, at: Vector2, phase: float) -> void:
	if atlas_frames.size() != 2: return
	var region: Rect2 = REGIONS[kind]
	var width: float = ART_WIDTHS[kind]
	var height: float = width*region.size.y/region.size.x
	c.draw_texture_rect_region(atlas_frames[int(phase)%2],Rect2(at-Vector2(width/2.0,height),Vector2(width,height)),region)

func draw_traffic(c: Node2D) -> void:
	var items: Array = []
	for actor in game.traffic.actors:
		items.append({"y":lane_y(actor.definition.lane),"actor":actor})
	items.append({"y":lane_y(game.rider.lane_position),"actor":null})
	items.sort_custom(func(a,b): return a.y < b.y)
	for item in items:
		var actor = item.actor
		if actor == null:
			var at := Vector2(240,item.y)
			if game.rider.sheltered:
				c.draw_colored_polygon(PackedVector2Array([at+Vector2(-42,-5),at+Vector2(95,-5),at+Vector2(95,-52),at+Vector2(-42,-22)]),Color(0.66,0.8,0.57,0.2))
			if game.rider.cooldown_left <= 0 or int(game.elapsed*14)%2 == 0:
				sprite_art(c,"player",at,game.rider.animation_phase)
			c.draw_line(at+Vector2(-25,4),at+Vector2(25,4),GOLD,3)
		else:
			var x: float = 240.0+(actor.distance-render_distance)*game.pixels_per_metre
			if actor.definition.visual_scene != null:
				if not is_instance_valid(actor.visual):
					actor.visual = actor.definition.visual_scene.instantiate()
					layers[1].add_child(actor.visual)
				actor.visual.position = Vector2(x,item.y)
			else:
				var cadence: float = absf(actor.definition.speed)/12.0*6.0 if actor.definition.kind == "cyclist" else 4.0 if actor.definition.kind == "pedestrian" else 2.0
				sprite_art(c,actor.definition.kind,Vector2(x,item.y),game.elapsed*cadence)

func draw_hud(c: Node2D) -> void:
	c.draw_rect(Rect2(0,0,960,70),Color("#2a3637"))
	text(c,Vector2(18,25),"LATE FOR LECTURE",19,GOLD)
	text(c,Vector2(18,54),"UNIVERSITY / 1.5 KM",14,MUTED)
	text(c,Vector2(275,27),"%d m LEFT" % int(ceil(maxf(0,game.route_length-game.distance))),24)
	text(c,Vector2(275,54),"%d:%02d  /  %d km/h" % [int(game.elapsed)/60,int(game.elapsed)%60,int(game.rider.speed*3.6)],16,MUTED)
	text(c,Vector2(505,24),"ENERGY %d%% %s" % [int(game.rider.energy),"+" if game.rider.energy_change>0 else "-" if game.rider.energy_change<0 else ""],17)
	c.draw_rect(Rect2(505,36,165,12),Color("#58605a"))
	c.draw_rect(Rect2(505,36,165*game.rider.energy/100.0,12),GREEN if game.rider.recovering else GOLD)
	var effort: String = "RECOVER %.1fs" % game.rider.recovery_left if game.rider.recovering else "BOOST %.1fs" % game.rider.boost_left if game.rider.boost_left > 0.0 else "K / B  BOOST READY" if game.rider.boost_ready() else "BOOST NEEDS 20"
	text(c,Vector2(700,25),effort,16,GREEN if game.rider.recovering or game.rider.sheltered else GOLD)
	text(c,Vector2(700,53),game.wind.warning() if game.wind.warning() != "" else game.wind.phase() + (" / DRAFT" if game.rider.sheltered else ""),13,MUTED)
	c.draw_rect(Rect2(0,67,960*clampf(game.distance/game.route_length,0,1),3),GOLD)

func draw_overlay(c: Node2D) -> void:
	if game.state == game.RunState.RUNNING: return
	if game.state == game.RunState.CRASHED:
		c.draw_rect(Rect2(0,0,960,540),Color(0.65,0.2,0.12,0.18))
		return
	if game.state == game.RunState.RESULTS or game.state == game.RunState.SUCCESS:
		return
	c.draw_rect(Rect2(0,70,960,470),Color(0.06,0.1,0.11,0.65))
	c.draw_rect(Rect2(165,130,630,285),Color("#293638"))
	c.draw_rect(Rect2(165,130,630,285),GOLD,false,2)
	var title: String = "LATE FOR LECTURE"
	var detail: String = "Ride 1.5 km through Copenhagen to university."
	var action: String = "ENTER / SPACE  START     ESC  PAUSE"
	match game.state:
		game.RunState.PAUSED:
			title = "TAKE A BREATHER"
			detail = "Distance, traffic, energy and wind are paused."
			action = "ENTER / SPACE / ESC  RESUME"
		game.RunState.READY:
			pass
	text(c,Vector2(200,180),title,28,GOLD)
	text(c,Vector2(200,221),detail,19)
	text(c,Vector2(200,261),"UP / DOWN or W / S — switch lanes",19)
	text(c,Vector2(200,298),"K / B: 2s boost · costs 20. At zero: 2s recovery.",17,MUTED)
	text(c,Vector2(200,325),"Rugbrød +20 · Danish +30 · Draft blocks headwind drain",15,MUTED)
	text(c,Vector2(200,350),action,20,GOLD)
	text(c,Vector2(200,389),"Click game to focus  |  Handheld: A start / C pause",14,MUTED)
	if game.score_write_error:
		text(c,Vector2(200,408),"Best score could not be saved.",13,MUTED)

func draw_food(c: Node2D) -> void:
	for item in game.food.items:
		var at := Vector2(240.0 + (item.distance - render_distance) * game.pixels_per_metre, lane_y(item.lane) - 24.0)
		if at.x < -60.0 or at.x > 1020.0: continue
		c.draw_circle(at, 24.0, Color("#293638"))
		c.draw_arc(at,24.0,0.0,TAU,32,GOLD,2.0,true)
		if item.kind == "bread":
			# Dark rye slice, crust and pale seeds, in the existing muted palette.
			c.draw_style_box(bread_style,Rect2(at-Vector2(18,13),Vector2(36,27)))
			for seed_at in [Vector2(-10,-5),Vector2(0,4),Vector2(9,-6),Vector2(-9,7),Vector2(11,6)]:
				c.draw_line(at+seed_at,at+seed_at+Vector2(3,-2),Color("#d4bc86"),2.0)
		else:
			# Folded spandauer: flaky corners, golden dough and custard centre.
			var outline := PackedVector2Array()
			var dough := PackedVector2Array()
			for point in [Vector2(-18,-9),Vector2(-10,-17),Vector2(0,-13),Vector2(12,-17),Vector2(19,-5),Vector2(14,0),Vector2(18,11),Vector2(7,18),Vector2(0,14),Vector2(-13,17),Vector2(-18,7),Vector2(-13,0)]:
				outline.append(at+point)
				dough.append(at+point*0.82)
			c.draw_colored_polygon(outline,Color("#975b34"))
			c.draw_colored_polygon(dough,GOLD)
			c.draw_circle(at,7.0,Color("#af713c"))
			c.draw_circle(at,5.0,Color("#edcf82"))
			for offset in [Vector2(-11,-9),Vector2(8,-10),Vector2(-10,9),Vector2(8,10)]:
				c.draw_line(at+offset-Vector2(2,1),at+offset+Vector2(3,-1),INK,2.0,true)
		text(c,at+Vector2(-14,39),"+20" if item.kind == "bread" else "+30",13,GOLD)
	if game.food.feedback_left > 0.0:
		c.draw_rect(Rect2(365,78,230,31),Color("#293638"))
		text(c,Vector2(389,100),game.food.feedback,18,GOLD)

func food_bread_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#735039")
	style.border_color = Color("#412f29")
	style.set_border_width_all(3)
	style.set_corner_radius_all(5)
	return style
