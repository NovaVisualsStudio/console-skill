extends SceneTree

const CameraRig = preload("res://scripts/third_person_camera_rig.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world_root := Node3D.new()
	root.add_child(world_root)
	var wall := StaticBody3D.new()
	wall.name = "CameraOcclusionWall"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5.0, 4.0, 0.5)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0.0, 1.0, 3.0)
	world_root.add_child(wall)
	await physics_frame
	await physics_frame

	var origin := Vector3(0.0, 1.0, 0.0)
	var desired := Vector3(0.0, 1.0, 7.0)
	var exclusions: Array[RID] = []
	var resolved: Vector3 = CameraRig.resolve_position(
		world_root.get_world_3d(), origin, desired, exclusions
	)
	if resolved.distance_to(origin) >= desired.distance_to(origin):
		_fail("Camera collision must shorten the camera arm when a wall blocks the view")
		return
	if resolved.z >= 2.8:
		_fail("Camera must remain in front of the occluding wall")
		return

	var clear_origin := Vector3(8.0, 1.0, 0.0)
	var clear_desired := Vector3(8.0, 1.0, 7.0)
	var clear_result: Vector3 = CameraRig.resolve_position(
		world_root.get_world_3d(), clear_origin, clear_desired, exclusions
	)
	if not clear_result.is_equal_approx(clear_desired):
		_fail("Camera must preserve its desired offset when the line of sight is clear")
		return

	world_root.queue_free()
	print("Third-person camera collision smoke test passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
