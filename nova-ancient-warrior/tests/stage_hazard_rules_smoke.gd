extends SceneTree

const StageHazardRules = preload("res://scripts/stage_hazard_rules.gd")


func _initialize() -> void:
	var sunken_warning := StageHazardRules.query(0, Vector3(0.0, 0.0, 8.4), 0.4)
	if not bool(sunken_warning.get("warning", false)) or bool(sunken_warning.get("active", false)):
		_fail("Sunken Ruins spikes must warn before striking")
		return
	var sunken := StageHazardRules.query(0, Vector3(0.0, 0.0, 8.4), 1.1)
	if not bool(sunken.get("active", false)) or int(sunken.get("damage", 0)) != 10:
		_fail("Sunken Ruins spike line did not damage during its strike window")
		return
	var sunken_cool := StageHazardRules.query(0, Vector3(0.0, 0.0, 8.4), 1.8)
	if bool(sunken_cool.get("active", false)):
		_fail("Sunken Ruins spike trap remained active outside its strike window")
		return
	var sunken_safe := StageHazardRules.query(0, Vector3(8.0, 0.0, 8.4), 1.1)
	if bool(sunken_safe.get("warning", false)) or bool(sunken_safe.get("active", false)):
		_fail("Sunken Ruins spike line affected the safe outer route")
		return

	var lava_warning := StageHazardRules.query(1, Vector3(-4.48, 0.0, 0.0), 0.4)
	if not bool(lava_warning.get("warning", false)) or bool(lava_warning.get("active", false)):
		_fail("Ember Causeway lava channels must warn before striking")
		return
	var lava := StageHazardRules.query(1, Vector3(-4.48, 0.0, 0.0), 1.3)
	if not bool(lava.get("active", false)) or int(lava.get("damage", 0)) != 10:
		_fail("Ember Causeway lava channel did not strike during its active window")
		return
	var lava_cool := StageHazardRules.query(1, Vector3(-4.48, 0.0, 0.0), 2.2)
	if bool(lava_cool.get("active", false)):
		_fail("Ember Causeway lava channel remained active outside its strike window")
		return
	var lava_bridge := StageHazardRules.query(1, Vector3.ZERO, 1.3)
	if bool(lava_bridge.get("warning", false)) or bool(lava_bridge.get("active", false)):
		_fail("Ember Causeway central bridge must remain safe")
		return
	var lava_end := StageHazardRules.query(1, Vector3(-4.48, 0.0, 11.0), 1.3)
	if bool(lava_end.get("warning", false)) or bool(lava_end.get("active", false)):
		_fail("Ember Causeway lava damage escaped the channel length")
		return

	var rune_warning := StageHazardRules.query(2, Vector3(-4.0, 0.0, -1.5), 0.5)
	if not bool(rune_warning.get("warning", false)) or bool(rune_warning.get("active", false)):
		_fail("Obsidian runes must telegraph before striking")
		return
	var rune_active := StageHazardRules.query(2, Vector3(-4.0, 0.0, -1.5), 1.5)
	if not bool(rune_active.get("active", false)) or int(rune_active.get("damage", 0)) != 14:
		_fail("Obsidian rune pulse did not apply its strike window")
		return
	var rune_cool := StageHazardRules.query(2, Vector3(-4.0, 0.0, -1.5), 2.2)
	if bool(rune_cool.get("active", false)):
		_fail("Obsidian rune pulse remained active beyond its window")
		return
	var rune_bridge := StageHazardRules.query(2, Vector3(0.0, 0.0, -1.5), 1.5)
	if bool(rune_bridge.get("active", false)):
		_fail("Obsidian Throne central route must remain safe")
		return

	print("Stage hazard smoke test passed: all chapters telegraph timed hazards and preserve safe routes")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
