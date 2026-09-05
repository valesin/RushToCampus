extends Control
# Rush to Campus start screen — Copenhagen art, live best distance, Start / How to Play.

@onready var best_label: Label = $BestBadge/BestLabel
@onready var start_button: Button = $StartButton
@onready var how_button: Button = $HowButton
@onready var how_panel: PanelContainer = $HowPanel

func _ready() -> void:
	GameManager.play_menu()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	MenuStyle.style_hotspot(start_button)
	MenuStyle.style_hotspot(how_button)
	MenuStyle.style_stat(best_label, 18)
	MenuStyle.style_subtitle($HowPanel/HowBox/HowTitle, 26)
	MenuStyle.style_stat($HowPanel/HowBox/HowBody, 18)
	$BestBadge.add_theme_stylebox_override("panel", MenuStyle.badge_style())
	how_panel.add_theme_stylebox_override("panel", MenuStyle.card_style())
	how_panel.visible = false
	_refresh_best()
	start_button.pressed.connect(_on_start)
	how_button.pressed.connect(_on_how)
	$HowPanel/HowBox/CloseHow.pressed.connect(func() -> void:
		how_panel.visible = false
		start_button.grab_focus()
	)
	MenuStyle.style_secondary_button($HowPanel/HowBox/CloseHow)
	start_button.grab_focus()

func _refresh_best() -> void:
	var best: float = GameManager.cycling_best_distance
	if best <= 0.0:
		best = GameManager.read_cycling_best()
	best_label.text = "Best Distance: %d m" % int(best)

func _on_start() -> void:
	Sfx.play("select")
	GameManager.start_cycling()

func _on_how() -> void:
	Sfx.play("select")
	how_panel.visible = not how_panel.visible
	if how_panel.visible:
		$HowPanel/HowBox/CloseHow.grab_focus()
	else:
		start_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			if how_panel.visible:
				how_panel.visible = false
				start_button.grab_focus()
			else:
				_on_start()
		elif event.keycode == KEY_ESCAPE:
			if how_panel.visible:
				how_panel.visible = false
				start_button.grab_focus()
			else:
				get_tree().quit()
