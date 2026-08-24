extends Node3D
class_name PlayerEntityHandler

@export_category("Entity Settings")
@export var kick_force: float = 60.0
@export var push_force: float = 3.0
@export var throw_force: float = 30.0

# Pickup / Throw
const PICKUP_SPEED: float = 2
const PICKUP_OFFSET: Vector3 = Vector3(0, 0, 0.2)

var _entities: Array[Node3D] = []
var entity_ref: Entity = null
var _entity_position: Vector3 = Vector3.ZERO

# This entity collision shape is for when an item is picked up, it duplicates
# its shape so that it will collide
var entity_collision: CollisionShape3D = null

var player: Player = null

func _ready() -> void:
	player = get_parent()

func start() -> void:
	entity_collision = player.get_node("EntityCollisionShape3D")
	player.interact_area.area_entered.connect(_on_interact_area_entered)
	player.interact_area.area_exited.connect(_on_interact_area_exited)
	player.direction_changed.connect(_on_direction_changed)

func process_pickup(delta: float) -> void:
	if entity_ref != null and not entity_ref.position.is_equal_approx(_entity_position):
		entity_ref.position = entity_ref.position.move_toward(_entity_position, PICKUP_SPEED * delta)
		entity_collision.position = entity_ref.position
	
		if player.direction == player.PlayerDirection.LEFT:
			entity_collision.position.z = absf(entity_collision.position.z)
		else:
			entity_collision.position.z = absf(entity_collision.position.z) * -1

func push() -> void:
	for i in player.get_slide_collision_count():
		var collision = player.get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is Entity:
			if _entities.has(collider):
				_push_entity(collision, collider)

func _push_entity(
	collision: KinematicCollision3D,
	body: Entity,
) -> void:
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
		push_dir * push_force
	)
	

func pickup() -> void:
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
	
	player.add_collision_exception_with(entity_ref)
	entity_ref.add_collision_exception_with(self)
	
	entity_ref.reparent(player.model, true)
	entity_ref.freeze = true
	
	var entity_size = entity_ref.get_size()
	var player_size = player.get_size()
	
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
	
func drop() -> void:
	if entity_ref == null:
		return

	entity_collision.disabled = true
	
	entity_ref.reparent(get_tree().get_first_node_in_group(&"Room"), true)
	_entities.append(entity_ref)
	entity_ref.freeze = false
	
	player.remove_collision_exception_with(entity_ref)
	entity_ref.remove_collision_exception_with(self)
	
	entity_ref.apply_central_impulse(
		player.velocity
	)
	entity_ref = null

func kick() -> void:
	for entity in _entities:
		if not entity.can_kick:
			continue
	
		if player.direction == player.PlayerDirection.RIGHT:
			entity.apply_central_impulse(
				Vector3(0, 0, -kick_force)
			)
		else:
			entity.apply_central_impulse(
				Vector3(0, 0, kick_force)
			)

func throw() -> void:
	if entity_ref == null or not entity_ref.can_throw or not entity_ref.position.is_equal_approx(_entity_position):
		return
	
	entity_collision.disabled = true
	
	entity_ref.reparent(get_tree().get_first_node_in_group(&"Room"), true)
	_entities.append(entity_ref)
	entity_ref.freeze = false
	
	player.remove_collision_exception_with(entity_ref)
	entity_ref.remove_collision_exception_with(self)
	
	var throw_dir = Vector3(0.0, 1.0, 1.0).normalized()
	
	if player.direction == player.PlayerDirection.RIGHT:
		throw_dir.z *= -1
	
	entity_ref.linear_velocity = Vector3.ZERO
	entity_ref.angular_velocity = Vector3.ZERO
	
	entity_ref.apply_central_impulse(
		(player.velocity * entity_ref.mass) + (throw_dir * throw_force)
	)
	
	entity_ref = null
	
func _on_interact_area_entered(area: Area3D) -> void:
	var parent = area.get_parent()
	
	if parent is Entity:
		print("C")
		if parent != entity_ref and not _entities.has(parent):
			_entities.append(parent)
	
func _on_interact_area_exited(area: Area3D) -> void:
	var parent = area.get_parent()
	if parent is Entity:
		if parent != entity_ref and _entities.has(parent):
			_entities.erase(parent)

func _on_direction_changed(direction: Player.PlayerDirection) -> void:
	if direction == Player.PlayerDirection.LEFT:
		if entity_ref != null:
			entity_collision.position.z = absf(entity_collision.position.z)
	elif direction == Player.PlayerDirection.RIGHT:
		if entity_ref != null:
			entity_collision.position.z = absf(entity_collision.position.z) * -1.0
