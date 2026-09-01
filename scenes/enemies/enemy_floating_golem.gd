extends EnemyBase

@export_enum("Two:2", "Four:4") var golem_type: int = 2
@export var target_stop_distance: Vector3 = Vector3(0.0, 2.0, 7.5)
@export var projectile: PackedScene = null

@onready var golem_body_2: MeshInstance3D = $Visuals/Model/Armature_002/Skeleton3D/FLOATING_GOLEM_2_BODY
@onready var golem_body_4: MeshInstance3D = $Visuals/Model/Armature_002/Skeleton3D/FLOATING_GOLEM_BODY
@onready var projectile_marker: Marker3D = $ProjectileMarker

var _is_too_close: bool = false
var attack_timer: Timer = null

func _ready() -> void:
	super._ready()
	
	if golem_type == 4:
		golem_body_4.visible = false
	else:
		golem_body_2.visible = false
	
	damage_area.body_entered.connect(_on_body_entered_damage_area)
	damage_area.body_exited.connect(_on_body_exited_damage_area)
	
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	add_child(attack_timer)
	
func _physics_process(delta):
	if not is_in_knockback and is_chasing:
		var diff: Vector3 = (player_ref.get_global_center() - global_position)
		
		if _is_too_close:
			# Prevent the player from getting stuck on it
			velocity = diff.normalized() * -1.0 * speed
			play_animation(&"idle")
		else:
			var is_close: bool = true
			
			if absf(diff.y) > target_stop_distance.y:
				if floor_check and floor_check.is_colliding() and diff.y < 0.0:
					velocity.y = move_toward(velocity.y, 0.0, speed * delta)
				else:
					is_close = false
					velocity.y = (diff.normalized() * speed).y
			else:
				velocity.y = move_toward(velocity.y, 0.0, speed * delta)
				
			if absf(diff.z) > target_stop_distance.z:
				is_close = false
				velocity.z = (diff.normalized() * speed).z
			else:
				velocity.z = move_toward(velocity.z, 0.0, speed * delta)
				
			if is_close:
				handle_attack()
			else:
				play_animation(&"idle")
	else:
		velocity = velocity.move_toward(Vector3(0.0, 0.0, 0.0), speed * delta)
		play_animation(&"idle")
	
	if is_chasing:
		handle_chase_turning()
		
	lock_to_25d_plane()
	move_and_slide()
	handle_3d_rotation(delta)
	
func handle_attack() -> void:
	if projectile == null:
		queue_animation(&"idle")
		return
	
	if not attack_timer.is_stopped():
		return
	
	attack_timer.start(attack_cooldown)
	
	play_animation(&"attack")
	queue_animation(&"idle")
	
	# Delay the projectile to match the animation
	await get_tree().create_timer(0.7).timeout
	
	var projectile_ = projectile.instantiate() as Node3D
	projectile_.global_position = projectile_marker.global_position
	projectile_.target = player_ref.get_global_center()
	get_parent().add_child(projectile_)
	
	if golem_type == 4:
		projectile_ = projectile.instantiate() as Node3D
		projectile_.global_position = projectile_marker.global_position
		projectile_.target = player_ref.get_global_center()
		projectile_.target.y += 1.25
		get_parent().add_child(projectile_)
		
		projectile_ = projectile.instantiate() as Node3D
		projectile_.global_position = projectile_marker.global_position
		projectile_.target = player_ref.get_global_center()
		projectile_.target.y -= 1.25
		get_parent().add_child(projectile_)

func _on_body_entered_damage_area(body: Node3D) -> void:
	_is_too_close = true
	
func _on_body_exited_damage_area(body: Node3D) -> void:
	_is_too_close = false

func flip_direction() -> void:
	super.flip_direction()
	
	projectile_marker.position.z = direction * absf(projectile_marker.position.z)
