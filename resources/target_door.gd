extends Resource
class_name TargetDoor

@export var door_id: StringName = &""
@export var door_offset: Vector3 = Vector3.ZERO
@export var player_state: Player.PlayerState = Player.PlayerState.NORMAL
@export var player_direction: Player.PlayerDirection = Player.PlayerDirection.RIGHT
@export var player_velocity: Vector3 = Vector3.ZERO

func _init(
	door_id_: StringName = &"", 
	door_offset_: Vector3 = Vector3.ZERO, 
	player: Player = null
) -> void:
	door_id = door_id_
	door_offset = door_offset_
	if player != null:
		player_state = player.state
		player_direction = player.direction
		player_velocity = player.velocity
