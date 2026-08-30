extends EnemyBase

func _physics_process(delta):
	apply_gravity(delta)
	
	if not is_in_knockback and is_on_floor():
		velocity.z = direction * speed
		play_animation(&"walk")
	else:
		velocity.z = move_toward(velocity.z, 0, speed * delta)
		play_animation(&"idle")
	
	if is_chasing:
		handle_chasing()
	else:
		handle_patrol_turning()
		
	lock_to_25d_plane()
	move_and_slide()
	handle_3d_rotation(delta)
