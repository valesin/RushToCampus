extends Control
# Shared Win / Game Over screen driven by GameManager cycling run stats.

@onready var title: Label = $Center/Card/Box/Title
@onready var subtitle: Label = $Center/Card/Box/Subtitle
@onready var stats: Label = $Center/Card/Box/Stats
@onready var record: Label = $Center/Card/Box/Record
@onready var primary: Button = $Center/Card/Box/PrimaryButton
@onready var menu_button: Button = $Center/Card/Box/MenuButton

func _ready() -> void:
	GameManager.play_menu()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var won: bool = name == "WinScreen"
	Sfx.play("win" if won else "gameover")
	$Center/Card.add_theme_stylebox_override("panel", MenuStyle.card_style())
	MenuStyle.style_display_title(title, 52 if won else 48)
	MenuStyle.style_subtitle(subtitle)
	MenuStyle.style_stat(stats, 22)
	MenuStyle.style_stat(record, 20)
	MenuStyle.style_button(primary)
	MenuStyle.style_secondary_button(menu_button)
	if won:
		title.text = "YOU WIN!"
		subtitle.text = "You made it to campus"
		primary.text = "▶  PLAY AGAIN  ◀"
		stats.text = "Flødebolle: %d" % GameManager.cycling_last_food
		if GameManager.cycling_new_record:
			record.text = "★  New Record!  ★"
			record.add_theme_color_override("font_color", MenuStyle.PINK)
		else:
			record.text = "Time  %d:%02d" % [
				int(GameManager.cycling_last_elapsed) / 60,
				int(GameManager.cycling_last_elapsed) % 60,
			]
	else:
		title.text = "GAME OVER"
		subtitle.text = "Watch out for traffic!"
		primary.text = "▶  RETRY  ◀"
		stats.text = "Distance:  %d m\nFlødebolle:  %d\nBest:  %d m" % [
			int(GameManager.cycling_last_distance),
			GameManager.cycling_last_food,
			int(GameManager.cycling_best_distance),
		]
		record.text = ""
		record.visible = false
	primary.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)
	primary.grab_focus()

func _on_retry() -> void:
	Sfx.play("select")
	GameManager.start_cycling()

func _on_menu() -> void:
	Sfx.play("select")
	GameManager.go_to_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			_on_retry()
		elif event.keycode == KEY_ESCAPE:
			_on_menu()
