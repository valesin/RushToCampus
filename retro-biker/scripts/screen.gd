extends CanvasLayer
# Used by GameOver and WinScreen. Plays a stinger on show; any key restarts.

@export var enter_sound: String = ""   # set per-scene: "gameover" or "win"

func _ready() -> void:
	if enter_sound != "":
		Sfx.play(enter_sound)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		Sfx.play("select")
		GameManager.reset_game()
	elif event is InputEventMouseButton and event.pressed:
		Sfx.play("select")
		GameManager.reset_game()
