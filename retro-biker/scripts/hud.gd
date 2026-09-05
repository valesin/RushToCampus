extends CanvasLayer

@onready var hearts: HBoxContainer = $Margin/Rows/Hearts
@onready var coin_icon: TextureRect = $Margin/Rows/Coins/CoinIcon
@onready var coin_count: Label = $Margin/Rows/Coins/CoinCount

func _ready() -> void:
	GameManager.lives_changed.connect(_update_lives)
	GameManager.coins_changed.connect(_update_coins)
	# Hearts use the real heart sprite (cropped real PNG if present, else solid red).
	for child in hearts.get_children():
		if child is TextureRect:
			var rect := child as TextureRect
			rect.texture = SpriteUtil.texture_for("res://assets/sprites/heart.png", Color(0.9, 0.15, 0.2), 28)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.custom_minimum_size = Vector2(24, 24)
	coin_icon.texture = SpriteUtil.texture_for("res://assets/sprites/coin.png", Color(0.95, 0.8, 0.2), 22)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_count.add_theme_font_size_override("font_size", 18)
	coin_count.add_theme_color_override("font_color", Color(1, 1, 1))
	coin_count.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.15))
	coin_count.add_theme_constant_override("outline_size", 5)
	_update_lives(GameManager.lives)
	_update_coins(GameManager.coins)

func _update_lives(lives: int) -> void:
	var i := 0
	for child in hearts.get_children():
		child.visible = i < lives
		i += 1

func _update_coins(coins: int) -> void:
	coin_count.text = "x " + str(coins)
