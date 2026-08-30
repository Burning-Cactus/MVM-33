extends EnemyBase

var radius: float
var _knockback_delta: float = 0.0

func _ready():
	super._ready()
	
	radius = $CollisionShape3D.shape.radius

func _physics_process(delta):
	apply_gravity(delta)
	
	if not is_in_knockback and not is_turning and is_on_floor():
		velocity.z = move_toward(velocity.z, direction * speed, speed * delta * 2)
	else:
		velocity.z = move_toward(velocity.z, 0, speed * delta * 2)
	
	var angular: float = velocity.z / radius
	visuals.rotation.x += angular * delta
	visuals.rotation.x = wrapf(visuals.rotation.x, 0.0, TAU)
	
	handle_patrol_turning()
	lock_to_25d_plane()
	move_and_slide()
	handle_3d_rotation(delta)

func handle_3d_rotation(delta: float):
	if is_in_knockback:
		if _knockback_delta < knockback_duration / 2.0:
			_knockback_delta += delta
			var weight: float = minf(1.0, _knockback_delta / (knockback_duration / 2.0))
			visuals.rotation.y = lerp_angle(0.0, PI, weight)
		else:
			_knockback_delta += delta
			
			var weight: float = _knockback_delta - (knockback_duration / 2.0)
			weight = minf(1.0, weight / (knockback_duration / 2.0))
			
			visuals.rotation.y = lerp_angle(PI, 2 * PI, weight)
			
			if _knockback_delta > knockback_duration:
				visuals.rotation.y = 0
	
func apply_knockback(damage_amount: int, source_position:float):
	_knockback_delta = 0.0
	super.apply_knockback(damage_amount, source_position)
	
	var direction_ = sign(global_position.z - source_position)
	if direction != direction_:
		flip_direction()
