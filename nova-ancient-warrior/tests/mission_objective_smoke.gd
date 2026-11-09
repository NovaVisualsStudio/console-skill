extends SceneTree

const MissionObjectives = preload("res://scripts/mission_objective_director.gd")


func _initialize() -> void:
	var parent := Node3D.new()
	root.add_child(parent)
	var previous_positions: Array[Vector3] = []
	for stage_index in range(3):
		var positions := MissionObjectives.relic_positions(stage_index)
		assert(positions.size() == 3, "Each chapter must expose three seal fragments")
		var sequence := MissionObjectives.relic_sequence(stage_index)
		assert(sequence.size() == 3, "Each chapter needs a three-step seal puzzle")
		assert(sequence.has(1) and sequence.has(2) and sequence.has(3), "Seal sequence must use each carved number exactly once")
		for position in positions:
			assert(absf(position.x) <= 16.0 and absf(position.z) <= 16.0, "Relic must remain inside the playable arena")
			assert(not previous_positions.has(position) or stage_index == 0, "Chapter layouts should not reuse identical relic placements")
		previous_positions = positions
		var relics := MissionObjectives.build_stage(parent, stage_index)
		assert(relics.size() == 3, "Stage builder must create all three relic visuals")
		for relic in relics:
			assert(relic.get_node_or_null("SealPedestal") != null, "Each relic must have a readable pedestal")
			assert(relic.get_node_or_null("SealBeacon") != null, "Each relic must have a vertical discovery beacon")
			var rune_material := relic.get_meta("rune_material") as StandardMaterial3D
			assert(rune_material != null, "Each relic must own its highlight material")
			var expected := int(relic.get_meta("sequence_order", 0)) == sequence[0]
			assert(is_equal_approx(rune_material.emission_energy_multiplier, 2.2 if expected else 0.55), "Only the next required seal should glow strongly")
		MissionObjectives.set_expected_order(relics, sequence[1])
		for relic in relics:
			var rune_material := relic.get_meta("rune_material") as StandardMaterial3D
			var expected := int(relic.get_meta("sequence_order", 0)) == sequence[1]
			assert(is_equal_approx(rune_material.emission_energy_multiplier, 2.2 if expected else 0.55), "Highlight must advance to the next seal")
		assert(MissionObjectives.collect(relics[0]), "First collection must succeed")
		assert(not MissionObjectives.collect(relics[0]), "Collected relic must not be collectible twice")
		assert(not relics[0].visible, "Collected relic must disappear")
	MissionObjectives.clear_stage(parent)
	assert(parent.get_node_or_null("GeneratedMissionRelics") == null, "Boss-wave resume must clear relic objectives")
	parent.queue_free()
	print("Mission objective smoke test passed: three chapter layouts, relic creation and one-time collection")
	quit(0)
