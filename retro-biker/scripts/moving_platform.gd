extends AnimatableBody2D
# Oscillating platform. Sits on collision layer 1 like static blocks so the
# player (mask 1) stands on it; sync_to_physics lets CharacterBody2D inherit its
# motion automatically. Presets (MovingPlatformH/V) set `axis` in the scene.

@export var axis: Vector2 = Vector2.RIGHT
@export var distance: float = 96.0     # peak travel from origin, px
@export var speed: float = 1.6         # angular speed, rad/sec
@export var width: float = 48.0
@export var height: float = 16.0
@export var color: Color = Color(0.62, 0.65, 0.78)

var _origin: Vector2
var _t: float = 0.0

func _ready() -> void:
	sync_to_physics = true
	_origin = position
	SpriteUtil.apply($Sprite2D, "res://assets/sprites/platform.png", color, width, height)

func _physics_process(delta: float) -> void:
	_t += delta
	position = _origin + axis.normalized() * sin(_t * speed) * distance
