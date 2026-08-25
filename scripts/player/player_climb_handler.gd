extends Node3D
class_name PlayerClimbHandler

@export var allow_fall: bool = false
@export var climb_speed: float = 5.0

@export_group("Forward Ladders")
@export var climb_area: Vector3 = Vector3(2.0, 0.75, 0.5)
@export var climb_area_offset: float = 0.125

var player: Player = null

var is_in_center_climb_area: bool = false
var is_in_top_climb_area: bool = false
var is_in_bottom_climb_area: bool = false
var is_in_left_climb_area: bool = false
var is_in_right_climb_area: bool = false

var _cancel_floor_climb_off: bool = false
var _direction: Player.PlayerDirection = Player.PlayerDirection.LEFT

func _ready() -> void:
	player = get_parent()
	_add_center_area()
	_add_top_area()
	_add_bottom_area()
	_add_left_area()
	_add_right_area()

func start() -> void:
	pass
	
func process_climbing(delta: float) -> void:
	var input_dir := Input.get_vector("right", "left", "up", "down")
	
	if _cancel_floor_climb_off and not player.is_on_floor():
		_cancel_floor_climb_off = false
	
	if input_dir:
		if player.get_direction() == player.PlayerDirection.FORWARD:
			input_dir = input_dir.normalized()
			if input_dir.x < 0.0:
				_direction = Player.PlayerDirection.RIGHT
			elif input_dir.x > 0.0:
				_direction = Player.PlayerDirection.LEFT
			player.velocity.z = input_dir.x * climb_speed
		player.velocity.y = input_dir.y * climb_speed * -1.0
	else:
		if player.get_direction() == player.PlayerDirection.FORWARD:
			player.velocity.z = move_toward(player.velocity.z, 0, climb_speed)
		player.velocity.y = move_toward(player.velocity.y, 0, climb_speed)
	
	if player.get_direction() != player.PlayerDirection.FORWARD:
		player.velocity.z = 0
	player.velocity.x = 0
	player.global_position.x = 0
	
	if player.is_on_floor() and not _cancel_floor_climb_off:
		release()
	elif Input.is_action_just_pressed(&"release"):
		release()
	elif Input.is_action_just_pressed(&"jump"):
		release()
		player.velocity.y = player.JUMP_VELOCITY
	
	player.move_and_slide()

func _add_center_area() -> void:
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 0
	area.set_collision_mask_value(7, true)
	
	area.area_entered.connect(_on_center_area_entered)
	area.area_exited.connect(_on_center_area_exited)
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = climb_area
	collision.shape = shape
	area.add_child(collision)
	collision.position = Vector3(0.0, climb_area_offset, 0.0)
	add_child(area)
	
func _add_top_area() -> void:
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 0
	area.set_collision_mask_value(7, true)
	
	area.area_entered.connect(_on_top_area_entered)
	area.area_exited.connect(_on_top_area_exited)
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(climb_area.x, 0.05, climb_area.z)
	collision.shape = shape
	area.add_child(collision)
	collision.position = Vector3(0.0, (climb_area.y / 2.0) + climb_area_offset + 0.05, 0.0)
	add_child(area)
	
func _add_bottom_area() -> void:
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 0
	area.set_collision_mask_value(7, true)
	
	area.area_entered.connect(_on_bottom_area_entered)
	area.area_exited.connect(_on_bottom_area_exited)
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(climb_area.x, 0.05, climb_area.z)
	collision.shape = shape
	area.add_child(collision)
	collision.position = Vector3(0.0, (-climb_area.y / 2.0) + climb_area_offset - 0.05, 0.0)
	add_child(area)

func _add_left_area() -> void:
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 0
	area.set_collision_mask_value(7, true)
	
	area.area_entered.connect(_on_left_area_entered)
	area.area_exited.connect(_on_left_area_exited)
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(climb_area.x, climb_area.y, 0.05)
	collision.shape = shape
	area.add_child(collision)
	collision.position = Vector3(0.0, climb_area_offset, (climb_area.z / 2.0) + 0.05)
	add_child(area)
	
func _add_right_area() -> void:
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 0
	area.set_collision_mask_value(7, true)
	
	area.area_entered.connect(_on_right_area_entered)
	area.area_exited.connect(_on_right_area_exited)
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(climb_area.x, climb_area.y, 0.05)
	collision.shape = shape
	area.add_child(collision)
	collision.position = Vector3(0.0, climb_area_offset, (-climb_area.z / 2.0) - 0.05)
	add_child(area)

func release() -> void:
	player.set_state(player.PlayerState.NORMAL)
	if player.get_direction() == player.PlayerDirection.FORWARD:
		player.set_direction(_direction)

func grab() -> void:
	if player.input_disabled:
		return
	
	# Can't climb while holding someting
	if player.entity_handler.is_holding_entity():
		return
		
	_grab_forward()
	_grab_side()
	
func _grab_forward() -> void:
	if not is_in_center_climb_area:
		return
	
	if Input.is_action_just_pressed(&"grab"):
		# prioritize picking up entities
		if not player.entity_handler.can_pickup():
			_cancel_floor_climb_off = true
			player.set_state(Player.PlayerState.CLIMBING)
			_direction = player.get_direction()
			player.set_direction(Player.PlayerDirection.FORWARD)
			return
		
	if player.is_on_floor():
		var input_dir := Input.get_vector("right", "left", "up", "down")
		if input_dir.y < 0:
			_cancel_floor_climb_off = true
			player.set_state(Player.PlayerState.CLIMBING)
			_direction = player.get_direction()
			player.set_direction(Player.PlayerDirection.FORWARD)
			return
	
func _grab_side() -> void:
	pass
	
func _on_center_area_entered(area: Area3D) -> void:
	is_in_center_climb_area = true
	print("A")
func _on_center_area_exited(area: Area3D) -> void:
	is_in_center_climb_area = false
	print("B")

func _on_top_area_entered(area: Area3D) -> void:
	is_in_top_climb_area = true
func _on_top_area_exited(area: Area3D) -> void:
	is_in_top_climb_area = false
	
func _on_bottom_area_entered(area: Area3D) -> void:
	is_in_bottom_climb_area = true
func _on_bottom_area_exited(area: Area3D) -> void:
	is_in_bottom_climb_area = true
	
func _on_left_area_entered(area: Area3D) -> void:
	is_in_left_climb_area = true
func _on_left_area_exited(area: Area3D) -> void:
	is_in_left_climb_area = true
	
func _on_right_area_entered(area: Area3D) -> void:
	is_in_right_climb_area = true
func _on_right_area_exited(area: Area3D) -> void:
	is_in_right_climb_area = true
