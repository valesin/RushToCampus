extends Node
# Central one-shot sound-effect player. Call `Sfx.play("jump")` from anywhere.
# Music is handled separately in GameManager — this only does SFX.
# Files live at res://assets/audio/<name>.mp3.

const POOL := 12
const DIR := "res://assets/audio/"
const NAMES := [
	"jump", "land", "footstep", "hurt", "death",
	"stomp", "bounce", "crumble",
	"level_complete", "win", "gameover", "select",
	"boss_intro", "boss_win",
	"coin", "heart",
]

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # SFX still play while the tree is paused
	for n in NAMES:
		# Accept either container — generated SFX may arrive as .mp3 or .wav.
		var mp3: String = DIR + n + ".mp3"
		var wav: String = DIR + n + ".wav"
		if ResourceLoader.exists(mp3):
			_streams[n] = load(mp3)
		elif ResourceLoader.exists(wav):
			_streams[n] = load(wav)
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)

# Plays a one-shot SFX by name. `pitch` accepts a small random spread for variety.
func play(name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _streams.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = _streams[name]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()
