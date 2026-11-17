extends SceneTree

const EnemyBodyFactory = preload("res://scripts/enemy_body_factory.gd")


func _initialize() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var root := Node3D.new()
	root.name = "EnemyPhysicsSmoke"
	get_root().add_child(root)

	var floor := StaticBody3D.new()
	floor.name = "TestFloor"
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(12.0, 0.5, 12.0)
	floor_collision.shape = floor_shape
	floor_collision.position.y = -0.25
	floor.add_child(floor_collision)
	root.add_child(floor)

	var wall := StaticBody3D.new()
	wall.name = "TestWall"
	var wall_collision := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(5.0, 3.0, 0.4)
	wall_collision.shape = wall_shape
	wall.add_child(wall_collision)
	root.add_child(wall)

	var enemy := EnemyBodyFactory.create_enemy_body()
	enemy.name = "TestEnemy"
	enemy.position = Vector3(0.0, 0.0, 2.0)
	root.add_child(enemy)
	await physics_frame

	if enemy.collision_layer != EnemyBodyFactory.ENEMY_COLLISION_LAYER or enemy.collision_mask != EnemyBodyFactory.WORLD_AND_PLAYER_MASK:
		_fail(root, "Enemy collision layer and mask must isolate enemies while detecting the world and player")
		return
	var shape := enemy.get_node_or_null("EnemyCollision") as CollisionShape3D
	if shape == null or not shape.shape is CapsuleShape3D:
		_fail(root, "Every enemy must have a capsule collision shape")
		return

	for frame in range(36):
		enemy.velocity = Vector3(0.0, 0.0, -4.0)
		enemy.move_and_slide()
		await physics_frame
	if enemy.global_position.z < 0.48:
		_fail(root, "Enemy moved through a solid wall instead of stopping at the collision boundary")
		return
	if enemy.global_position.z > 1.6:
		_fail(root, "Enemy did not approach the wall as expected during the collision test")
		return

	root.free()
	print("Enemy physics smoke test passed: capsule collision, world blocking and enemy collision-layer isolation")
	quit(0)


func _fail(root: Node3D, message: String) -> void:
	push_error(message)
	root.free()
	quit(1)
