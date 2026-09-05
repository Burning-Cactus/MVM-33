extends CharacterBody3D
class_name Player

@export_group("Knockback Settings")
@export var player_knockback_force: Vector3 = Vector3(0.0, 2.8, 8.0)
@export var player_knockback_duration: float = 0.3

@onready var player_model: Node3D = $Model
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var model: Node3D = $Model
@onready var attack_area: Area3D = $SwordBoneAttachment/SwordHitbox
@onready var interact_area: Area3D = $InteractArea

@onready var damage_timer: Timer = $DamageTimer
var is_invincible: bool = false

var player_data: PlayerData
var attack_damage:int = 7
var damage_cooldown: float = 1.0

var double_jump_unlocked := false
var slide_unlocked := false

var has_double_jumped := false

var input_disabled: bool = false
var input_disabled_until_on_floor: bool = false

const SPEED = 5.0
const JUMP_VELOCITY = 6.0

var can_attack: bool = true

@onready var climb_handler: PlayerClimbHandler = $PlayerClimbHandler
@onready var hang_handler: PlayerHangHandler = $PlayerHangHandler
@onready var entity_handler: PlayerEntityHandler = $PlayerEntityHandler

var jump_duration: Timer

enum PlayerState {
	NORMAL,
	JUMPING,
	FALLING,
	HANGING,
	CLIMBING,
	ATTACKING,
	JUMP_ATTACKING,
	ON_LEDGE,
	SLIDING,
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
	attack_area.monitorable = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	entity_handler.start()
	hang_handler.start()
	climb_handler.start()
	attack_cooldown = Timer.new()
	attack_cooldown.one_shot = true
	add_child(attack_cooldown)
	attack_duration = Timer.new()
	attack_duration.one_shot = true
	attack_duration.timeout.connect(end_attack)
	add_child(attack_duration)
	
	model.scale.x = -1
	model.scale.z = -1

func _physics_process(delta: float) -> void:
	if input_disabled_until_on_floor:
		if is_on_floor():
			input_disabled_until_on_floor = false
			input_disabled = false
			
	match state:
		PlayerState.NORMAL:
			if not is_on_floor():
				set_state(PlayerState.FALLING)
			else:
				has_double_jumped = false
				if _is_action_just_pressed("jump"):
					set_state(PlayerState.JUMPING)
				if _is_action_just_pressed("attack"):
					if Input.is_action_pressed("down"):
						set_state(PlayerState.SLIDING)
					else:
						set_state(PlayerState.ATTACKING)
				else:
					handle_movement()
					if velocity.z:
						animation_player.play("WALK")
					else:
						animation_player.play("IDLE")
		PlayerState.JUMPING:
			handle_movement()
			if _is_action_just_pressed("attack"):
				set_state(PlayerState.JUMP_ATTACKING)
			elif _is_action_pressed("jump"):
				velocity.y = JUMP_VELOCITY
			else:
				set_state(PlayerState.FALLING)
		PlayerState.FALLING:
			if is_on_floor():
				set_state(PlayerState.NORMAL)
			else:
				animation_player.play("JUMP_FALL")
				# velocity += (get_gravity() - Vector3(0, 2, 0)) * delta
				velocity.y = move_toward(velocity.y, get_gravity().y * 3, -get_gravity().y * delta)
				handle_movement()
				if _is_action_just_pressed("attack"):
					set_state(PlayerState.JUMP_ATTACKING)
				elif _is_action_just_pressed("jump") && double_jump_unlocked && !has_double_jumped:
						has_double_jumped = true
						velocity.y = JUMP_VELOCITY
						animation_player.play("JUMP_DOUBLE")
		PlayerState.JUMP_ATTACKING:
			if is_on_floor():
				set_state(PlayerState.NORMAL)
			else:
				velocity += get_gravity() * delta
				handle_movement()
		PlayerState.HANGING:
			hang_handler.process_hanging(delta)
		PlayerState.CLIMBING:
			climb_handler.process_climbing(delta)
		PlayerState.ATTACKING:
			velocity.z = 0
			if attack_cooldown.is_stopped() && _is_action_just_pressed("attack"):
				handle_attack()
		PlayerState.ON_LEDGE:
			pass
		PlayerState.SLIDING:
			var input_dir := Input.get_vector("right", "left", "up", "down")
			var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			if direction == PlayerDirection.LEFT && dir.x < 0.0:
				direction = PlayerDirection.RIGHT
				set_state(PlayerState.NORMAL)
			elif direction == PlayerDirection.RIGHT && dir.x > 0.0:
				direction = PlayerDirection.LEFT
				set_state(PlayerState.NORMAL)
			else:
				var motion: float = 1.5 if direction == PlayerDirection.LEFT else -1.5
				velocity.z = motion * SPEED
	
	velocity.x = 0
	global_position.x = 0
	move_and_slide()
	
	# These needs to be after move_and_slide() to prevent issues
	# from the collisions not being processed yet
	entity_handler.push()
	hang_handler.push()
	entity_handler.process_entity(delta)
	hang_handler.grab()
	climb_handler.grab()

func _is_action_just_pressed(action: StringName, exact_match: bool = false) -> bool:
	return Input.is_action_just_pressed(action, exact_match) and not input_disabled
	
func _is_action_pressed(action: StringName, exact_match: bool = false) -> bool:
	return Input.is_action_pressed(action, exact_match) and not input_disabled

func handle_movement() -> void:
	if input_disabled:
		return
		
	var input_dir := Input.get_vector("right", "left", "up", "down")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if dir:
		if dir.x > 0.0:
			set_direction(PlayerDirection.LEFT)
		elif dir.x < 0.0:
			set_direction(PlayerDirection.RIGHT)
		velocity.z = dir.x * SPEED
	else:
		velocity.z = move_toward(velocity.z, 0, SPEED)

func unlock_ability(ability_name: String) -> void:
	if ability_name == "double_jump":
		double_jump_unlocked = true
	elif ability_name == "slide":
		slide_unlocked = true
	GameManager.unlock_ability(ability_name)

func receive_damage(
	amount: int, 
	source_position: float = 0.0,
	independent: bool = false,
	apply_knockback: bool = true
):
	if independent:
		GameManager.update_health(-amount)
		if apply_knockback:
			apply_player_knockback(source_position)
		return
	
	if is_invincible:
		return
		
	GameManager.update_health(-amount)
	#TODO invul visual flashing
	is_invincible = true
	if apply_knockback:
		apply_player_knockback(source_position)
	damage_timer.start(damage_cooldown)
	await damage_timer.timeout
	is_invincible = false

var attack_step := 0
var attack_cooldown: Timer
var attack_duration: Timer
func handle_attack():
	attack_step += 1
	match attack_step:
		1:
			animation_player.play("ATTACK_1")
			attack_cooldown.start(0.3)
			attack_duration.start(0.6)
		2:
			animation_player.play("ATTACK_2")
			attack_cooldown.start(0.3)
			attack_duration.start(0.6)
		3:
			animation_player.play("ATTACK_3")
			attack_cooldown.start(0.7)
			attack_duration.start(1.0)

func handle_jump_attack():
	animation_player.play("JUMP_ATTACK")
	attack_duration.start(0.6)

func apply_player_knockback(source_position: float):
	input_disabled = true

	var knockback_dir = sign(global_position.z - source_position)
	if knockback_dir == 0:
		knockback_dir = 1

	velocity.z = knockback_dir * player_knockback_force.z
	velocity.y = player_knockback_force.y

	if animation_player.has_animation("hurt"):
		animation_player.play("hurt")

	await get_tree().create_timer(player_knockback_duration).timeout
	input_disabled = false

func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage") and body != self:
		body.take_damage(attack_damage, global_position.z)

func get_global_center() -> Vector3:
	return global_position + $CollisionShape3D.position
	
func get_size() -> Vector3:
	return Vector3(
		$CollisionShape3D.shape.radius * 2,
		$CollisionShape3D.shape.height,
		$CollisionShape3D.shape.radius * 2,
	)
	
func can_interact() -> bool:
	if input_disabled:
		return false
		
	match state:
		PlayerState.NORMAL, PlayerState.JUMPING, PlayerState.FALLING:
			return true
			
	return false

func disable_input_until_on_floor() -> void:
	has_double_jumped = true
	input_disabled = true
	input_disabled_until_on_floor = true
	pass

func set_state(new_state: PlayerState) -> void:
	match state:
		PlayerState.ATTACKING:
			attack_area.monitoring = false
			attack_area.monitorable = false
		PlayerState.JUMP_ATTACKING:
			attack_area.monitoring = false
			attack_area.monitorable = false
	match new_state:
		PlayerState.JUMPING:
			animation_player.play("JUMP_START")
		PlayerState.ATTACKING:
			attack_area.monitoring = true
			attack_area.monitorable = true
			attack_step = 0
			handle_attack()
		PlayerState.JUMP_ATTACKING:
			attack_area.monitoring = true
			attack_area.monitorable = true
			handle_jump_attack()
		PlayerState.SLIDING:
			animation_player.play("SLIDE")
	state = new_state
	state_changed.emit(state)
func get_state() -> PlayerState:
	return state

func set_direction(value: PlayerDirection) -> void:
	direction = value
		
	if direction == PlayerDirection.LEFT:
		model.rotation_degrees.y = 180
		interact_area.rotation_degrees.y = 180
		model.scale.x = 1
	elif direction == PlayerDirection.RIGHT:
		model.rotation_degrees.y = 0
		interact_area.rotation_degrees.y = 0
		model.scale.x = -1
	elif direction == PlayerDirection.FORWARD:
		model.rotation_degrees.y = 90
		interact_area.rotation_degrees.y = 90
		model.scale.x = -1
			
	direction_changed.emit(direction)

func get_direction() -> PlayerDirection:
	return direction

func end_attack() -> void:
	if is_on_floor():
		set_state(PlayerState.NORMAL)
	else:
		set_state(PlayerState.FALLING)
