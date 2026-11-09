extends SceneTree

const CombatRules = preload("res://scripts/combat_rules.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")


func _initialize() -> void:
	for wave in range(1, 10):
		var should_be_boss := wave == 3 or wave == 6 or wave == 9
		if CombatRules.is_boss_wave(wave) != should_be_boss:
			push_error("Boss scheduling mismatch at wave %d" % wave)
			quit(1)
			return
		if CombatRules.chapter_for_wave(wave) != LevelCatalog.stage_index(wave) + 1:
			push_error("Campaign chapter mismatch at wave %d" % wave)
			quit(1)
			return
	if CombatRules.is_final_boss_wave(9) != true or CombatRules.is_final_boss_wave(8):
		push_error("Final campaign boss detection is incorrect")
		quit(1)
		return
	if CombatRules.boss_display_name(3) == CombatRules.boss_display_name(6) or CombatRules.boss_display_name(6) == CombatRules.boss_display_name(9):
		push_error("Boss encounters must have distinct identities")
		quit(1)
		return
	print("Campaign smoke test passed: nine waves, three chapters and three unique boss encounters")
	quit(0)
