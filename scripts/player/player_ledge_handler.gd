extends Node3D
class_name PlayerLedgeHandler

@export_category("Ledge Settings")
@export var horizontal_position: Vector3 = Vector3(0.0, -0.2, 0.0)
@export var vertical_position: Vector3 = Vector3(0.0, 0.6, -0.2)
@export var ledge_target_position: Vector3 = Vector3(0, -0.2, -0.2)
@export var player_hand_position: Vector3 = Vector3(0.0, 2.4, 0.4)

var horizontal_check: RayCast3D
var vertical_check: RayCast3D
var _is_climbing_up: bool = false
var _climb_up_delta: float = 0.0
var _climb_up_vertical_delta: float = 0.4
var _max_climb_up_delta: float = 0.0
var _player_position: Vector3 = Vector3.ZERO
var _collision_point: Vector3 = Vector3.ZERO

var player: Player = null

func _ready() -> void:
	player = get_parent()
	
	var size = player.get_size()
	var center = player.get_center()

	var offset = Vector3(
		0.0,
		center.y + (size.y / 2.0),
		center.z - (size.z / 2.0),
	)
	
	horizontal_check = RayCast3D.new()
	horizontal_check.position = Vector3(
		0.0, 
		offset.y + horizontal_position.y,
		offset.z + horizontal_position.z
	)
	horizontal_check.target_position = Vector3(0.0, 0.0, ledge_target_position.z)
	add_child(horizontal_check)
	
	vertical_check = RayCast3D.new()
	vertical_check.position = Vector3(
		0.0, 
		offset.y + vertical_position.y,
		offset.z + vertical_position.z, 
	)
	vertical_check.target_position = Vector3(0.0, ledge_target_position.y, 0.0)
	add_child(vertical_check)
	
func start() -> void:
	player.direction_changed.connect(_on_direction_changed)
	_max_climb_up_delta = player.get_animation_length(&"ledge_climb")

func process_ledge(delta: float) -> void:
	if not _is_climbing_up:
		if not vertical_check.is_colliding():
			if player.velocity.y > 0.0:
				player.velocity.y = 0.0
			player.velocity.y = move_toward(
				player.velocity.y, 
				player.get_gravity().y * 3, 
				-player.get_gravity().y * delta
			)
		else:
			player.velocity = Vector3.ZERO
			if Input.is_action_just_pressed(&"jump"):
				_is_climbing_up = true
				_climb_up_delta = 0.0
				_collision_point = vertical_check.get_collision_point()
				if player.get_direction() == Player.PlayerDirection.LEFT:
					_collision_point.z += 0.25
				else:
					_collision_point.z -= 0.25
				_player_position = player.global_position
				player.play_animation(&"ledge_climb")
				
	if _is_climbing_up:
		_climb_up_delta += delta
		
		player.position.y = lerpf(
			_player_position.y,
			_collision_point.y,
			minf(1.0, _climb_up_delta / _climb_up_vertical_delta)
		)
		
		if _climb_up_delta > _climb_up_vertical_delta:
			player.position.z = lerpf(
				_player_position.z,
				_collision_point.z,
				minf(1.0, (_climb_up_delta - _climb_up_vertical_delta) / (_max_climb_up_delta - _climb_up_vertical_delta))
			)
			
		if _climb_up_delta >= _max_climb_up_delta:
			player.set_state(Player.PlayerState.NORMAL)
	elif Input.is_action_just_pressed(&"release"):
		release()
		
func grab() -> void:
	if not player.can_interact():
		return
	
	# Can't climb while holding someting
	if player.entity_handler.is_holding_entity():
		return
		
	if not horizontal_check.is_colliding():
		return
		
	if vertical_check.is_colliding():
		return

	if Input.is_action_pressed(&"grab"):
		player.play_animation(&"ledge_grab")
		player.set_state(Player.PlayerState.ON_LEDGE)
		_is_climbing_up = false
		
func release() -> void:
	player.set_state(player.PlayerState.NORMAL)

func _on_direction_changed(direction: Player.PlayerDirection) -> void:
	if direction == Player.PlayerDirection.LEFT:
		horizontal_check.position.z = absf(horizontal_check.position.z)
		horizontal_check.target_position.z = absf(horizontal_check.target_position.z)
		vertical_check.position.z = absf(vertical_check.position.z)
	elif direction == Player.PlayerDirection.RIGHT:
		horizontal_check.position.z = absf(horizontal_check.position.z) * -1
		horizontal_check.target_position.z = absf(horizontal_check.target_position.z) * -1
		vertical_check.position.z = absf(vertical_check.position.z) * -1
