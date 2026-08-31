extends EnemyBase

@export var chase_duration: float = 10.0

var radius: float
var _knockback_delta: float = 0.0
var _chase_started: bool = false
var _chase_delta: float = 0.0

func _ready():
	super._ready()
	
	radius = $CollisionShape3D.shape.radius

func _physics_process(delta):
	apply_gravity(delta)
	
	if not is_in_knockback and not is_turning and is_on_floor() and _chase_started:
		velocity.z = move_toward(velocity.z, direction * speed, speed * delta * 2)
	else:
		velocity.z = move_toward(velocity.z, 0, speed * delta * 2)
	
	var angular: float = velocity.z / radius
	visuals.rotation.x += angular * delta
	visuals.rotation.x = wrapf(visuals.rotation.x, 0.0, TAU)
	visuals.rotation.z = 0

	
	if is_chasing:
		_chase_delta = 0.0
		if not _chase_started:
			_chase_started = true
			handle_chase_turning()
		else:
			handle_patrol_turning()
	else:
		if _chase_started:
			_chase_delta += delta
			if _chase_delta > chase_duration:
				_chase_started = false
		handle_patrol_turning()
		
	lock_to_25d_plane()
	move_and_slide()
	handle_3d_rotation(delta)

func handle_3d_rotation(delta: float):
	if is_in_knockback:
		if is_zero_approx(_knockback_delta):
			visuals.rotation.y = 0
			
		_knockback_delta += delta
		
		if _knockback_delta > knockback_duration:
			visuals.rotation.y = 0
		else:
			var weight: float = minf(1.0, _knockback_delta / knockback_duration)
			weight = smoothstep(0.0, 2.0, weight + 1.0)
			weight = (weight - 0.5) * 2.0
			visuals.rotation.y = lerp_angle(0.0, PI, weight) * 2
	else:
		visuals.rotation.y = 0
		
	
func apply_knockback(damage_amount: int, source_position:float):
	if is_in_knockback:
		play_animation(&"hurt")
		return
		
	_knockback_delta = 0.0
	
	super.apply_knockback(damage_amount, source_position)
	
	var direction_ = sign(global_position.z - source_position)
	if direction != direction_:
		flip_direction()
