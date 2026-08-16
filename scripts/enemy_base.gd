extends CharacterBody3D
class_name EnemyBase

@export_group("Base Movement")
@export var speed: float = 3.0
@export var rotation_speed: float = 15.0

@export_group("Combat Attributes")
@export var max_health: int = 20
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.5

@export_group("Knockback Settings")
@export var has_knockback: bool = true
@export var knockback_force: float = 6.0
@export var knockback_duration: float = 0.25

var unique_enemy_id: String = ""
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_health: int
var direction: int = 1 # 1 = Right (+X), -1 = Left (-X)
var is_chasing: bool = false
var is_in_knockback: bool = false 
var can_attack: bool = true

var player_ref: CharacterBody3D = null


@onready var visuals: Node3D = $Visuals
@onready var anim_player: AnimationPlayer = $Visuals/AnimationPlayer
@onready var floor_check: RayCast3D = $FloorCheck
@onready var detector: Area3D = $PlayerDetection

func _ready():
	current_health = max_health
	if detector:
		detector.body_entered.connect(_on_player_detected)
		detector.body_exited.connect(_on_player_lost)
	#generate ID, if its already on the defeated enemy list we despawn the enemy
	var room_name = get_tree().current_scene.name
	unique_enemy_id = room_name + "_" + name
	if GameManager.defeated_enemies.has(unique_enemy_id):
		queue_free()
		return
		
	setup_enemy()

# Override this in specific enemy scripts if they need extra setup
func setup_enemy():
	pass

func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_patrol_turning():
	# Turn around if hitting a vertical 3D wall, or about to walk off an edge
	if is_on_wall() or (floor_check and not floor_check.is_colliding()):
		flip_direction()

func flip_direction():
	direction *= -1
	if floor_check:
		floor_check.position.z = direction * 0.6

func handle_3d_rotation(delta: float):
	# Target angles: 0 rad for Right (+X), PI rad (180 deg) for Left (-X)
	var target_y_rot = 0.0 if direction > 0 else PI
	visuals.rotation.y = rotate_toward(visuals.rotation.y, target_y_rot, rotation_speed * delta)

func lock_to_25d_plane():
	velocity.x = 0
	global_transform.origin.x = 0

func play_animation(anim_name: String):
	if anim_player and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)

func take_damage(amount: int,source_position: float):
	current_health -= amount
	print(amount, " damage taken, ", current_health, " left.")
	if current_health <= 0:
		die()
		return
	if has_knockback:
		apply_knockback(source_position)
	else:
		play_animation("hurt")
		
func die():
	if not GameManager.defeated_enemies.has(unique_enemy_id):
		GameManager.defeated_enemies.append(unique_enemy_id)
	#add death animation exp some drop or whatever here
	queue_free()

func _on_player_detected(body: Node3D):
	if body is Player:
		print("player spotted")
		is_chasing = true
		player_ref = body

func _on_player_lost(body: Node3D):
	print("player lost")
	if body == player_ref:
		is_chasing = false
		player_ref = null

func apply_knockback(source_position:float):
	is_in_knockback = true

	var knockback_dir = sign(global_position.z - source_position)
	if knockback_dir == 0: 
		knockback_dir = -direction

	velocity.z = knockback_dir * knockback_force
	velocity.y = knockback_force * 0.4 
	play_animation("hurt")

	await get_tree().create_timer(knockback_duration).timeout
	is_in_knockback = false
