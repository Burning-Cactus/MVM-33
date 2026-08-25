extends CharacterBody3D
class_name Player

@export_group("Knockback Settings")
@export var player_knockback_force: float = 8.0
@export var player_knockback_duration: float = 0.3

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var model: MeshInstance3D = $Model
@onready var attack_area: Area3D = $Model/AttackArea
@onready var interact_area: Area3D = $Model/InteractArea

@onready var damage_timer: Timer = $DamageTimer
var is_invincible: bool = false

var player_data: PlayerData
var attack_damage:int = 7

var double_jump_unlocked := false
var slide_unlocked := false

var has_double_jumped := false

var input_disabled: bool = false
var input_disabled_until_on_floor: bool = false

const SPEED = 5.0
const JUMP_VELOCITY = 5.0

@onready var climb_handler: PlayerClimbHandler = $PlayerClimbHandler
@onready var hang_handler: PlayerHangHandler = $PlayerHangHandler
@onready var entity_handler: PlayerEntityHandler = $PlayerEntityHandler

enum PlayerState {
	NORMAL,
	HANGING,
	CLIMBING,
}

enum PlayerDirection {
	LEFT,
	RIGHT,
	FORWARD,
}

var state: PlayerState = PlayerState.NORMAL:
	get = get_state,
	set = set_state
	
var direction: PlayerDirection = PlayerDirection.RIGHT:
	get = get_direction,
	set = set_direction

signal state_changed(state: PlayerState)
signal direction_changed(direction: PlayerDirection)

func _ready() -> void:
	player_data = GameManager.player_data
	for ability in player_data.unlocked_abilities:
		if ability == "double_jump":
			double_jump_unlocked = true
		elif ability == "slide":
			slide_unlocked = true
	attack_area.monitoring = false
	
	entity_handler.start()
	hang_handler.start()
	climb_handler.start()
	
func _physics_process(delta: float) -> void:
	if input_disabled_until_on_floor:
		if is_on_floor():
			input_disabled_until_on_floor = false
			input_disabled = false
			
	if state == PlayerState.HANGING:
		hang_handler.process_hanging(delta)
		return
	elif state == PlayerState.CLIMBING:
		climb_handler.process_climbing(delta)
		return
		
	if not is_on_floor():
		velocity += get_gravity() * delta

	if input_disabled and is_on_floor():
		velocity.z = 0
	elif not input_disabled:
		if Input.is_action_just_pressed("jump"):
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
			elif double_jump_unlocked && !has_double_jumped:
				has_double_jumped = true
				velocity.y = JUMP_VELOCITY
		elif is_on_floor():
			has_double_jumped = false
			
		if Input.is_action_just_pressed("attack"):
			animation_player.play("attack")
			handle_attack()

		var input_dir := Input.get_vector("right", "left", "up", "down")
		var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if dir:
			if dir.x>0:
				set_direction(PlayerDirection.LEFT)
			else:
				set_direction(PlayerDirection.RIGHT)

			velocity.z = dir.x * SPEED
		else:
			velocity.z = move_toward(velocity.z, 0, SPEED)

	velocity.x = 0
	global_position.x = 0
	move_and_slide()

	check_contact_damage()
	
	# These needs to be after move_and_slide() to prevent issues
	# from the collisions not being processed yet
	entity_handler.push()
	hang_handler.push()
	entity_handler.process_entity(delta)
	hang_handler.grab()
	climb_handler.grab()

func unlock_ability(ability_name: String) -> void:
	if ability_name == "double_jump":
			double_jump_unlocked = true
	elif ability_name == "slide":
			slide_unlocked = true
	GameManager.unlock_ability(ability_name)

func check_contact_damage():
	if is_invincible:
		return
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()

		if body and "attack_damage" in body:
			receive_damage(body.attack_damage,body.global_position.z)
			return

func receive_damage(amount: int,source_position:float):
	if is_invincible:
		return
	GameManager.update_health(-amount)
	#TODO invul visual flashing
	is_invincible = true
	apply_player_knockback(source_position)
	damage_timer.start(1.0)
	await damage_timer.timeout
	is_invincible = false

func handle_attack():
	attack_area.monitoring = true
	input_disabled = true
	await get_tree().create_timer(0.4).timeout
	input_disabled = false
	attack_area.monitoring = false

func apply_player_knockback(source_position: float):
	input_disabled = true

	var knockback_dir = sign(global_position.z - source_position)
	if knockback_dir == 0:
		knockback_dir = 1

	velocity.z = knockback_dir * player_knockback_force
	velocity.y = player_knockback_force * 0.35

	if animation_player.has_animation("hurt"):
		animation_player.play("hurt")

	await get_tree().create_timer(player_knockback_duration).timeout
	input_disabled = false

func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage") and body != self:
		body.take_damage(attack_damage,global_position.z)

func get_size() -> Vector3:
	return Vector3(
		$CollisionShape3D.shape.radius * 2,
		$CollisionShape3D.shape.height,
		$CollisionShape3D.shape.radius * 2,
	)

func disable_input_until_on_floor() -> void:
	has_double_jumped = true
	input_disabled = true
	input_disabled_until_on_floor = true
	pass

func set_state(value: PlayerState) -> void:
	state = value
	
	state_changed.emit(state)
func get_state() -> PlayerState:
	return state

func set_direction(value: PlayerDirection) -> void:
	direction = value
	
	if direction == PlayerDirection.LEFT:
		model.rotation_degrees.y = 180
		model.scale.x = -1
	elif direction == PlayerDirection.RIGHT:
		model.rotation_degrees.y = 0
		model.scale.x = 1
	elif direction == PlayerDirection.FORWARD:
		model.rotation_degrees.y = 90
		model.scale.x = 1
			
	direction_changed.emit(direction)

func get_direction() -> PlayerDirection:
	return direction
