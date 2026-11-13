extends Node
## Original, procedural ambient score. No third-party samples or licensed recordings.
const SAMPLE_RATE := 22050.0
const ROOT_NOTES := [55.0, 65.41, 73.42, 49.0]
const BEAT_SECONDS := 0.82

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _sample_cursor := 0
var _intensity := 0.22


func _ready() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = 0.65
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	var music_level := float(SaveManager.profile.get("music_volume", 0.72))
	_player.volume_db = linear_to_db(maxf(music_level, 0.0001)) - 8.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback


func set_intensity(value: float) -> void:
	_intensity = clampf(value, 0.0, 1.0)


func _process(_delta: float) -> void:
	if _playback == null:
		return
	var frames := mini(_playback.get_frames_available(), 2048)
	if frames <= 0:
		return
	var buffer := PackedVector2Array()
	buffer.resize(frames)
	for i in range(frames):
		var time := float(_sample_cursor) / SAMPLE_RATE
		var bar := int(floor(time / (BEAT_SECONDS * 4.0)))
		var chord: float = float(ROOT_NOTES[bar % ROOT_NOTES.size()])
		var beat_phase := fposmod(time, BEAT_SECONDS)
		var pad := sin(TAU * chord * time) * 0.105
		pad += sin(TAU * chord * 1.5 * time) * 0.052
		pad += sin(TAU * chord * 2.0 * time) * 0.024
		var upper := sin(TAU * chord * 3.0 * time + 0.3) * 0.018
		var kick := sin(TAU * 48.0 * beat_phase) * exp(-beat_phase * 17.0) * 0.10 * _intensity
		var pulse := sin(TAU * (chord * 0.5) * time) * 0.012 * _intensity
		var sample := clampf((pad + upper + kick + pulse) * (0.55 + _intensity * 0.45), -0.65, 0.65)
		buffer[i] = Vector2(sample, sample * 0.985)
		_sample_cursor += 1
	_playback.push_buffer(buffer)

func stop_and_release() -> void:
	if is_instance_valid(_player):
		_player.stop()
		_player.stream = null
	# Drop the script-held reference; AudioServer retires its playback asynchronously.
	_playback = null


func _exit_tree() -> void:
	stop_and_release()
