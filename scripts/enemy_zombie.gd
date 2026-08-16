extends EnemyBase

func setup_enemy():
	speed = 1.5 # Very slow walking speed
	max_health = 15

func _physics_process(delta):
	apply_gravity(delta)
	if not is_in_knockback:
		
		velocity.z = direction * speed
		play_animation("walk")
	else:
		velocity.z = move_toward(velocity.z, 0, speed * delta * 2)
	
	
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
