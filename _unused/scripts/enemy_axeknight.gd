extends EnemyBase

const AXE_PROJECTILE = preload("uid://cpyadvsd3mfno")
@onready var marker_3d: Marker3D = $Visuals/Marker3D

func setup_enemy():
	speed = 2.0
	max_health = 40

func _physics_process(delta):
	apply_gravity(delta)
	
	if is_chasing and player_ref:
		# Face player securely
		direction = sign(player_ref.global_position.x - global_position.x)
		velocity.z = 0 # Halt walking completely to execute stance attack
		
		if can_attack:
			throw_axe()
	else:
		velocity.z = direction * speed
		play_animation("walk")
		handle_patrol_turning()
		
	lock_to_25d_plane()
	move_and_slide()
	handle_3d_rotation(delta)

func throw_axe():
	can_attack = false
	play_animation("attack")

	if AXE_PROJECTILE:
		var axe = AXE_PROJECTILE.instantiate()
		get_parent().add_child(axe) 
		
		# Set trajectory location parameters
		axe.global_position = marker_3d.global_position
		axe.spawn_z_position = marker_3d.global_position.z
		axe.launch(direction) # Pass current forward facing sign (+1 or -1)
		
	# Wait for cooldown timer framework
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
