extends Node2D
## Independent facade, surface, decal/prop, traffic, pickup and HUD canvases.
const Layer = preload("res://scripts/cycling/presentation_layer.gd")
const Districts = preload("res://scripts/cycling/districts.gd")
const Layout = preload("res://scripts/cycling/presentation_layout.gd")
var game
var font: Font = ThemeDB.fallback_font
var city_texture: Texture2D
var atlas_frames: Array[Texture2D] = []
var layers: Array[Node2D] = []
var render_distance: float = 0.0
var street_materials: Texture2D
var street_sprites: Texture2D
var hud_fade: GradientTexture2D
var debug_contacts: bool = false
var hud_style: StyleBoxFlat = make_hud_style()
const REGIONS: Dictionary = {
	"player": Rect2(106, 90, 350, 365),
	"cyclist": Rect2(583, 91, 359, 365),
	"car": Rect2(992, 246, 520, 205),
	"bus": Rect2(40, 628, 680, 198),
	"pedestrian": Rect2(754, 548, 200, 325),
	"barrier": Rect2(1076, 607, 382, 257)
}

const ART_WIDTHS: Dictionary = {"player":82.0,"cyclist":82.0,"car":110.0,"bus":170.0,"pedestrian":40.0,"barrier":55.0}

const INK := Color("#eee4cd")
const MUTED := Color("#b6b3a4")
const GOLD := Color("#dfb552")
const GREEN := Color("#a9c495")

const MATERIAL_REGIONS: Array[Rect2] = [Rect2(0,90,1254,224),Rect2(0,505,1254,224),Rect2(0,900,1254,224)]
const STREET_REGIONS: Dictionary = {"bread":Rect2(96,102,485,323),"pastry":Rect2(697,113,473,309),"planter":Rect2(88,530,511,334),"chair":Rect2(795,487,319,406),"curb":Rect2(64,1030,542,88),"cycle":Rect2(716,962,476,220)}
const CITY_BASELINES: Array[float] = [252.0,558.0,778.0,1018.0]
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
	street_materials = load("res://assets/cycling/street-materials.png")
	street_sprites = load("res://assets/cycling/street-sprites.png")
	hud_fade = GradientTexture2D.new()
	hud_fade.width = 8
	hud_fade.height = 81
	hud_fade.fill_from = Vector2(0,0)
	hud_fade.fill_to = Vector2(0,1)
	hud_fade.gradient = Gradient.new()
	hud_fade.gradient.set_color(0,Color(0.025,0.025,0.02,0.58))
	hud_fade.gradient.set_color(1,Color(0.025,0.025,0.02,0.0))
	for i in 6:
		var layer := Layer.new()
		layer.host = self
		layer.layer_id = i
		add_child(layer)
		layers.append(layer)
	var key_material := ShaderMaterial.new()
	key_material.shader = load("res://scripts/cycling/chroma_key.gdshader")
	layers[3].material = key_material
	var street_key := ShaderMaterial.new()
	street_key.shader = load("res://scripts/cycling/street_key.gdshader")
	for i in [2,4]: layers[i].material = street_key

func _process(_delta: float) -> void:
	render_distance = game.distance
	if game.state == game.RunState.RUNNING:
		render_distance = lerpf(game.previous_distance, game.distance, clampf(Engine.get_physics_interpolation_fraction(),0.0,1.0))
	for layer in layers:
		layer.queue_redraw()

func text(c: Node2D, at: Vector2, message: String, size: int = 18, tint: Color = INK) -> void:
	c.draw_string(font, at, message, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, tint)

func lane_y(value: float) -> float:
	return Layout.lane_y(value)

func district(tile: int) -> int:
	return Districts.visual_district(tile)

func render_layer(c: Node2D, layer_id: int) -> void:
	match layer_id:
		0: draw_facades(c)
		1: draw_surfaces(c)
		2: draw_street_details(c)
		3: draw_traffic(c)
		4: draw_food(c)
		5:
			draw_hud(c)
			draw_overlay(c)
			if debug_contacts: draw_contacts(c)

func draw_facades(c: Node2D) -> void:
	c.draw_rect(Rect2(0,0,960,81),Color("#3a372e"))
	if not city_texture: return
	var scroll: float = render_distance * game.pixels_per_metre * Districts.BUILDING_RATE
	var first: int = int(floor(scroll/Districts.TILE_WIDTH))
	for tile in range(first,first+3):
		var left: float = tile*Districts.TILE_WIDTH-scroll
		var area: int = district(tile)
		var first_tile: int = [0,2,4,5][area]
		var source := Rect2(fposmod((tile-first_tile)*480.0,960.0),CITY_BASELINES[area]-54.0,480.0,54.0)
		c.draw_texture_rect_region(city_texture,Rect2(left,0,720,81),source,Color("#d1c6b1"))

func draw_surfaces(c: Node2D) -> void:
	var scroll: float = render_distance*game.pixels_per_metre
	var first: int = int(floor(scroll/512.0))
	for lane_id in 5:
		var source: Rect2 = MATERIAL_REGIONS[0 if lane_id < 3 else lane_id-2]
		for tile in range(first,first+3):
			var left: float = tile*512.0-scroll
			# Alternate mirrored material tiles have matching pixels at every join.
			var mirrored: bool = posmod(tile,2) == 1
			c.draw_set_transform(Vector2(left+512.0 if mirrored else left,Layout.lane_top(lane_id)),0,Vector2(-1 if mirrored else 1,1))
			c.draw_texture_rect_region(street_materials,Rect2(0,0,512,Layout.LANE_HEIGHT),source,Color("#c8bba4"))
			c.draw_set_transform(Vector2.ZERO)
		# Shadow lives within its lane and never changes the playable band.
		c.draw_line(Vector2(0,Layout.lane_top(lane_id)+6),Vector2(960,Layout.lane_top(lane_id)+6),Color(0,0,0,0.25),2)

func street_art(c: Node2D, kind: String, rect: Rect2, tint: Color = Color.WHITE) -> void:
	c.draw_texture_rect_region(street_sprites,rect,STREET_REGIONS[kind],tint)

func draw_street_details(c: Node2D) -> void:
	var scroll: float = render_distance*game.pixels_per_metre
	var first: int = int(floor(scroll/144.0))
	for tile in range(first,first+8):
		var x: float = tile*144.0-scroll
		for lane_id in 5:
			street_art(c,"curb",Rect2(x,Layout.lane_top(lane_id),145,6),Color("#b5aa91"))
	# Worn paint dashes: separate overlay, with deterministic chips.
	for tile in range(first,first+8):
		var x: float = tile*144.0-scroll
		for lane_id in 3:
			var y: float = Layout.lane_top(lane_id)+Layout.LANE_HEIGHT*0.53
			var tint: Color = Color("#a48d46") if lane_id == 0 else Color("#b8af98")
			for chip in 10:
				var fade: float = 0.27+float(posmod(tile*17+chip*7+lane_id,9))*0.035
				tint.a = fade
				c.draw_rect(Rect2(x+chip*4,y+float(posmod(chip,3))*0.3,3.5,2.2),tint)
	var mark_first: int = int(floor(scroll/288.0))
	for tile in range(mark_first,mark_first+5):
		street_art(c,"cycle",Rect2(tile*288.0-scroll,Layout.lane_top(3)+36,52,24),Color(0.85,0.81,0.70,0.58))
	# Sparse illustrated furniture. All pixels stay above the gameplay strip.
	var prop_first: int = int(floor(scroll/720.0))
	for tile in range(prop_first,prop_first+3):
		var x: float = tile*720.0-scroll
		street_art(c,"planter",Rect2(x+490,48,44,29),Color("#b6b099"))
		street_art(c,"chair",Rect2(x+175,45,25,32),Color("#c9bea5"))

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
			var at := Vector2(Layout.PLAYER_X,item.y)
			if game.rider.sheltered:
				c.draw_colored_polygon(PackedVector2Array([at+Vector2(-42,-5),at+Vector2(95,-5),at+Vector2(95,-52),at+Vector2(-42,-22)]),Color(0.66,0.8,0.57,0.2))
			if game.rider.cooldown_left <= 0 or int(game.elapsed*14)%2 == 0:
				sprite_art(c,"player",at,game.rider.animation_phase)

		else:
			var x: float = Layout.world_x(actor.distance,render_distance,game.pixels_per_metre)
			if actor.definition.visual_scene != null:
				if not is_instance_valid(actor.visual):
					actor.visual = actor.definition.visual_scene.instantiate()
					layers[3].add_child(actor.visual)
				actor.visual.position = Vector2(x,item.y)
			else:
				var cadence: float = absf(actor.definition.speed)/12.0*6.0 if actor.definition.kind == "cyclist" else 4.0 if actor.definition.kind == "pedestrian" else 2.0
				sprite_art(c,actor.definition.kind,Vector2(x,item.y),game.elapsed*cadence)

func draw_hud(c: Node2D) -> void:
	c.draw_texture_rect(hud_fade,Rect2(0,0,960,81),false)
	# Transparent bordered panels float over the facade and fade behind the text.
	for panel in [Rect2(10,8,218,43),Rect2(236,8,204,43),Rect2(448,8,211,43),Rect2(667,8,229,43),Rect2(904,8,46,43)]:
		c.draw_style_box(hud_style,panel)
	text(c,Vector2(42,28),"CAMPUS  %.2f km" % (maxf(0,game.route_length-game.distance)/1000.0),18,INK)
	text(c,Vector2(20,44),"%d:%02d   %d km/h" % [int(game.elapsed)/60,int(game.elapsed)%60,int(game.rider.speed*3.6)],11,MUTED)
	text(c,Vector2(246,28),"ENERGY  %d%%" % int(game.rider.energy),16,INK)
	c.draw_rect(Rect2(246,36,183,6),Color("#443d2d"))
	c.draw_rect(Rect2(246,36,183*game.rider.energy/100.0,6),GREEN if game.rider.recovering else GOLD)
	var effort: String = "RECOVER %.1fs" % game.rider.recovery_left if game.rider.recovering else "BOOST %.1fs" % game.rider.boost_left if game.rider.boost_left > 0.0 else "BOOST  K / B" if game.rider.boost_ready() else "BOOST NEEDS 20"
	text(c,Vector2(484,35),effort,16,GREEN if game.rider.recovering else INK)
	text(c,Vector2(705,28),game.wind.phase(),15,INK)
	var wind_detail: String = game.wind.warning() if game.wind.warning() != "" else "DRAFT: SHELTERED" if game.rider.sheltered else ""
	text(c,Vector2(677,44),wind_detail,10,MUTED)
	draw_hud_icon(c,"pin",Vector2(27,28))
	draw_hud_icon(c,"cap",Vector2(466,28))
	draw_hud_icon(c,"wind",Vector2(683,24))
	draw_hud_icon(c,"menu",Vector2(927,25))
	text(c,Vector2(911,44),"ESC/C",9,MUTED)
	if game.food.feedback_left > 0.0:
		c.draw_style_box(hud_style,Rect2(374,55,212,23))
		text(c,Vector2(389,72),game.food.feedback,14,GOLD)
	c.draw_rect(Rect2(0,79,960*clampf(game.distance/game.route_length,0,1),2),GOLD)

func make_hud_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05,0.055,0.04,0.36)
	style.border_color = Color(0.66,0.60,0.47,0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

func draw_overlay(c: Node2D) -> void:
	if game.state == game.RunState.RUNNING: return
	if game.state == game.RunState.CRASHED:
		c.draw_rect(Rect2(0,0,960,540),Color(0.65,0.2,0.12,0.18))
		return
	c.draw_rect(Rect2(0,Layout.CITY_HEIGHT,960,540-Layout.CITY_HEIGHT),Color(0.06,0.1,0.11,0.65))
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
		game.RunState.RESULTS:
			title = "END OF THE ROAD"
			detail = "%d m ridden / Best %d m" % [int(game.distance),int(game.best_distance)]
			action = "ENTER / SPACE  TRY AGAIN"
		game.RunState.SUCCESS:
			title = "MADE IT TO UNIVERSITY!"
			detail = "1.5 km in %d:%02d. You made it to class." % [int(game.elapsed)/60,int(game.elapsed)%60]
			action = "ENTER / SPACE  RIDE AGAIN"
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
		var at := Vector2(Layout.world_x(item.distance,render_distance,game.pixels_per_metre),lane_y(item.lane)-24.0)
		if at.x < -60.0 or at.x > 1020.0: continue
		street_art(c,item.kind,Rect2(at-Vector2(20,15),Vector2(40,30)))
		text(c,at+Vector2(-12,27),"+20" if item.kind == "bread" else "+30",12,GOLD)

func draw_contacts(c: Node2D) -> void:
	for lane_id in 5:
		c.draw_line(Vector2(0,lane_y(lane_id)),Vector2(960,lane_y(lane_id)),Color(0,1,1,0.4),1)
	c.draw_rect(Layout.contact_rect(game.distance,game.rider.lane_position,game.rider.contact_size,render_distance,game.pixels_per_metre),Color.CYAN,false,1)
	for actor in game.traffic.actors:
		c.draw_rect(Layout.contact_rect(actor.distance,actor.definition.lane,actor.definition.contact_size,render_distance,game.pixels_per_metre),Color.RED if actor.lethal() else Color.YELLOW,false,1)
	for item in game.food.items:
		c.draw_rect(Layout.contact_rect(item.distance,item.lane,Vector2(7,0.6),render_distance,game.pixels_per_metre),Color.GREEN,false,1)

func draw_hud_icon(c: Node2D, kind: String, at: Vector2) -> void:
	match kind:
		"pin":
			c.draw_arc(at-Vector2(0,4),6.5,PI,TAU,16,INK,2,true)
			c.draw_polyline(PackedVector2Array([at+Vector2(-6.5,-4),at+Vector2(0,12),at+Vector2(6.5,-4)]),INK,2,true)
			c.draw_circle(at-Vector2(0,4),2.2,INK)
		"cap":
			c.draw_colored_polygon(PackedVector2Array([at+Vector2(-13,-2),at+Vector2(0,-8),at+Vector2(13,-2),at+Vector2(0,4)]),INK)
			c.draw_polyline(PackedVector2Array([at+Vector2(-7,3),at+Vector2(-7,7),at+Vector2(0,10),at+Vector2(7,7),at+Vector2(7,3)]),INK,2,true)
		"wind":
			for i in 3:
				c.draw_line(at+Vector2(-10,i*5-4),at+Vector2(8-i*3,i*5-4),INK,1.5,true)
			c.draw_arc(at+Vector2(8,-7),3,-PI/2,PI/2,8,INK,1.5,true)
		"menu":
			for i in 3: c.draw_line(at+Vector2(-9,i*5-5),at+Vector2(9,i*5-5),INK,1.6,true)

func _unhandled_input(event: InputEvent) -> void:
	# The illustrated menu icon opens the existing pause overlay, not a new menu.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Rect2(904,8,46,43).has_point(event.position):
			if game.state == game.RunState.RUNNING: game.state = game.RunState.PAUSED
			elif game.state == game.RunState.PAUSED: game.state = game.RunState.RUNNING
			get_viewport().set_input_as_handled()
