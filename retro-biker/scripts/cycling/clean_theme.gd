extends RefCounted
## Alternative 2D illustrations. Gameplay dimensions belong to Presentation/Layout.
const DIR: String = "res://assets/cycling/clean/"
const DETAILS: Dictionary = {
	"bread": Rect2(108,96,494,344), "pastry": Rect2(684,100,489,345),
	"planter": Rect2(90,550,535,349), "chair": Rect2(790,493,335,434),
	"curb": Rect2(66,1058,554,104), "cycle": Rect2(692,987,488,228)
}
const ACTORS: Dictionary = {
	"player": Rect2(90,108,368,350), "cyclist": Rect2(582,110,357,349),
	"car": Rect2(992,274,506,184), "bus": Rect2(44,634,680,226),
	"pedestrian": Rect2(756,560,194,312), "barrier": Rect2(1076,610,382,254)
}
var city: Texture2D
var materials: Texture2D
var details: Texture2D
var frames: Array[Texture2D] = []

func _init() -> void:
	city = load(DIR + "city.png")
	materials = load(DIR + "materials.png")
	details = load(DIR + "details.png")
	frames.assign([load(DIR + "traffic-1.png"),load(DIR + "traffic-2.png")])

static func scaled_region(region: Rect2, texture: Texture2D, source_size: Vector2) -> Rect2:
	var ratio: Vector2 = texture.get_size() / source_size
	return Rect2(region.position * ratio, region.size * ratio)
