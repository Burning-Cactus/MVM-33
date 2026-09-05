extends CharacterBody3D
class_name EnemyBase

@export var is_boss: bool = false
@export var label: StringName = &""

@export_group("Base Movement")
@export var speed: float = 3.0
@export var rotation_speed: float = 15.0
@export_enum("Left:1", "Right:-1") var start_direction: int = 1

@export_group("Combat Attributes")
@export var max_health: int = 20
@export var attack_damage: int = 10 # DamageArea grabs this value
@export var attack_cooldown: float = 1.5 # DamageArea grabs this value

@export_group("Knockback Settings")
@export var has_knockback: bool = true
@export var knockback_force: Vector3 = Vector3(0, 2.4, 6.0)
@export var knockback_duration: float = 0.25
@export var knockback_min_damage: int = 0

@export_group("Turning Settings")
@export var turning_duration: float = 0.5

@export_group("Animations")
@export var model_animations: Dictionary[StringName, ModelAnimation] = {}

var unique_enemy_id: String = ""
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_health: int
var direction: int = 1 # 1 = Right (+X), -1 = Left (-X)
var is_chasing: bool = false
var is_in_knockback: bool = false 
var is_turning: bool = false
var can_attack: bool = true
var floor_check_disabled: bool = false

var damage_timer: Timer
var is_invincible: bool = false
var damage_cooldown: float = 1.0
var current_damage_step: int = 0

var player_ref: CharacterBody3D = null

@onready var visuals: Node3D = $Visuals
@onready var model: Node3D = $Visuals/Model
@onready var floor_check: RayCast3D = $FloorCheck
@onready var detector: Area3D = $PlayerDetection
@onready var damage_area: DamageArea = $DamageArea

var anim_player: AnimationPlayer = null

signal death

func _ready():
	current_health = max_health
	if detector:
		detector.body_entered.connect(_on_player_detected)
		detector.body_exited.connect(_on_player_lost)
	#generate ID, if its already on the defeated enemy list we despawn the enemy
	var room_name = get_tree().current_scene.name
	unique_enemy_id = room_name + "_" + name
	
	if is_boss:
		if GameManager.permanent_flags.has(unique_enemy_id + "_defeated"):
			queue_free()
			return
	elif GameManager.defeated_enemies.has(unique_enemy_id):
		queue_free()
		return
	
	if model != null:
		anim_player = model.get_node_or_null("AnimationPlayer")
	
	if anim_player != null:
		anim_player.animation_changed.connect(_on_animation_changed)
	
	damage_timer = Timer.new()
	damage_timer.one_shot = true
	damage_timer.timeout.connect(_on_damage_end)
	add_child(damage_timer)
	
	setup_enemy()
	
	direction = start_direction
	flip_direction()

# Override this in specific enemy scripts if they need extra setup
func setup_enemy():
	pass

func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_chase_turning() -> void:
	if not is_chasing or not player_ref:
		return
	
	if player_ref.position.z < position.z:
		if direction != -1:
			flip_direction()
	else:
		if direction != 1:
			flip_direction()

func handle_patrol_turning():
	# Turn around if hitting a vertical 3D wall, or about to walk off an edge
	if is_on_wall():
		is_turning = true
			
		var normal = get_wall_normal()
		
		if normal.z > 0 and direction != 1:
			flip_direction()
		elif normal.z < 0 and direction != -1:
			flip_direction()
			
		if not is_zero_approx(turning_duration):
			await get_tree().create_timer(turning_duration).timeout
			
		is_turning = false
	elif (floor_check and not floor_check.is_colliding() and not floor_check_disabled):
		is_turning = true
		
		flip_direction()
		
		if not is_zero_approx(turning_duration):
			await get_tree().create_timer(turning_duration).timeout
		
		is_turning = false
		
	if not is_in_knockback and floor_check_disabled and is_on_floor():
		floor_check_disabled = false

func flip_direction():
	direction *= -1
		
	if floor_check:
		floor_check.position.z = direction * absf(floor_check.position.z)

func handle_3d_rotation(delta: float):
	# Target angles: 0 rad for Right (+X), PI rad (180 deg) for Left (-X)
	var target_y_rot = 0.0 if direction > 0 else PI
	visuals.rotation.y = rotate_toward(visuals.rotation.y, target_y_rot, rotation_speed * delta)

func lock_to_25d_plane():
	velocity.x = 0
	global_transform.origin.x = 0

func play_animation(anim_name: StringName):
	var model_anim := get_model_animation(anim_name)
			
	if anim_player and anim_player.has_animation(model_anim.anim_name):
		if anim_player.current_animation != model_anim.anim_name:
			anim_player.play(model_anim.anim_name)
			visuals.position = model_anim.model_offset

func queue_animation(anim_name: StringName):
	var model_anim := get_model_animation(anim_name)
			
	if anim_player and anim_player.has_animation(model_anim.anim_name):
		anim_player.queue(model_anim.anim_name)
			
func get_model_animation(anim_name: StringName) -> ModelAnimation:
	if model_animations.has(anim_name):
		return model_animations.get(anim_name)
		
	return ModelAnimation.new(anim_name)

func _on_animation_changed(old_name: StringName, new_name: StringName) -> void:
	var model_anim := get_model_animation(new_name)
	visuals.position = model_anim.model_offset

func take_damage(amount: int, source_position: float, damage_step: int = 0):
	if is_invincible and current_damage_step == damage_step:
		return
		
	is_invincible = true
	current_damage_step = damage_step
	
	if max_health > 0:
		current_health -= amount
		print(amount, " damage taken, ", current_health, " left.")
		if is_boss:
			UiLayer.update_boss_health_display(current_health, max_health)
		if current_health <= 0:
			die()
			return
		
	if has_knockback:
		apply_knockback(amount, source_position)
	else:
		play_animation(&"hurt")
	
	if not is_zero_approx(damage_cooldown):
		if not damage_timer.is_stopped():
			damage_timer.stop()
		damage_timer.start(damage_cooldown)
	is_invincible = false

func _on_damage_end() -> void:
	is_invincible = false
	
func die():
	if is_boss:
		if not GameManager.permanent_flags.has(unique_enemy_id + "_defeated"):
			GameManager.permanent_flags.append(unique_enemy_id + "_defeated")
	elif not GameManager.defeated_enemies.has(unique_enemy_id):
		GameManager.defeated_enemies.append(unique_enemy_id)

	#add death animation exp some drop or whatever here
	queue_free()
	death.emit()

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

func apply_knockback(damage_amount, source_position: float) -> void:
	if damage_amount < knockback_min_damage:
		play_animation(&"hurt")
		return
		
	is_in_knockback = true
	floor_check_disabled = true

	var knockback_dir = sign(global_position.z - source_position)
	if knockback_dir == 0: 
		knockback_dir = -direction

	velocity.z = knockback_dir * knockback_force.z
	velocity.y = knockback_force.y
	
	play_animation(&"hurt")

	await get_tree().create_timer(knockback_duration).timeout
	is_in_knockback = false
