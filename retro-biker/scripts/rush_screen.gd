extends Control
## Shared live interface for the start and result scenes; backgrounds contain no UI.
const Store = preload("res://scripts/cycling/results_store.gd")
var background: TextureRect
var buttons: Array[Button] = []
var theme_button: Button
var how_panel: PanelContainer
var close_button: Button
var leaving: bool = false
var is_start: bool = false
var title: Label
var subtitle: Label

func _ready() -> void:
	is_start = name == "MainMenu"
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.play_menu()
	GameManager.cycling_best_distance = maxf(GameManager.cycling_best_distance, Store.read_best(GameManager.cycling_score_path))
	background = TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	title = label_at("RUSH TO", Rect2(190,16,580,75), 64)
	subtitle = label_at("CAMPUS", Rect2(190,83,580,84), 72)
	subtitle.add_theme_color_override("font_color", Color("29b9b4"))
	var badge := panel_at(Rect2(720,14,226,37))
	var best := Label.new()
	best.text = "BEST DISTANCE  %d m" % int(GameManager.cycling_best_distance)
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best.add_theme_font_size_override("font_size",16)
	best.add_theme_color_override("font_color",Color("f7f1e4"))
	badge.add_child(best)
	if is_start:
		button_at("START GAME", Rect2(315,360,330,56), start_run)
		button_at("HOW TO PLAY", Rect2(315,426,330,40), show_how)
		theme_button = button_at("", Rect2(245,477,470,40), switch_theme)
	else:
		build_results()
		Sfx.play("win" if name == "WinScreen" else "gameover", -10.0)
	build_how()
	apply_theme()
	buttons[0].grab_focus()

func panel_at(rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06,0.1,0.13,0.94)
	style.border_color = Color("e5cd99")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	return panel

func label_at(value: String, rect: Rect2, font_size: int) -> Label:
	var result := Label.new()
	result.position = rect.position
	result.size = rect.size
	result.text = value
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size",font_size)
	result.add_theme_color_override("font_color",Color("fff1d5"))
	result.add_theme_color_override("font_outline_color",Color("172331"))
	result.add_theme_constant_override("outline_size",8 if font_size > 40 else 3)
	if font_size > 40:
		var display_font := FontVariation.new()
		display_font.base_font = ThemeDB.fallback_font
		display_font.variation_embolden = 1.6
		result.add_theme_font_override("font",display_font)
		result.add_theme_color_override("font_shadow_color",Color("e85a7a"))
		result.add_theme_constant_override("shadow_offset_x",4)
		result.add_theme_constant_override("shadow_offset_y",5)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result)
	return result

func button_at(value: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = value
	button.add_theme_font_size_override("font_size",22 if rect.size.y > 45 else 17)
	for state: String in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("f7f1e4") if state == "normal" else Color("ffe3aa")
		style.border_color = Color("e85a7a") if state == "focus" else Color("193545")
		style.set_border_width_all(4 if state == "focus" else 2)
		style.set_corner_radius_all(12)
		if state == "focus": style.bg_color = Color(0,0,0,0)
		button.add_theme_stylebox_override(state,style)
	for state: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,Color("172331"))
	button.pressed.connect(callback)
	add_child(button)
	buttons.append(button)
	return button

func build_results() -> void:
	var result: Dictionary = GameManager.cycling_last_result
	var won: bool = bool(result.get("won", name == "WinScreen"))
	title.text = "YOU MADE IT!" if won else "GAME OVER"
	title.add_theme_font_size_override("font_size",50)
	subtitle.text = "RUSH TO CAMPUS"
	subtitle.add_theme_font_size_override("font_size",30)
	panel_at(Rect2(270,186,420,235))
	var seconds: int = int(result.get("elapsed",0.0))
	label_at("You made it to campus" if won else "Watch out for traffic!",Rect2(280,191,400,32),22)
	label_at("DISTANCE   %d m\nTIME   %d:%02d\nFOOD COLLECTED   %d" % [int(result.get("distance",0.0)),seconds / 60,seconds % 60,int(result.get("food",0))],Rect2(280,228,400,108),23)
	label_at("NEW DISTANCE RECORD!" if result.get("new_record",false) else "BEST DISTANCE   %d m" % int(GameManager.cycling_best_distance),Rect2(280,344,400,30),20)
	label_at("Best score could not be saved." if result.get("save_error",false) else "LOOK: " + theme_name(),Rect2(280,382,400,26),15)
	button_at("PLAY AGAIN" if won else "RETRY",Rect2(310,434,340,43),start_run)
	button_at("MAIN MENU",Rect2(310,486,340,38),main_menu)

func build_how() -> void:
	how_panel = panel_at(Rect2(160,96,640,354))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",14)
	how_panel.add_child(box)
	var body := Label.new()
	body.text = "HOW TO PLAY\n\nW/S or ↑/↓ — change lanes\nK — boost for 2 seconds (20 energy)\nAt zero energy: 2 seconds of recovery\nDraft behind a cyclist: +5 energy/s during normal riding\nRugbrød +20 • Danish +30 • Reach campus at 1.5 km\nJ / Enter / Space — confirm    L / Escape — pause/back"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size",19)
	body.add_theme_color_override("font_color",Color("f7f1e4"))
	box.add_child(body)
	close_button = Button.new()
	close_button.text = "GOT IT"
	close_button.custom_minimum_size.y = 42
	close_button.pressed.connect(hide_how)
	box.add_child(close_button)
	how_panel.visible = false

func theme_name() -> String:
	return "COLOURFUL" if GameManager.cycling_clean_theme else "ILLUSTRATED"

func apply_theme() -> void:
	background.texture = load("res://assets/ui/rush-colourful.png" if GameManager.cycling_clean_theme else "res://assets/ui/rush-illustrated.png")
	subtitle.add_theme_color_override("font_color",Color("29b9b4") if GameManager.cycling_clean_theme else Color("dfb552"))
	if theme_button != null:
		theme_button.text = "LOOK: " + theme_name() + "  /  Switch to " + ("Illustrated" if GameManager.cycling_clean_theme else "Colourful")

func switch_theme() -> void:
	Sfx.play("select",-14.0)
	GameManager.cycling_clean_theme = not GameManager.cycling_clean_theme
	apply_theme()

func show_how() -> void:
	Sfx.play("select",-14.0)
	how_panel.show()
	for button in buttons: button.disabled = true
	close_button.grab_focus()

func hide_how() -> void:
	how_panel.hide()
	for button in buttons: button.disabled = false
	buttons[1].grab_focus()

func start_run() -> void:
	if leaving: return
	Sfx.play("select",-14.0)
	leaving = true
	GameManager.start_cycling()

func main_menu() -> void:
	if leaving: return
	Sfx.play("select",-14.0)
	leaving = true
	GameManager.cycling_menu()

func _input(event: InputEvent) -> void:
	if leaving or event.is_echo(): return
	var handled: bool = true
	if event.is_action_pressed("cycling_confirm"):
		var focused: Control = get_viewport().gui_get_focus_owner()
		if focused is Button and not focused.disabled: focused.pressed.emit()
	elif event.is_action_pressed("cycling_up") or event.is_action_pressed("cycling_down"):
		if not how_panel.visible:
			var index: int = buttons.find(get_viewport().gui_get_focus_owner())
			var direction: int = 1 if event.is_action_pressed("cycling_down") else -1
			buttons[posmod(index + direction,buttons.size())].grab_focus()
	elif event.is_action_pressed("cycling_pause"):
		if how_panel.visible: hide_how()
		elif not is_start: main_menu()
	else:
		handled = false
	if handled: get_viewport().set_input_as_handled()
