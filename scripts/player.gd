extends CharacterBody3D
class_name Player

@export_group("Knockback Settings")
@export var player_knockback_force: float = 8.0
@export var player_knockback_duration: float = 0.3

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var model: MeshInstance3D = $Model
@onready var attack_area: Area3D = $Model/AttackArea
@onready var entity_collision: CollisionShape3D = $EntityCollisionShape3D

@onready var damage_timer: Timer = $DamageTimer
var is_invincible: bool = false

var health:int  = 100
var attack_damage:int = 7

var double_jump_unlocked := false
var slide_unlocked := false

var has_double_jumped := false

var input_disabled:bool = false

const PICKUP_SPEED: float = 2
const PICKUP_OFFSET: Vector3 = Vector3(0, 0, 0.2)
var _entities: Array[Node3D] = []
var entity_ref: Entity = null
var _entity_position: Vector3 = Vector3.ZERO

const SPEED = 5.0
const JUMP_VELOCITY = 5.0

func _ready() -> void:
	health = GameManager.player_data["health"]
	for ability in GameManager.player_data["unlocked_abilities"]:
		if ability == "double_jump":
			double_jump_unlocked = true
		elif ability == "slide":
			slide_unlocked = true
	attack_area.monitoring = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if input_disabled and is_on_floor():
		velocity.z = 0
	if not input_disabled:
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

		if Input.is_action_just_pressed("kick") and is_on_floor():
			_kick_entities()

		var input_dir := Input.get_vector("right", "left", "up", "down")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			if direction.x>0:
				model.rotation_degrees.y = 180
				if entity_ref != null:
					entity_collision.position.z = absf(entity_collision.position.z)
			else:
				model.rotation_degrees.y = 0
				if entity_ref != null:
					entity_collision.position.z = absf(entity_collision.position.z) * -1.0

			velocity.z = direction.x * SPEED
		else:
			velocity.z = move_toward(velocity.x, 0, SPEED)

	if entity_ref != null and not entity_ref.position.is_equal_approx(_entity_position):
		entity_ref.position = entity_ref.position.move_toward(_entity_position, PICKUP_SPEED * delta)
		entity_collision.position = entity_ref.position
	
		if model.rotation_degrees.y == 180:
			entity_collision.position.z = absf(entity_collision.position.z)
		else:
			entity_collision.position.z = absf(entity_collision.position.z) * -1

	velocity.x = 0
	global_position.x = 0
	move_and_slide()

	check_contact_damage()
	
	_push_rigid_body()

	# This needs to be after move_and_slide() to prevent wierd collision issues
	if not input_disabled:
		if Input.is_action_just_pressed("pickup"):
			_pickup_entity()

		if Input.is_action_just_pressed("drop"):
			_drop_entity()
		elif Input.is_action_just_pressed("throw"):
			_throw_entity()

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
	health = GameManager.player_data["health"]
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

func _push_rigid_body() -> void:
	var ropes: Array[RopeBase] = []
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is Entity:
			_push_entity(collision, collider)
		elif collider is RigidBody3D:
			var parent: Node = collider.get_parent()
			if parent is RopeBase and not ropes.has(parent):
				ropes.append(parent)
				_push_rope(collision, collider)

func _push_entity(
	collision: KinematicCollision3D,
	body: Entity,
) -> void:
	if not is_on_floor():
		return
		
	if not body is Entity or not body.can_push:
		return

	var push_dir = -collision.get_normal()

	# Limit y direction so jumping on box doesn't push it
	if push_dir.y > 0.4 or push_dir.y < -0.4:
		return

	# Only want left and right
	push_dir.y = 0.0
	push_dir.x = 0.0

	push_dir = push_dir.normalized()

	if push_dir.length_squared() < 0.01:
		return

	body.apply_central_impulse(
		push_dir * body.push_force
	)
	
func _push_rope(
	collision: KinematicCollision3D,
	body: RigidBody3D,
) -> void:
	# TODO: This still needs tweaking
	var push_dir := -collision.get_normal()

	push_dir.x = 0.0

	if push_dir.length_squared() < 0.001:
		return
	
	if push_dir.z >= 0.0 and push_dir.z < 0.7:
		push_dir.z = 0.7
	elif push_dir.z < 0.0 and push_dir.z > -0.7   :
		push_dir.z = -0.7
	
	push_dir = push_dir.normalized()

	var push_speed := velocity.dot(push_dir)

	if push_speed <= 0.0:
		push_speed = 0.5 

	var push_force: float = push_speed * body.get_parent().push_force

	push_force = maxf(0.5 * push_force, push_force)

	body.apply_central_impulse(
		push_dir * push_force
	)
	
func _on_area_3d_interact_area_entered(area: Area3D) -> void:
	var parent = area.get_parent()
	if parent is Entity and parent != entity_ref:
		if not _entities.has(parent):
			_entities.append(parent)
	
func _on_area_3d_interact_area_exited(area: Area3D) -> void:
	var parent = area.get_parent()
	if parent is Entity and parent != entity_ref:
		if _entities.has(parent):
			_entities.erase(parent)
	
func _pickup_entity() -> void:
	if _entities.is_empty() or entity_ref != null:
		return
	
	for entity in _entities:
		if not entity.can_pickup:
			continue
	
		entity_ref = entity
		break

	if entity_ref == null:
		return
	
	_entities.erase(entity_ref)
	
	add_collision_exception_with(entity_ref)
	entity_ref.add_collision_exception_with(self)
	
	entity_ref.reparent(model, true)
	entity_ref.freeze = true
	
	var entity_size = entity_ref.get_size()
	var player_size = get_size()
	
	_entity_position = Vector3(
		0,
		0,
		(player_size.z / 2) + (entity_size.z / 2),
	)
	
	_entity_position += PICKUP_OFFSET
	
	_entity_position.z *= -1
	
	entity_collision.position = entity_ref.position
	entity_collision.shape = entity_ref.collision.shape.duplicate()
	entity_collision.disabled = false
	
func _drop_entity() -> void:
	if entity_ref == null:
		return

	entity_collision.disabled = true
	
	entity_ref.reparent(get_tree().get_first_node_in_group(&"Room"), true)
	_entities.append(entity_ref)
	entity_ref.freeze = false
	
	remove_collision_exception_with(entity_ref)
	entity_ref.remove_collision_exception_with(self)
	
	entity_ref.apply_central_impulse(
		velocity
	)
	entity_ref = null

func _kick_entities() -> void:
	for entity in _entities:
		if not entity.can_kick:
			continue
	
		if model.rotation_degrees.y == 0.0:
			entity.apply_central_impulse(
				Vector3(0, 0, -entity.kick_force)
			)
		else:
			entity.apply_central_impulse(
				Vector3(0, 0, entity.kick_force)
			)

func _throw_entity() -> void:
	if entity_ref == null or not entity_ref.can_throw or not entity_ref.position.is_equal_approx(_entity_position):
		return
	
	entity_collision.disabled = true
	
	entity_ref.reparent(get_tree().get_first_node_in_group(&"Room"), true)
	_entities.append(entity_ref)
	entity_ref.freeze = false
	
	remove_collision_exception_with(entity_ref)
	entity_ref.remove_collision_exception_with(self)
	
	var throw_dir = Vector3(0.0, 1.0, 1.0).normalized()
	
	if model.rotation_degrees.y == 0.0:
		throw_dir.z *= -1
	
	entity_ref.apply_central_impulse(
		velocity + (throw_dir * entity_ref.throw_force)
	)
	
	entity_ref = null
	
func get_size() -> Vector3:
	return Vector3(
		$CollisionShape3D.shape.radius * 2,
		$CollisionShape3D.shape.height,
		$CollisionShape3D.shape.radius * 2,
	)
