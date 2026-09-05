extends Node2D
var host
var layer_id: int
func _draw() -> void:
	host.render_layer(self, layer_id)
