extends EnemyBase

@export var fly_chase_speed: float = 4.5

func setup_enemy():
	speed = 2.0
	max_health = 8

func _physics_process(delta):

	if not is_in_knockback:
		if is_chasing and player_ref:
			var target_dir = (player_ref.global_position - global_position).normalized()
			velocity.z = target_dir.z * fly_chase_speed
			velocity.y = target_dir.y * fly_chase_speed
			
			# Keep visual facing aligned with current travel direction
			direction = 1 if velocity.x > 0 else -1
			play_animation("fly_fast")
		else:
			# Idle air patrol
			velocity.z = direction * speed
			velocity.y = 0 
			play_animation("fly_idle")

			if is_on_wall():
				flip_direction()
	else:
		velocity.z = move_toward(velocity.z, 0, speed * delta * 2)
	
			
	lock_to_25d_plane()
	move_and_slide()
	handle_3d_rotation(delta)
