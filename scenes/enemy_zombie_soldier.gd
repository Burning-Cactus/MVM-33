extends EnemyBase

func setup_enemy():
	speed = 1.5 # Very slow walking speed
	max_health = 15

func _physics_process(delta):
	apply_gravity(delta)
	
	if not is_in_knockback:
		if is_chasing:
			var target_dir = (player_ref.global_position - global_position).normalized()
			velocity.z = target_dir.z * speed
		else:
			velocity.z = direction * speed
	else:
		velocity.z = move_toward(velocity.z, 0, speed * delta * 2)
		
	play_animation("walk")
	handle_patrol_turning()
	lock_to_25d_plane()
	move_and_slide()
	handle_3d_rotation(delta)
	
	# Deal contact damage directly
	handle_contact_damage()

func handle_contact_damage():
	# Simple check: if a 3D wall collision is actually the player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var obj = collision.get_collider()
		if obj and obj.is_in_group("player"):
			GameManager.update_health(-attack_damage)
