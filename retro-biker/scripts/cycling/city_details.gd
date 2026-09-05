extends RefCounted
## Decorative street furniture stays above y190; no gameplay colliders.
const Districts = preload("res://scripts/cycling/districts.gd")
const IRON := Color("#414a46")
const STONE := Color("#b2ac95")
const BRICK := Color("#80634e")
const LEAF := Color("#6e8064")

static func bicycle(c: Node2D, x: float, y: float) -> void:
	for offset in [0.0,19.0]:
		c.draw_arc(Vector2(x+offset,y),7,0,TAU,16,IRON,1.6,true)
	c.draw_polyline(PackedVector2Array([Vector2(x,y),Vector2(x+7,y-12),Vector2(x+19,y),Vector2(x+6,y),Vector2(x+13,y-12),Vector2(x+7,y-12)]),IRON,1.6,true)
	c.draw_line(Vector2(x+13,y-12),Vector2(x+15,y-18),IRON,1.6)
	c.draw_line(Vector2(x+13,y-18),Vector2(x+19,y-18),IRON,1.6)

static func draw(c: Node2D, host) -> void:
	var scroll: float = host.render_distance * host.game.pixels_per_metre
	var first: int = int(floor(scroll/720.0))
	for id in range(first, first+3):
		var x: float = id*720.0-scroll
		var district_id: int = Districts.at_distance(id*720.0/host.game.pixels_per_metre,host.game.pixels_per_metre)
		if district_id == 0:
			# A dark water strip and railing distinguish the waterfront from the road.
			c.draw_rect(Rect2(x,174,720,12),Color("#607b79"))
			c.draw_line(Vector2(x,173),Vector2(x+720,173),STONE,2)
			for post in 24:
				c.draw_line(Vector2(x+post*30,173),Vector2(x+post*30,187),IRON,2)
			var boat_x: float = x+300
			c.draw_colored_polygon(PackedVector2Array([Vector2(boat_x,176),Vector2(boat_x+70,176),Vector2(boat_x+57,185),Vector2(boat_x+12,185)]),BRICK)
			c.draw_rect(Rect2(boat_x+20,162,30,14),STONE)
			c.draw_line(Vector2(boat_x+37,143),Vector2(boat_x+37,176),IRON,2)
			c.draw_line(Vector2(x+80,143),Vector2(x+80,188),IRON,3)
			c.draw_rect(Rect2(x+73,135,14,13),Color("#d3bd83"))
			c.draw_line(Vector2(x+72,134),Vector2(x+88,134),IRON,3)
		else:
			bicycle(c,x+130,182)
			bicycle(c,x+148,181)
			bicycle(c,x+164,182)
			c.draw_line(Vector2(x+355,135),Vector2(x+355,188),IRON,3)
			c.draw_rect(Rect2(x+344,129,23,24),Color("#d6bb58"))
			host.text(c,Vector2(x+347,146),"BUS",9,IRON)
			c.draw_rect(Rect2(x+340,155,30,18),STONE)
			for line in 3:
				c.draw_line(Vector2(x+344,159+line*4),Vector2(x+365,159+line*4),IRON,1)
	# Fixed world markers: readable plaques, never floating in a traffic lane.
	for marker in [[180.0,"Dronning Louises Bro"],[640.0,"Nørrebrogade"],[1390.0,"UNIVERSITET"]]:
		var x: float = 240.0+(float(marker[0])-host.render_distance)*host.game.pixels_per_metre
		if x < -240 or x > 1200: continue
		c.draw_line(Vector2(x,141),Vector2(x,188),IRON,3)
		c.draw_rect(Rect2(x-110,118,220,25),Color("#e0d8c4"))
		c.draw_rect(Rect2(x-110,118,220,25),IRON,false,2)
		host.text(c,Vector2(x-102,136),marker[1],17,IRON)
