extends SceneTree

const AUDIO_SCRIPT = preload("res://scripts/audio_fx.gd")

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var audio := AUDIO_SCRIPT.new() as NovaAudioFX
    root.add_child(audio)
    await process_frame

    if audio.ambience_player == null or audio.ambience_player.stream == null:
        push_error("Atmospheric ambience player was not created.")
        quit(1)
        return
    var ambience := audio.ambience_player.stream as AudioStreamWAV
    if ambience == null or ambience.loop_mode != AudioStreamWAV.LOOP_FORWARD:
        push_error("Atmospheric bed must be a looping WAV stream.")
        quit(1)
        return
    if ambience.data.size() < 22050:
        push_error("Atmospheric bed sample data is unexpectedly short.")
        quit(1)
        return
    if audio.one_shot_players.size() != 5:
        push_error("Combat sound pool should have five reusable voices.")
        quit(1)
        return

    audio.start_ambience()
    audio.play_swing(false)
    audio.play_swing(true)
    audio.play_hit(false)
    audio.play_hit(true)
    audio.play_parry()
    audio.play_telegraph(true)
    audio.play_boss_phase()
    if audio._swing_light.data.is_empty() or audio._impact_heavy.data.is_empty() or audio._parry.data.is_empty():
        push_error("One or more procedural combat sound assets have no sample data.")
        quit(1)
        return

    print("AUDIO TESTS PASS: looping atmospheric drone, light/heavy swing and impact, parry, boss telegraph and phase burst.")
    audio.free()
    await process_frame
    await process_frame
    quit(0)
