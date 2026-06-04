extends Area2D

var speed: float = 1000.0

func _physics_process(delta: float) -> void:
	var step = Vector2.UP * speed * delta
	var target_pos = global_position + step
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target_pos)
	query.collision_mask = 1
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		if collider.is_in_group("paddle") or collider.is_in_group("ball"):
			global_position = target_pos
		else:
			if collider.has_method("take_damage"):
				collider.take_damage(1)
			queue_free()
	else:
		global_position = target_pos
	if global_position.y < -100:
		queue_free()
