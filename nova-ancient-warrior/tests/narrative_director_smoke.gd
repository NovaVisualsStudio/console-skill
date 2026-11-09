extends SceneTree

const NarrativeDirector = preload("res://scripts/narrative_director.gd")


func _initialize() -> void:
	for chapter in range(1, 4):
		var lines: Array[Dictionary] = NarrativeDirector.chapter_dialogue(chapter)
		assert(lines.size() >= 3, "Every chapter needs a complete story setup")
		for line in lines:
			assert(not str(line.get("speaker", "")).is_empty(), "Dialogue speaker cannot be empty")
			assert(not str(line.get("text", "")).is_empty(), "English subtitle cannot be empty")
			assert(not str(line.get("text_ar", "")).is_empty(), "Arabic subtitle cannot be empty")

	for boss_kind in ["ash_titan", "ember_warlord", "obsidian_sovereign"]:
		var lines: Array[Dictionary] = NarrativeDirector.boss_dialogue(boss_kind)
		assert(lines.size() >= 2, "Every boss needs an introduction exchange")

	print("Narrative director smoke test passed: three localized chapter arcs and three boss exchanges")
	quit(0)
