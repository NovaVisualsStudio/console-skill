extends SceneTree

const ARENA_SCRIPT = preload("res://scripts/main.gd")
const TEST_SAVE_PATH := "user://nova_campaign_smoke.cfg"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var arena := ARENA_SCRIPT.new() as NovaArenaController
    if arena.CHAPTER_NAMES.size() != 3 or arena.BOSS_NAMES.size() != 3:
        push_error("Campaign test: expected three chapters and three boss identities.")
        quit(1)
        return
    arena.chapter_index = 0
    arena.unlocked_chapter = 0
    arena._save_campaign_progress(1, false, TEST_SAVE_PATH)
    var config := ConfigFile.new()
    if config.load(TEST_SAVE_PATH) != OK:
        push_error("Campaign test: progress file was not written.")
        quit(1)
        return
    if int(config.get_value("progress", "current_chapter", -1)) != 1 or int(config.get_value("progress", "unlocked_chapter", -1)) != 1:
        push_error("Campaign test: chapter unlock did not persist.")
        quit(1)
        return
    arena._load_campaign_progress(TEST_SAVE_PATH)
    if arena.chapter_index != 1:
        push_error("Campaign test: loading progress did not restore chapter two.")
        quit(1)
        return
    arena._save_campaign_progress(2, true, TEST_SAVE_PATH)
    arena._load_campaign_progress(TEST_SAVE_PATH)
    if arena.chapter_index != 2 or not arena.campaign_complete:
        push_error("Campaign test: final chapter completion did not persist.")
        quit(1)
        return
    arena._save_campaign_progress(0, false, TEST_SAVE_PATH)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
    arena.free()
    for stage_index in [1, 2]:
        var stage_arena := ARENA_SCRIPT.new() as NovaArenaController
        stage_arena.chapter_index = stage_index
        stage_arena._build_world()
        if stage_arena.get_child_count() < 20:
            push_error("Campaign test: chapter %d did not build its environment geometry." % (stage_index + 1))
            stage_arena.free()
            quit(1)
            return
        if stage_index == 1 and stage_arena.find_child("SanctumBrokenArchLeft", true, false) == null:
            push_error("Campaign test: Sunken Sanctum is missing its distinct broken cathedral architecture.")
            stage_arena.free()
            quit(1)
            return
        if stage_index == 2 and stage_arena.find_child("CrownObsidianMonolith", true, false) == null:
            push_error("Campaign test: Crown of Ash is missing its distinct obsidian skyline.")
            stage_arena.free()
            quit(1)
            return
        stage_arena.free()
    print("CAMPAIGN TEST PASS: persistent progression plus distinct Sunken Sanctum and Crown of Ash landmarks verified.")
    quit(0)
