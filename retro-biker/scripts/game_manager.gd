extends Node
# Autoload singleton. Persists across scene reloads, so respawn / next-level
# are just reload_current_scene(); the Level scene rebuilds from current_level.

signal lives_changed(lives: int)
signal coins_changed(coins: int)

const MAX_LIVES := 3
const GAME_OVER_DELAY := 1.7   # let the death play out before the Game Over screen

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

# Starts a fresh run from level 1. Called by Main Menu "Start" and end-screen
# "Retry" / "Play Again".
func reset_game() -> void:
	current_level = 0
	lives = MAX_LIVES
	coins = 0
	lives_changed.emit(lives)
	coins_changed.emit(coins)
	get_tree().change_scene_to_file("res://scenes/Level.tscn")

# Returns to the main menu. Called by the end-screen "Main Menu" button.
func go_to_menu() -> void:
	current_level = 0
	lives = MAX_LIVES
	coins = 0
	lives_changed.emit(lives)
	coins_changed.emit(coins)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# Cycling session state survives menu, run and result scenes.
const CyclingResults = preload("res://scripts/cycling/results_store.gd")
var cycling_clean_theme: bool = true
var cycling_auto_start: bool = false
var cycling_last_result: Dictionary = {}
var cycling_best_distance: float = 0.0
var cycling_score_path: String = CyclingResults.PATH
var cycling_transition_pending: bool = false

func start_cycling() -> void:
	if cycling_transition_pending: return
	cycling_auto_start = true
	cycling_change_scene("res://scenes/cycling/CyclingGame.tscn")

func cycling_change_scene(path: String) -> void:
	if cycling_transition_pending: return
	cycling_transition_pending = true
	_finish_cycling_transition.call_deferred(path)

func _finish_cycling_transition(path: String) -> void:
	var error: Error = get_tree().change_scene_to_file(path)
	cycling_transition_pending = false
	if error != OK: push_error("Could not open cycling screen: " + path)

func record_cycling_result(result: Dictionary) -> void:
	cycling_last_result = result.duplicate(true)
	cycling_best_distance = maxf(cycling_best_distance, float(result.best))
	cycling_change_scene("res://scenes/WinScreen.tscn" if result.won else "res://scenes/GameOver.tscn")

func cycling_menu() -> void:
	cycling_auto_start = false
	cycling_change_scene("res://scenes/MainMenu.tscn")
