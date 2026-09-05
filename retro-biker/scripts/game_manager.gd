extends Node
# Autoload singleton. Persists across scene reloads, so respawn / next-level
# are just reload_current_scene(); the Level scene rebuilds from current_level.

signal lives_changed(lives: int)
signal coins_changed(coins: int)

const MAX_LIVES := 3
const GAME_OVER_DELAY := 1.7   # let the death play out before the Game Over screen
const CYCLING_SCENE := "res://scenes/cycling/CyclingGame.tscn"
const CYCLING_BEST_PATH := "user://cycling_best.json"

var level_files := [
	"res://levels/level_01.txt",
	"res://levels/level_02.txt",
	"res://levels/level_03.txt",
	"res://levels/level_04.txt",
]
var current_level := 0
var lives := MAX_LIVES
var _game_over_pending := false
var coins := 0

# Cycling run summary for Rush start / win / game-over screens.
var cycling_best_distance: float = 0.0
var cycling_last_distance: float = 0.0
var cycling_last_food: int = 0
var cycling_last_elapsed: float = 0.0
var cycling_new_record: bool = false
var cycling_auto_start: bool = true

# --- Music. Lives on this autoload so it survives scene changes; switching only
# happens when the requested track differs, so level->level keeps playing. ---
var _music: AudioStreamPlayer
var _menu_stream: AudioStream
var _game_stream: AudioStream
var _boss_stream: AudioStream
var _current_track := ""

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.volume_db = -9.0
	add_child(_music)
	_menu_stream = _load_loop("res://assets/audio/music_level.mp3")
	_game_stream = _load_loop("res://assets/audio/music_game.mp3")
	_boss_stream = _load_loop("res://assets/audio/music_boss.mp3")
	cycling_best_distance = read_cycling_best()

func _load_loop(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	var s = load(path)
	if s is AudioStreamMP3:
		s = s.duplicate()
		s.loop = true
	elif s is AudioStreamWAV:
		s = s.duplicate()
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2     # 16-bit mono -> 2 bytes per frame
	return s

func stop_music() -> void:
	_music.stop()
	_current_track = ""

func play_menu() -> void:
	_play("menu", _menu_stream)

func play_game() -> void:
	_play("game", _game_stream)

func play_boss() -> void:
	_play("boss", _boss_stream)

func _play(id: String, stream: AudioStream) -> void:
	if stream == null or _current_track == id:
		return
	_current_track = id
	_music.stream = stream
	_music.play()

func get_current_level_path() -> String:
	return level_files[current_level]

# Deducts one life. Returns true if that was the last life (game over triggered
# here), so the caller can stop. The caller decides what a non-fatal loss does
# (the player takes a hit in place; a fall respawns at the level start).
func lose_life() -> bool:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		_trigger_game_over()
		return true
	return false

# Hold a beat on the death (so the player can see it) before the Game Over screen.
func _trigger_game_over() -> void:
	if _game_over_pending:
		return
	_game_over_pending = true
	get_tree().create_timer(GAME_OVER_DELAY).timeout.connect(_go_to_game_over)

func _go_to_game_over() -> void:
	_game_over_pending = false
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

# Collectibles.
func add_coin() -> void:
	coins += 1
	coins_changed.emit(coins)

# Restores one life up to the cap. Returns true if it actually healed.
func add_life() -> bool:
	if lives >= MAX_LIVES:
		return false
	lives += 1
	lives_changed.emit(lives)
	return true

# Called by Door when the player reaches it.
func next_level() -> void:
	current_level += 1
	if current_level >= level_files.size():
		get_tree().change_scene_to_file("res://scenes/WinScreen.tscn")
	else:
		get_tree().reload_current_scene()

# Starts a fresh platformer run from level 1.
func reset_game() -> void:
	current_level = 0
	lives = MAX_LIVES
	coins = 0
	lives_changed.emit(lives)
	coins_changed.emit(coins)
	get_tree().change_scene_to_file("res://scenes/Level.tscn")

# Boot the Copenhagen cycling run from Rush menus.
func start_cycling() -> void:
	cycling_auto_start = true
	get_tree().change_scene_to_file(CYCLING_SCENE)

func record_cycling_result(won: bool, distance: float, food: int, elapsed: float, best: float, new_record: bool) -> void:
	cycling_last_distance = distance
	cycling_last_food = food
	cycling_last_elapsed = elapsed
	cycling_best_distance = best
	cycling_new_record = new_record
	var path: String = "res://scenes/WinScreen.tscn" if won else "res://scenes/GameOver.tscn"
	get_tree().change_scene_to_file(path)

func read_cycling_best() -> float:
	if not FileAccess.file_exists(CYCLING_BEST_PATH):
		return 0.0
	var file := FileAccess.open(CYCLING_BEST_PATH, FileAccess.READ)
	if file == null:
		return 0.0
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return 0.0
	var parsed = parser.data
	if not parsed is Dictionary:
		return 0.0
	var value = parsed.get("best_distance", 0.0)
	if not (value is float or value is int):
		return 0.0
	return maxf(0.0, float(value)) if is_finite(float(value)) else 0.0

# Returns to the main menu. Called by the end-screen "Main Menu" button.
func go_to_menu() -> void:
	current_level = 0
	lives = MAX_LIVES
	coins = 0
	lives_changed.emit(lives)
	coins_changed.emit(coins)
	cycling_best_distance = read_cycling_best()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
