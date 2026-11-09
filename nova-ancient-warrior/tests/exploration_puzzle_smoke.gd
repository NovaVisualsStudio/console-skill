extends SceneTree

const ExplorationPuzzleDirector = preload("res://scripts/exploration_puzzle_director.gd")


func _initialize() -> void:
	call_deferred("_run_puzzle_smoke")


func _run_puzzle_smoke() -> void:
	var root := Node3D.new()
	root.name = "ExplorationPuzzleSmoke"
	get_root().add_child(root)
	for chapter in range(3):
		var runes := ExplorationPuzzleDirector.build_stage(root, chapter)
		if runes.size() != 3:
			_fail(root, "Chapter %d must contain exactly three runes" % chapter)
			return
		for rune in runes:
			if not rune is StaticBody3D or rune.find_children("*", "CollisionShape3D", true, false).size() < 3:
				_fail(root, "Every rune must have pedestal, column and crystal collision shapes")
				return
		if root.get_child_count() != 1:
			_fail(root, "Rebuilding a chapter must not leave duplicate puzzle roots")
			return
		var sequence := ExplorationPuzzleDirector.sequence_for_stage(chapter)
		if sequence.size() != 3 or sequence[0] == sequence[1] or sequence[1] == sequence[2] or sequence[0] == sequence[2]:
			_fail(root, "Chapter %d sequence must contain three unique rune indices" % chapter)
			return
		var hint := root.get_node_or_null("GeneratedExplorationPuzzle/PuzzleSequenceHint") as Label3D
		if hint == null or (not hint.text.contains("ANCIENT ORDER") and not hint.text.contains("ترتيب الرموز")):
			_fail(root, "Chapter %d must visibly communicate the rune order" % chapter)
			return
		var wrong_rune := (sequence[0] % 3) + 1
		var rejected := ExplorationPuzzleDirector.evaluate_rune(wrong_rune, 0, sequence)
		if bool(rejected.get("accepted", true)) or int(rejected.get("progress", -1)) != 0:
			_fail(root, "Out-of-order rune must be rejected without advancing puzzle progress")
			return
		ExplorationPuzzleDirector.set_expected_order(runes, sequence[0])
		var expected_material := runes[sequence[0] - 1].get_meta("rune_material") as StandardMaterial3D
		if expected_material == null or not is_equal_approx(expected_material.emission_energy_multiplier, 2.35):
			_fail(root, "The next rune in the sequence must be visibly highlighted")
			return
		for step in range(sequence.size()):
			var rune := runes[sequence[step] - 1]
			var accepted := ExplorationPuzzleDirector.evaluate_rune(sequence[step], step, sequence)
			if not bool(accepted.get("accepted", false)) or int(accepted.get("progress", -1)) != step + 1 or bool(accepted.get("solved", false)) != (step == sequence.size() - 1):
				_fail(root, "Correct sequence input must advance and solve the puzzle at exactly the third rune")
				return
			if not ExplorationPuzzleDirector.activate(rune):
				_fail(root, "A rune in the chapter sequence should activate once")
				return
			if ExplorationPuzzleDirector.activate(rune):
				_fail(root, "An activated rune must not activate twice")
				return
			if step + 1 < sequence.size():
				ExplorationPuzzleDirector.set_expected_order(runes, sequence[step + 1])
		var after_solve := ExplorationPuzzleDirector.evaluate_rune(sequence[0], sequence.size(), sequence)
		if bool(after_solve.get("accepted", true)) or not bool(after_solve.get("solved", false)):
			_fail(root, "Solved puzzles must reject additional sequence inputs")
			return
		if bool(root.get_node("GeneratedExplorationPuzzle").get_meta("solved", false)):
			_fail(root, "The puzzle director must not mark a puzzle solved before gameplay confirms the final sequence")
			return
	root.free()
	print("Exploration puzzle smoke test passed: all three chapter sequences, visible clues, next-rune highlighting and one-time activation")
	quit(0)


func _fail(root: Node3D, message: String) -> void:
	push_error(message)
	root.free()
	quit(1)
