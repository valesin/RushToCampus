extends Node
## Scene-local voices. No template Sfx or music; the run owns pause and reset.
const Districts = preload("res://scripts/cycling/districts.gd")
const DIR: String = "res://assets/cycling/audio/"
const GROUPS: Array[String] = ["CyclingAmbience", "CyclingRider", "CyclingTraffic", "CyclingInterface"]
@export var mix_gain_db: float = 10.0
@export var crossfade_seconds: float = 3.0
@export var shelter_fade_seconds: float = 0.5
@export var max_traffic_voices: int = 4
@export var bell_interval: float = 2.0
var game
var streams: Dictionary = {}
var ambience: Array[AudioStreamPlayer] = []
var rider_voices: Array[AudioStreamPlayer] = []
var traffic_voices: Array[AudioStreamPlayer] = []
var traffic_owners: Array[String] = []
var traffic_pans: Array[AudioEffectPanner] = []
var owned_buses: Array[String] = []
var bell: AudioStreamPlayer
var impact: AudioStreamPlayer
var district_weights: Array[float] = [1.0,0.0,0.0]
var fade_from: Array[float] = [1.0,0.0,0.0]
var district_id: int = 0
var fade_elapsed: float = 3.0
var wind_gain_db: float = -35.0
var bell_left: float = 0.0
var duck_left: float = 0.0
var bell_count: int = 0
var impact_count: int = 0
var peak_traffic_count: int = 0

func _ready() -> void:
	for group in GROUPS:
		ensure_bus(group)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(group),mix_gain_db)
	for clip in ["waterfront","street","campus","tyres","chain","freewheel","wind","car","bus","bell","bump"]:
		var path: String = DIR + clip + ".ogg"
		if ResourceLoader.exists(path):
			streams[clip] = load(path)
		else:
			push_error("Missing cycling sound: " + path)
	for clip in ["waterfront","street","campus"]:
		ambience.append(make_voice(clip, "CyclingAmbience", true))
	for clip in ["tyres","chain","freewheel","wind"]:
		rider_voices.append(make_voice(clip, "CyclingRider", true))
	for i in max_traffic_voices:
		var bus_name: String = "CyclingTraffic" + str(i)
		ensure_bus(bus_name, "CyclingTraffic")
		var pan := AudioEffectPanner.new()
		AudioServer.add_bus_effect(AudioServer.get_bus_index(bus_name), pan)
		traffic_pans.append(pan)
		traffic_voices.append(make_voice("", bus_name, true))
		traffic_owners.append("")
	bell = make_voice("bell", "CyclingInterface", false)
	impact = make_voice("bump", "CyclingInterface", false)
	reset()

func ensure_bus(bus_name: String, send: String = "Master") -> void:
	if AudioServer.get_bus_index(bus_name) >= 0: return
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, send)
	owned_buses.append(bus_name)

func make_voice(clip: String, bus_name: String, looping: bool) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	# Streaming avoids the web sample loop allocation failure and retains bus effects.
	if OS.has_feature("web"): voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	voice.bus = bus_name
	voice.volume_db = -80.0
	add_child(voice)
	if streams.has(clip):
		var stream: AudioStream = streams[clip].duplicate()
		if stream is AudioStreamOggVorbis: stream.loop = looping
		voice.stream = stream
	return voice

func reset() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream_paused = false
			child.volume_db = -80.0
	for i in traffic_owners.size(): traffic_owners[i] = ""
	district_id = 0
	district_weights = [1.0,0.0,0.0]
	fade_from = [1.0,0.0,0.0]
	fade_elapsed = crossfade_seconds
	wind_gain_db = -35.0
	bell_left = 0.0
	duck_left = 0.0
	bell_count = 0
	impact_count = 0
	peak_traffic_count = 0

func _process(delta: float) -> void:
	update_mix(delta)

func update_mix(delta: float) -> void:
	if game == null: return
	var paused: bool = game.state == game.RunState.PAUSED
	for child in get_children():
		if child is AudioStreamPlayer and child.stream_paused != paused: child.stream_paused = paused
	if paused: return
	var running: bool = game.state == game.RunState.RUNNING
	bell_left = maxf(0.0, bell_left-delta)
	duck_left = maxf(0.0, duck_left-delta)
	var next_district: int = 2 if game.state == game.RunState.SUCCESS else Districts.at_distance(game.distance, game.pixels_per_metre)
	if next_district != district_id:
		fade_from = district_weights.duplicate()
		district_id = next_district
		fade_elapsed = 0.0
	fade_elapsed = minf(crossfade_seconds, fade_elapsed+delta)
	var blend: float = clampf(fade_elapsed / maxf(0.01,crossfade_seconds),0.0,1.0)
	var duck: float = -10.0 if duck_left > 0.0 else 0.0
	for i in ambience.size():
		district_weights[i] = lerpf(fade_from[i],1.0 if i == district_id else 0.0,blend)
		set_loop(ambience[i], -25.0 + duck + linear_to_db(maxf(0.0001,district_weights[i])), district_weights[i] > 0.0001)
	if not running:
		stop_motion()
		return
	var ratio: float = clampf(game.rider.speed / game.rider.base_speed,0.25,1.3)
	set_loop(rider_voices[0], -24.0 + linear_to_db(ratio))
	set_loop(rider_voices[1], (-35.0 if game.rider.recovering else -25.0) + linear_to_db(ratio))
	set_loop(rider_voices[2], -32.0 + linear_to_db(ratio), game.rider.recovering)
	for i in 3:
		rider_voices[i].pitch_scale = clampf(0.65+ratio*0.35,0.7,1.12)
	var exposure: float = 1.0 if game.wind.phase() == "HEADWIND" else 0.0
	var wind_target: float = lerpf(-34.0,-21.0,exposure) - (9.0 if game.rider.sheltered else 0.0)
	wind_gain_db = move_toward(wind_gain_db,wind_target,18.0/maxf(0.1,shelter_fade_seconds)*delta)
	set_loop(rider_voices[3],wind_gain_db)
	update_traffic()

func set_loop(voice: AudioStreamPlayer, db: float, enabled: bool = true) -> void:
	if not enabled:
		voice.stop()
		return
	voice.volume_db = clampf(db,-80.0,-10.0)
	if not voice.playing and voice.stream != null: voice.play()

func stop_motion() -> void:
	for voice in rider_voices: voice.stop()
	for i in traffic_voices.size():
		traffic_voices[i].stop()
		traffic_owners[i] = ""
	bell.stop()

func actor_key(actor) -> String:
	return str(actor.get_instance_id()) + ":" + str(actor.audio_generation)

func update_traffic() -> void:
	var candidates: Array = []
	for actor in game.traffic.actors:
		if actor.definition.kind not in ["car","bus","cyclist"]: continue
		var dx: float = actor.distance-game.distance
		if dx < -24.0 or dx > 65.0: continue
		var lane_gap: float = absf(actor.definition.lane-game.rider.lane_position)
		candidates.append({"actor":actor,"key":actor_key(actor),"priority":absf(dx)+lane_gap*8.0})
	candidates.sort_custom(func(a,b): return a.priority < b.priority)
	if candidates.size() > max_traffic_voices: candidates.resize(max_traffic_voices)
	var keys: Array = candidates.map(func(item): return item.key)
	for i in traffic_owners.size():
		if traffic_owners[i] not in keys:
			traffic_owners[i] = ""
			traffic_voices[i].stop()
	for item in candidates:
		var actor = item.actor
		var slot: int = traffic_owners.find(item.key)
		if slot < 0:
			slot = traffic_owners.find("")
			if slot < 0: continue
			traffic_owners[slot] = item.key
			var clip: String = "chain" if actor.definition.kind == "cyclist" else actor.definition.kind
			var stream: AudioStream = streams.get(clip)
			if stream != null:
				stream = stream.duplicate()
				if stream is AudioStreamOggVorbis: stream.loop = true
			traffic_voices[slot].stream = stream
		var dx: float = actor.distance-game.distance
		var lane_gap: float = absf(actor.definition.lane-game.rider.lane_position)
		var proximity: float = 1.0/(1.0+pow(absf(dx)/10.0,2.0))
		var base_db: float = -18.0 if actor.definition.kind == "bus" else -21.0 if actor.definition.kind == "car" else -29.0
		set_loop(traffic_voices[slot],base_db+linear_to_db(maxf(0.001,proximity))-lane_gap*2.5)
		# Relative to the rider/listener, not the screen centre; mono retains the envelope.
		traffic_pans[slot].pan = clampf(dx/30.0,-0.75,0.75)
		if actor.definition.kind == "cyclist" and dx > 0.0 and dx < 14.0 and lane_gap < 0.6 and not actor.bell_played and bell_left <= 0.0:
			actor.bell_played = true
			bell_left = bell_interval
			bell.volume_db = -27.0
			bell.play()
			bell_count += 1
	peak_traffic_count = maxi(peak_traffic_count,candidates.size())

func hit(lethal: bool) -> void:
	impact.volume_db = -14.0 if lethal else -22.0
	impact.pitch_scale = 0.85 if lethal else 1.0
	impact.play()
	impact_count += 1
	if lethal:
		stop_motion()
		duck_left = 1.2

func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer: child.stop()
	for i in range(owned_buses.size()-1,-1,-1):
		var index: int = AudioServer.get_bus_index(owned_buses[i])
		if index >= 0: AudioServer.remove_bus(index)
