extends Node3D
class_name PlayerHangHandler

@export_category("Rope Settings")
@export var swing_force: float = 10.0
@export var climb_speed: float = 2.5

var _rope_segments: Array[Node3D] = []
var _rope_segment_ref: RigidBody3D
var _rope_grab_joint: PinJoint3D
var _rope_grab_body: RigidBody3D
var _rope_segments_ref: Array[RigidBody3D] = []
var _rope_release_timer: Timer
var _rope_release_delta: float = 0.3
var _rope_climb_position: float = 0.0
var _rope_grab_offset: Vector3 = Vector3.ZERO

var player: Player = null

func _ready() -> void:
	player = get_parent()
	
	_add_rope_area()
	
	_rope_release_timer = Timer.new()
	_rope_release_timer.one_shot = true
	add_child(_rope_release_timer)
	_rope_release_timer.timeout.connect(_on_rope_release_timeout)

func start() -> void:
	player.interact_area.area_entered.connect(_on_interact_area_entered)
	player.interact_area.area_exited.connect(_on_interact_area_exited)

func _add_rope_area() -> void:
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 0
	area.set_collision_mask_value(6, true)
	
	area.area_entered.connect(_on_rope_area_body_entered)
	area.area_exited.connect(_on_rope_area_body_exited)
	
	var collision = CollisionShape3D.new()
	var shape = player.get_node("CollisionShape3D").shape.duplicate()
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	
func process_hanging(delta: float) -> void:
	_swing_rope()
	_climb_rope(delta)
	
	player.global_position = _rope_grab_body.global_position
	
	if Input.is_action_just_pressed(&"release"):
		_release_rope()
	elif Input.is_action_just_pressed(&"jump"):
		_release_rope()
		player.velocity.y = player.JUMP_VELOCITY

func push() -> void:
	var ropes: Array[Rope] = []
	
	for i in player.get_slide_collision_count():
		var collision = player.get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is RigidBody3D:
			var parent: Node = collider.get_parent()
			if parent is Rope and not ropes.has(parent):
				ropes.append(parent)
				_push_rope(collision, collider)

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

	var push_speed := player.velocity.dot(push_dir)

	if push_speed <= 0.0:
		push_speed = 0.5 

	var rope_push_force: float = push_speed * player.entity_handler.push_force

	rope_push_force = maxf(0.5 * rope_push_force, rope_push_force)

	body.apply_central_impulse(
		push_dir * rope_push_force
	)

func grab() -> void:
	if player.state == player.PlayerState.HANGING:
		return
	
	# Can't grab while holding an entity
	if player.entity_handler.entity_ref != null or _rope_segments.is_empty():
		return
		
	if not Input.is_action_just_pressed("grab"):
		return
		
	_rope_release_timer.stop()

	var closest_segment: RigidBody3D
	var closest_distance: float = -1.0
	
	for segment in _rope_segments:
		if not is_instance_valid(segment):
			continue

		var distance := global_position.distance_to(segment.global_position)

		if closest_distance < 0.0 or distance < closest_distance:
			closest_distance = distance
			closest_segment = segment

	_rope_segment_ref = closest_segment
	
	_set_rope_climb_position()
	
	var rope := _rope_segment_ref.get_parent() as Rope
	if _rope_climb_position < 0.0 or _rope_climb_position > rope.segment_count * rope.segment_length:
		return
	
	_create_grab_body()
	_create_grab_joint()
	
	# I guess this could just be a float since not using x
	_rope_grab_offset = _rope_segment_ref.to_local(global_position)
	_rope_grab_offset.x = 0.0
	_rope_grab_offset.y = 0.0
	
	player.set_collision_mask_value(6, false)

	player.state = player.PlayerState.HANGING

	player.velocity = Vector3.ZERO
	
	# Reset double jump so can do so upon release of rope
	player.has_double_jumped = false

func _create_grab_body() -> void:
	_rope_grab_body = RigidBody3D.new()

	_rope_grab_body.linear_damp = 0.2
	_rope_grab_body.angular_damp = 0.5

	# Lock X movement
	_rope_grab_body.axis_lock_linear_x = true
	_rope_grab_body.axis_lock_angular_y = true
	_rope_grab_body.axis_lock_angular_z = true

	# Don't let the grab body collide with anything.
	_rope_grab_body.collision_layer = 0
	_rope_grab_body.collision_mask = 0

	get_tree().current_scene.add_child(_rope_grab_body)

	_rope_grab_body.global_position = global_position


func _set_rope_climb_position() -> void:
	var rope := _rope_segment_ref.get_parent() as Rope
	if rope == null:
		return

	var index := rope.segments.find(_rope_segment_ref)
	if index < 0:
		return

	var local_position := _rope_segment_ref.to_local(
		global_position
	)

	_rope_climb_position = (
		float(index) * rope.segment_length - local_position.y
	)

func _create_grab_joint() -> void:
	_rope_grab_joint = PinJoint3D.new()
	_rope_grab_joint.exclude_nodes_from_collision = true
	
	get_tree().current_scene.add_child(_rope_grab_joint)
	
	_rope_grab_joint.global_position = _rope_grab_body.global_position

	_rope_grab_joint.node_a = _rope_segment_ref.get_path()
	_rope_grab_joint.node_b = _rope_grab_body.get_path()

func _release_rope() -> void:
	var release_velocity := Vector3.ZERO
	
	if is_instance_valid(_rope_grab_joint):
		_rope_grab_joint.queue_free()

	if is_instance_valid(_rope_grab_body):
		release_velocity = _rope_grab_body.linear_velocity
		_rope_grab_body.queue_free()

	_rope_grab_joint = null
	_rope_grab_body = null
	_rope_segment_ref = null

	player.state = player.PlayerState.NORMAL
	
	player.velocity = release_velocity
	
	_rope_release_timer.start(_rope_release_delta)
	
func _swing_rope() -> void:
	var rope_vector: Vector3 = _rope_grab_body.global_position - _rope_segment_ref.get_parent().global_position
	rope_vector.x = 0.0

	if rope_vector.length_squared() < 0.001:
		return

	rope_vector = rope_vector.normalized()

	var tangent := Vector3(
		0.0,
		-rope_vector.z,
		rope_vector.y
	)

	tangent = tangent.normalized()
	
	var input_dir := Input.get_vector("right", "left", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, 0)).normalized()

	if direction.x > 0.1:
		_rope_grab_body.apply_central_force(
			tangent * swing_force * -1
		)
	elif direction.x < -0.1:
		_rope_grab_body.apply_central_force(
			tangent * swing_force
		)
		
func _climb_rope(delta: float) -> void:
	var input_dir := Input.get_vector("right", "left", "up", "down")
	if absf(input_dir.y) < 0.1:
		return

	var rope := _rope_segment_ref.get_parent() as Rope
	if rope == null:
		return

	var max_position := rope.segment_count * rope.segment_length
	
	var clamp_position := true
	
	if _rope_climb_position < rope.segment_length:
		if input_dir.y > 0:
			clamp_position = false
		else:
			return
	elif _rope_climb_position > max_position - rope.segment_length:
		if input_dir.y < 0:
			clamp_position = false
		else:
			return
	
	_rope_climb_position += (input_dir.y * climb_speed * delta)

	if clamp_position:
		_rope_climb_position = clampf(
			_rope_climb_position,
			rope.segment_length,
			max_position - rope.segment_length
		)

	var segment_float := _rope_climb_position / rope.segment_length
	var segment_index := floori(segment_float)
	var weight := segment_float - float(segment_index)

	var start_index := 0
	var end_index := rope.segments.size() - 1
	
	segment_index = clampi(
		segment_index,
		start_index,
		end_index
	)

	var current_segment := rope.segments[segment_index]
	
	var next_index := clampi(
		segment_index + 1,
		start_index,
		end_index
	)

	var next_segment := rope.segments[next_index]

	var new_position := current_segment.global_position.lerp(
		next_segment.global_position,
		weight
	)

	var rope_basis := current_segment.global_transform.basis.slerp(
		next_segment.global_transform.basis,
		weight
	)

	new_position += (rope_basis * _rope_grab_offset)

	_rope_segment_ref = current_segment
	_rope_grab_body.global_position = new_position
	
	_rope_grab_joint.free()
	_rope_grab_joint = null

	_create_grab_joint()
	
func _on_rope_area_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and body.get_parent() is Rope:
		if not _rope_segments_ref.has(body):
			_rope_segments_ref.append(body)

func _on_rope_area_body_exited(body: Node3D) -> void:
	if body is RigidBody3D and body.get_parent() is Rope:
		if _rope_segments_ref.has(body):
			_rope_segments_ref.erase(body)
			if (_rope_segments_ref.is_empty() and 
				player.state != Player.PlayerState.HANGING and
				_rope_release_timer.is_stopped()
			):
				player.set_collision_mask_value(6, true)
				
func _on_rope_release_timeout() -> void:
	if (_rope_segments_ref.is_empty() and 
		player.state != player.PlayerState.HANGING
	):
		player.set_collision_mask_value(6, true)

func _on_interact_area_entered(area: Area3D) -> void:
	var parent = area.get_parent()
	
	if parent is RigidBody3D:
		if not _rope_segments.has(parent):
			if parent.get_parent() is Rope:
				_rope_segments.append(parent)
	
func _on_interact_area_exited(area: Area3D) -> void:
	var parent = area.get_parent()
	
	if parent is RigidBody3D:
		if _rope_segments.has(parent):
			_rope_segments.erase(parent)
