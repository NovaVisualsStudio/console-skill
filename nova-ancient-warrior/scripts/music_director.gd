extends Node
## Original ambient score is baked by tools/generate_game_audio.py and looped as a WAV.
const MUSIC_PATH := "res://audio/generated/ambient_music.wav"

var _player: AudioStreamPlayer
var _music_level := 0.72
var _intensity := 0.22


func _ready() -> void:
	print("MUSIC_DIRECTOR_READY_ENTER")
	print("MUSIC_DIRECTOR_PATH_EXISTS=", ResourceLoader.exists(MUSIC_PATH))
	var stream := load(MUSIC_PATH) as AudioStreamWAV
	print("MUSIC_DIRECTOR_STREAM_OK=", stream != null, " DATA_BYTES=", stream.data.size() if stream != null else -1)
	if stream == null or stream.data.is_empty():
		push_warning("Original ambient music is missing; run tools/generate_game_audio.py")
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.data.size() / (4 if stream.stereo else 2))
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		var profile = save_manager.get("profile")
		if profile is Dictionary:
			_music_level = float(profile.get("music_volume", _music_level))
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	add_child(_player)
	print("MUSIC_DIRECTOR_PLAYER_ADDED=", _player.is_inside_tree(), " CHILDREN=", get_child_count())
	_apply_volume()
	_player.play()


func _exit_tree() -> void:
	if is_instance_valid(_player):
		_player.stop()
		_player.stream = null
		_player.free()
	_player = null


func set_intensity(value: float) -> void:
	_intensity = clampf(value, 0.0, 1.0)
	_apply_volume()


func _apply_volume() -> void:
	if not is_instance_valid(_player):
		return
	var scaled_level := _music_level * (0.55 + _intensity * 0.45)
	_player.volume_db = linear_to_db(maxf(scaled_level, 0.0001)) - 8.0
