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
			stream = null
			quit(1)
			return
		stream = null
	var music_path := "res://audio/generated/ambient_music.wav"
	if not ResourceLoader.exists(music_path):
		push_error("Original ambient music loop is missing: " + music_path)
		quit(1)
		return
	var music := load(music_path) as AudioStreamWAV
	if music == null or music.mix_rate != 22050 or music.data.is_empty() or music.get_length() < 10.0:
		push_error("Original ambient music loop failed WAV import or duration validation")
		music = null
		quit(1)
		return
	var music_length := music.get_length()
	var director_script := load("res://scripts/music_director.gd")
	if director_script == null:
		push_error("MusicDirector script could not be loaded")
		music = null
		quit(1)
		return
	var director = director_script.new()
	root.add_child(director)
	await process_frame
	var player := director.get_node_or_null("AudioStreamPlayer") as AudioStreamPlayer
	if player == null:
		push_error("MusicDirector did not create an AudioStreamPlayer")
		director.free()
		await process_frame
		director = null
		music = null
		quit(1)
		return
	var active_music := player.stream as AudioStreamWAV
	if active_music == null or active_music.loop_mode != AudioStreamWAV.LOOP_FORWARD or active_music.loop_end <= 0:
		push_error("MusicDirector did not configure a valid looping WAV stream")
		director.free()
		await process_frame
		player = null
		active_music = null
		director = null
		music = null
		quit(1)
		return
	director.free()
	await process_frame
	await process_frame
	player = null
	active_music = null
	director = null
	music = null
	print("Audio asset smoke test passed: %d original SFX WAV files and a %.2f-second looping ambient track configured at 22.05 kHz" % [SOUND_NAMES.size(), music_length])
	quit(0)
