extends Resource
## Team-facing traffic contract. Visuals use bottom-centre origins.
@export_enum("bus", "car", "cyclist", "pedestrian", "barrier") var kind: String = "car"
@export_range(0, 4) var lane: int = 1
@export var speed: float = -12.0
@export var contact_size: Vector2 = Vector2(4.0, 0.36)
@export var visual_scene: PackedScene
