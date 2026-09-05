extends Control
# Shared Game Over / Win screen: splash background, dimming overlay, a big
# title, and Retry / Main Menu buttons. Title text + color are set per scene.

func _ready() -> void:
	GameManager.play_menu()
	Sfx.play("win" if name == "WinScreen" else "gameover")
	var title: Label = $Center/Box/Title
	var retry: Button = $Center/Box/RetryButton
	var menu: Button = $Center/Box/MenuButton
	MenuStyle.style_title(title, 60)
	MenuStyle.style_button(retry)
	MenuStyle.style_button(menu)
	retry.pressed.connect(func() -> void: Sfx.play("select"); GameManager.reset_game())
	menu.pressed.connect(func() -> void: Sfx.play("select"); GameManager.go_to_menu())
	retry.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			Sfx.play("select")
			GameManager.reset_game()
		elif event.keycode == KEY_ESCAPE:
			Sfx.play("select")
			GameManager.go_to_menu()
