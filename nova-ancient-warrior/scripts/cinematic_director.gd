extends RefCounted
## Small reusable camera-reveal primitive for boss and chapter introductions.
static func play_camera_reveal(camera: Camera3D, subject: Node3D, return_position: Vector3, return_target: Vector3, duration: float = 2.8) -> Tween:
	if not is_instance_valid(camera) or not is_instance_valid(subject):
		return null
	var return_rotation := camera.rotation
	var return_fov := camera.fov
	var reveal_position := subject.global_position + Vector3(4.2, 3.0, 5.4)
	camera.global_position = reveal_position
	camera.look_at(subject.global_position + Vector3(0.0, 1.25, 0.0), Vector3.UP)
	var reveal_rotation := camera.rotation
	camera.global_position = return_position
	camera.look_at(return_target, Vector3.UP)
	return_rotation = camera.rotation
	camera.fov = 48.0
	camera.global_position = reveal_position
	camera.rotation = reveal_rotation
	var tween := camera.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", subject.global_position + Vector3(3.2, 2.6, 4.0), duration * 0.28)
	tween.parallel().tween_property(camera, "fov", 42.0, duration * 0.28)
	tween.tween_interval(duration * 0.20)
	tween.tween_property(camera, "global_position", return_position, duration * 0.42)
	tween.parallel().tween_property(camera, "rotation", return_rotation, duration * 0.42)
	tween.parallel().tween_property(camera, "fov", return_fov, duration * 0.42)
	return tween
