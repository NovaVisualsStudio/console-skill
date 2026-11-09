extends SceneTree

const MissionObjectives = preload("res://scripts/mission_objective_director.gd")


func _initialize() -> void:
	var parent := Node3D.new()
	root.add_child(parent)
	var previous_positions: Array[Vector3] = []
	for stage_index in range(3):
		var positions := MissionObjectives.relic_positions(stage_index)
		assert(positions.size() == 3, "Each chapter must expose three seal fragments")
		for position in positions:
			assert(absf(position.x) <= 16.0 and absf(position.z) <= 16.0, "Relic must remain inside the playable arena")
			assert(not previous_positions.has(position) or stage_index == 0, "Chapter layouts should not reuse identical relic placements")
		previous_positions = positions
		var relics := MissionObjectives.build_stage(parent, stage_index)
		assert(relics.size() == 3, "Stage builder must create all three relic visuals")
		assert(MissionObjectives.collect(relics[0]), "First collection must succeed")
		assert(not MissionObjectives.collect(relics[0]), "Collected relic must not be collectible twice")
		assert(not relics[0].visible, "Collected relic must disappear")
	parent.queue_free()
	print("Mission objective smoke test passed: three chapter layouts, relic creation and one-time collection")
	quit(0)
