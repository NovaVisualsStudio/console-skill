extends SceneTree

const SOUND_NAMES := [
	"sword_swing", "heavy_swing", "impact", "parry", "footstep",
	"dodge", "jump", "hurt", "boss_roar", "hazard_warning",
	"hazard_burst", "victory", "upgrade"
]


func _initialize() -> void:
	for sound_name in SOUND_NAMES:
		var path := "res://audio/generated/%s.wav" % sound_name
		if not ResourceLoader.exists(path):
			push_error("Generated sound asset is missing: " + path)
			quit(1)
			return
		var stream := load(path) as AudioStreamWAV
		if stream == null:
			push_error("Generated sound did not import as WAV: " + path)
			quit(1)
			return
		if stream.mix_rate != 22050 or stream.data.is_empty():
			push_error("Generated sound has invalid sample rate or empty PCM: " + path)
			quit(1)
			return
		if stream.get_length() <= 0.04:
			push_error("Generated sound is too short to be useful: " + path)
			quit(1)
			return
	var music_path := "res://audio/generated/ambient_music.wav"
	if not ResourceLoader.exists(music_path):
		push_error("Original ambient music loop is missing: " + music_path)
		quit(1)
		return
	var music := load(music_path) as AudioStreamWAV
	if music == null or music.mix_rate != 22050 or music.data.is_empty() or music.get_length() < 10.0:
		push_error("Original ambient music loop failed WAV import or duration validation")
		quit(1)
		return
	print("Audio asset smoke test passed: %d original SFX WAV files and a %.2f-second ambient loop at 22.05 kHz" % [SOUND_NAMES.size(), music.get_length()])
	quit(0)
