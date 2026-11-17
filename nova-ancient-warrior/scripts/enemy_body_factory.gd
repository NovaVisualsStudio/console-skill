extends RefCounted
## Shared collision profile for melee enemies and bosses.

const ENEMY_COLLISION_LAYER := 2
const WORLD_AND_PLAYER_MASK := 1
const ENEMY_CAPSULE_RADIUS := 0.38
const ENEMY_CAPSULE_HEIGHT := 1.8


static func create_enemy_body() -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.collision_layer = ENEMY_COLLISION_LAYER
	body.collision_mask = WORLD_AND_PLAYER_MASK
	body.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	body.floor_snap_length = 0.18
	body.safe_margin = 0.04

	var collision := CollisionShape3D.new()
	collision.name = "EnemyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = ENEMY_CAPSULE_RADIUS
	capsule.height = ENEMY_CAPSULE_HEIGHT
	collision.shape = capsule
	collision.position.y = ENEMY_CAPSULE_HEIGHT * 0.5
	body.add_child(collision)
	return body
