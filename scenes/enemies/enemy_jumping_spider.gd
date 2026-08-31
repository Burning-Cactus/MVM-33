extends EnemyBase

@export var jump_cooldown: float = 2.0
@export var jump_velocity: Vector3 = Vector3(0, 8.0, 5.0)

var _jump_delta: float = 0.0
var _jump_off: bool = false

func _ready():
	super._ready()
	
	damage_area.body_entered.connect(_on_body_enterd)

func _physics_process(delta):
	apply_gravity(delta)
	
	if not is_in_knockback and is_on_floor() and is_chasing:
		_jump_delta += delta
		if _jump_delta > jump_cooldown:
			_jump_delta = 0.0
			
			var cancel_z = randi_range(0, 3)
			
			velocity = jump_velocity
			
			if cancel_z == 1:
				velocity.y = jump_velocity.y / 1.5
			
			
			if cancel_z == 0:
				velocity.z = 0.0	
			else:
				velocity.z *= direction
			play_animation(&"jump")
	elif _jump_off:
		_jump_off = false
		velocity = jump_velocity
		velocity.y /= 2.0
		velocity.z *= direction * -1.0
		play_animation(&"jump")
	else:
		if not is_chasing:
			_jump_delta = jump_cooldown / 2.0
		play_animation(&"idle")
	
	velocity.z = move_toward(velocity.z, 0, speed * delta)
	
	handle_chase_turning()
	lock_to_25d_plane()
	move_and_slide()
	handle_3d_rotation(delta)

func handle_chase_turning() -> void:
	if is_on_floor():
		super.handle_chase_turning()
		
func flip_direction():
	super.flip_direction()
	
	var position: float = absf($CollisionShape3D.position.z)
	print(position * direction * -1.0)
	$CollisionShape3D.position.z = position * direction * -1.0
	
	for child in damage_area.get_children():
		if child is CollisionShape3D:
			child.position.z = $CollisionShape3D.position.z

func _on_body_enterd(body: Node3D) -> void:
	if body.is_in_group(&"Player"):
		_jump_off = true
