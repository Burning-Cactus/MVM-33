extends EnemyBase

@export_enum("Two:0", "Four:1") var golem_type: int = 0
@export var player_stop_distance: float = 4.0
@export var projectile: PackedScene = null

@onready var golem_body_2: MeshInstance3D = $Visuals/Model/Armature_002/Skeleton3D/FLOATING_GOLEM_BODY
@onready var golem_body_4: MeshInstance3D = $Visuals/Model/Armature_002/Skeleton3D/FLOATING_GOLEM_2_BODY

var _is_too_close: bool = false

func _ready() -> void:
	super._ready()
	
	if golem_type == 0:
		golem_body_4.visible = false
	else:
		golem_body_2.visible = false
	
	damage_area.body_entered.connect(_on_body_entered_damage_area)
	damage_area.body_exited.connect(_on_body_exited_damage_area)
	
func _physics_process(delta):
	if not is_in_knockback and is_chasing:
		var diff: Vector3 = (player_ref.global_position - global_position)
				
		if diff.length() > player_stop_distance:
			if floor_check and floor_check.is_colliding() and diff.y < 0.0:
				velocity.z = (diff.normalized() * speed).z
				velocity.y = move_toward(velocity.y, 0, speed * delta)
			else:
				velocity = diff.normalized() * speed
				
			play_animation(&"idle")
		elif _is_too_close: # Prevent the player from getting stuck on it
			velocity = diff.normalized() * -1.0 * speed
			play_animation(&"idle")
		else:
			velocity = velocity.move_toward(Vector3(0.0, 0.0, 0.0), speed * delta)
			play_animation(&"attack")
	else:
		velocity = velocity.move_toward(Vector3(0.0, 0.0, 0.0), speed * delta)
		play_animation(&"idle")
	
	if is_chasing:
		handle_chase_turning()
		
	lock_to_25d_plane()
	move_and_slide()
	handle_3d_rotation(delta)

func _on_body_entered_damage_area(body: Node3D) -> void:
	_is_too_close = true
	
func _on_body_exited_damage_area(body: Node3D) -> void:
	_is_too_close = false
