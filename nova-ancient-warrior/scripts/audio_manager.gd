extends Node
## Owns music playback, the SFX voice pool, and synthesized fallback tones.

const MusicDirector = preload("res://scripts/music_director.gd")

var _voices: Array[AudioStreamPlayer] = []
var _voice_cursor := 0
var _sfx_streams: Dictionary = {}
var _music_director: Node
var _configured := false


func configure(profile: Dictionary) -> void:
	if _configured:
		return
	_configured = true
	_music_director = MusicDirector.new()
	_music_director.name = "MusicDirector"
	add_child(_music_director)
	var sfx_level := float(profile.get("sfx_volume", 0.85))
	var sfx_gain_db := linear_to_db(maxf(sfx_level, 0.0001)) - 5.0
	for index in range(4):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = sfx_gain_db
		add_child(voice)
		_voices.append(voice)
	var sound_names := [
		"sword_swing", "heavy_swing", "impact", "parry", "footstep",
		"dodge", "jump", "hurt", "boss_roar", "hazard_warning",
		"hazard_burst", "victory", "upgrade"
	]
	for sound_name in sound_names:
		var audio_path := "res://audio/generated/%s.wav" % sound_name
		if ResourceLoader.exists(audio_path):
			var stream := load(audio_path) as AudioStreamWAV
			if stream != null:
				_sfx_streams[sound_name] = stream


func play_sfx(sound_name: String) -> bool:
	if _voices.is_empty() or not _sfx_streams.has(sound_name):
		return false
	var voice := _next_voice()
	voice.stream = _sfx_streams[sound_name]
	voice.play()
	return true


func play_sfx_or_tone(sound_name: String, frequency: float, duration: float, amplitude: float) -> bool:
	if play_sfx(sound_name):
		return true
	return play_tone(frequency, duration, amplitude)


func play_tone(frequency: float, duration: float, amplitude: float) -> bool:
	if _voices.is_empty():
		return false
	var sample_rate := 22050
	var count := maxi(1, int(sample_rate * duration))
	var data := PackedByteArray()
	data.resize(count * 2)
	for index in range(count):
		var time := float(index) / float(sample_rate)
		var envelope := 1.0 - float(index) / float(count)
		var sample := int(sin(TAU * frequency * time) * amplitude * envelope * 32767.0)
		data.encode_s16(index * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	var voice := _next_voice()
	voice.stream = stream
	voice.play()
	return true


func set_music_intensity(value: float) -> void:
	if is_instance_valid(_music_director):
		_music_director.call("set_intensity", value)


func stop_and_release() -> void:
	if is_instance_valid(_music_director):
		_music_director.call("stop_and_release")
	for voice in _voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null


func _next_voice() -> AudioStreamPlayer:
	var voice := _voices[_voice_cursor]
	_voice_cursor = (_voice_cursor + 1) % _voices.size()
	return voice
