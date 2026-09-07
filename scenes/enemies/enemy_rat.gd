extends EnemyBase

var attacking := false
@onready var bite_area: Area3D = $HeadBoneAttachment/BiteArea
@onready var attack_range: Area3D = $AttackRange

func _ready() -> void:
	super._ready()
	attack_range.body_entered.connect(_on_attack_range_entered)

func _physics_process(delta):
	apply_gravity(delta)
	
	if !attacking:
		if not is_in_knockback and is_on_floor():
			velocity.z = direction * speed
			play_animation(&"walk")
		else:
			velocity.z = move_toward(velocity.z, 0, speed * delta)
			play_animation(&"idle")
		
		if is_chasing:
			handle_chase_turning()
		else:
			handle_patrol_turning()
	
	lock_to_25d_plane()
	move_and_slide()
	handle_3d_rotation(delta)

# Override
func apply_knockback(damage_amount, source_position: float) -> void:
	super.apply_knockback(damage_amount, source_position)
	deactivate_hitbox()

func start_attack() -> void:
	attacking = true
	play_animation(&"attack")
	#await anim_player.animation_finished
	#attacking = false

func activate_hitbox() -> void:
	bite_area.monitoring = true

func deactivate_hitbox() -> void:
	bite_area.monitoring = false
	attacking = false

func _on_attack_range_entered(body: Node3D) -> void:
	if !attacking && body == player_ref:
		start_attack()
