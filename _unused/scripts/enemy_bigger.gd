extends EnemyBase

@export var chase_speed: float = 2.2 # Relatively slow chase speed

var player_in_melee_range: bool = false

@onready var melee_range_zone = $MeleeRange

func setup_enemy():
	speed = 1.2 # Slow deliberate patrol pacing
	max_health = 100
	attack_damage = 25
	attack_cooldown = 2.0
	
	melee_range_zone.body_entered.connect(_on_melee_entered)
	melee_range_zone.body_exited.connect(_on_melee_exited)

func _physics_process(delta):
	apply_gravity(delta)
	
	if is_chasing and player_ref:
		direction = sign(player_ref.global_position.z - global_position.z)
	
		if player_in_melee_range:
			velocity.z = 0 
			if can_attack:
				execute_heavy_slam()
		else:
			velocity.z = direction * chase_speed
			play_animation("walk")
	else:
		velocity.z = direction * speed
		play_animation("walk")
		handle_patrol_turning()

	lock_to_25d_plane()
	move_and_slide()
	handle_3d_rotation(delta)

func execute_heavy_slam():
	can_attack = false
	play_animation("attack")

	await get_tree().create_timer(0.4).timeout 
	
	if player_in_melee_range:
		player_ref.take_damage(attack_damage,global_position.z)

	await get_tree().create_timer(attack_cooldown - 0.4).timeout
	can_attack = true

func _on_melee_entered(body):
	if body is Player:
		player_in_melee_range = true

func _on_melee_exited(body):
	if body == player_ref:
		player_in_melee_range = false
