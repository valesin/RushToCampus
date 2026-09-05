extends Control
# Main menu: splash background + title + Start / Quit. Boot scene of the game.

func _ready() -> void:
	GameManager.play_menu()
	var title: Label = $Center/Box/Title
	var start: Button = $Center/Box/StartButton
	var quit: Button = $Center/Box/QuitButton
	MenuStyle.style_title(title)
	MenuStyle.style_button(start)
	MenuStyle.style_button(quit)
	start.pressed.connect(_on_start)
	quit.pressed.connect(_on_quit)
	start.grab_focus()

func _on_start() -> void:
	GameManager.reset_game()

func _on_quit() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_start()
		elif event.keycode == KEY_ESCAPE:
			_on_quit()
