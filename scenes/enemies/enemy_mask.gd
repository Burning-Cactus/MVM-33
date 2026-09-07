extends EnemyBase

@export var target_stop_distance: Vector3 = Vector3(0.0, 2.25, 0.0)
@export var projectile: PackedScene = null
@onready var player_detection_collision: CollisionShape3D = $PlayerDetection/CollisionShape3D

@onready var projectile_marker: Marker3D = $ProjectileMarker

var _is_too_close: bool = false
var attack_timer: Timer = null

func _ready() -> void:
	super._ready()
	
	damage_area.body_entered.connect(_on_body_entered_damage_area)
	damage_area.body_exited.connect(_on_body_exited_damage_area)
	
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	add_child(attack_timer)
	
func _physics_process(delta):
	play_animation(&"idle")
			
	if not is_in_knockback and is_chasing:
		var diff: Vector3 = (player_ref.get_global_center() - global_position)
		
		if _is_too_close:
			# Prevent the player from getting stuck on it
			print(diff)
			velocity = diff.normalized() * -1.0 * speed
		else:
			if absf(diff.y) > target_stop_distance.y:
				if floor_check and floor_check.is_colliding() and diff.y < 0.0:
					velocity.y = move_toward(velocity.y, 0.0, speed * delta)
				else:
					velocity.y = (diff.normalized() * speed).y
			else:
				velocity.y = move_toward(velocity.y, 0.0, speed * delta)
				
			if absf(diff.z) > target_stop_distance.z:
				velocity.z = (diff.normalized() * speed).z
			else:
				velocity.z = move_toward(velocity.z, 0.0, speed * delta)
				
		handle_attack()
	else:
		velocity = velocity.move_toward(Vector3(0.0, 0.0, 0.0), speed * delta)
	
	if is_chasing:
		handle_chase_turning()
		
	lock_to_25d_plane()
	move_and_slide()
	handle_3d_rotation(delta)
	
func handle_3d_rotation(delta: float):
	if is_chasing:
		super.handle_3d_rotation(delta)
	else:
		var target_y_rot = PI / 2.0
		visuals.rotation.y = rotate_toward(visuals.rotation.y, target_y_rot, rotation_speed * delta)
	
func handle_attack() -> void:
	if projectile == null:
		return
	
	if not attack_timer.is_stopped():
		return
	
	attack_timer.start(attack_cooldown)
	
	var projectile_ = projectile.instantiate() as Node3D
	projectile_.global_position = projectile_marker.global_position
	# Target downwards
	projectile_.target = global_position + Vector3(0.0, -999, 0.0)
	get_parent().add_child(projectile_)

func _on_body_entered_damage_area(body: Node3D) -> void:
	_is_too_close = true
	
func _on_body_exited_damage_area(body: Node3D) -> void:
	_is_too_close = false

func flip_direction() -> void:
	super.flip_direction()
	
	projectile_marker.position.z = direction * absf(projectile_marker.position.z)

func _on_player_detected(body: Node3D):
	super._on_player_detected(body)
	if is_chasing:
		player_detection_collision.shape.size.z = 15.0

func _on_player_lost(body: Node3D):
	super._on_player_lost(body)
	if not is_chasing:
		player_detection_collision.shape.size.z = 10.0
