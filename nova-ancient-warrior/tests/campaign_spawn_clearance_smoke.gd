extends SceneTree

const CampaignLayout = preload("res://scripts/campaign_layout.gd")
const CombatRules = preload("res://scripts/combat_rules.gd")

const PLAYER_SPAWN := Vector3(0.0, 0.0, 3.5)
const ACTOR_RADIUS := 0.46
const ACTOR_HEIGHT := 1.8


func _initialize() -> void:
	call_deferred("_run_spawn_clearance")


func _run_spawn_clearance() -> void:
	var root := Node3D.new()
	root.name = "SpawnClearanceSmoke"
	get_root().add_child(root)
	for chapter in range(3):
		CampaignLayout.build_stage(root, chapter, "mid")
		var layout := root.get_node_or_null("GeneratedCampaignLayout")
		if layout == null:
			_fail(root, "Missing campaign layout for chapter %d" % (chapter + 1))
			return
		var wave_start := chapter * CombatRules.WAVES_PER_CHAPTER + 1
		for wave in range(wave_start, wave_start + CombatRules.WAVES_PER_CHAPTER):
			var count := CombatRules.wave_enemy_count(wave)
			var boss_wave := CombatRules.is_boss_wave(wave)
			for index in range(count):
				var spawn := CombatRules.wave_enemy_spawn_position(wave, index)
				if _overlaps_blocker(layout, spawn):
					_fail(root, "Chapter %d wave %d enemy spawn %d intersects solid geometry at %s" % [chapter + 1, wave, index + 1, str(spawn)])
					return
		if chapter == 0 and _overlaps_blocker(layout, PLAYER_SPAWN):
			_fail(root, "Player start intersects solid geometry in chapter 1")
			return
	root.free()
	print("Campaign spawn-clearance smoke test passed: all 9 waves and player start are unobstructed")
	quit(0)


func _overlaps_blocker(layout: Node3D, spawn: Vector3) -> bool:
	for body in layout.get_children():
		if not body is StaticBody3D:
			continue
		var collision := body.get_node_or_null("Collision") as CollisionShape3D
		if collision == null or not collision.shape is BoxShape3D:
			continue
		var shape := collision.shape as BoxShape3D
		var center := collision.global_position
		var half := shape.size * 0.5
		if center.y + half.y <= 0.0 or center.y - half.y >= ACTOR_HEIGHT:
			continue
		var nearest_x := clampf(spawn.x, center.x - half.x, center.x + half.x)
		var nearest_z := clampf(spawn.z, center.z - half.z, center.z + half.z)
		var dx := spawn.x - nearest_x
		var dz := spawn.z - nearest_z
		if dx * dx + dz * dz < ACTOR_RADIUS * ACTOR_RADIUS:
			return true
	return false


func _fail(root: Node3D, message: String) -> void:
	push_error(message)
	root.free()
	quit(1)
