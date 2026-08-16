extends Camera3D

@export var follow_speed: float = 5.0
@export var offset: Vector3 = Vector3(8, 2, 0)

var player: Player
var is_tracking: bool = true

func _ready() -> void:
	# Connect to tracking freeze/resume events
	EventBus.camera_stop_tracking_requested.connect(_on_camera_stop)
	EventBus.camera_start_tracking_requested.connect(_on_camera_start)
	# Also re-fetch the player instance when a new room loads
	EventBus.room_changed.connect(_on_room_changed)
	if not is_node_ready():
		await ready
	_find_player()
	
func _physics_process(delta: float) -> void:
	# If the camera is frozen, completely skip the tracking code
	if not is_tracking or not is_instance_valid(player):
		#print(is_tracking, player)
		return

	# Standard smooth 2.5D tracking logic
	var target_position = player.global_position + offset
	
	# Optional: Keep the camera strictly 2D by freezing its own Z depth 
	# target_position.z = offset.z 

	global_position = global_position.lerp(target_position, follow_speed * delta)

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _on_room_changed(_new_room: Node) -> void:
	# Freshly spawned rooms mean a new player node instance
	_find_player()
	
	# Optional: Snap camera instantly to the new player position while screen is black
	if is_instance_valid(player):
		global_position = player.global_position + offset

func _on_camera_stop() -> void:
	is_tracking = false

func _on_camera_start() -> void:
	is_tracking = true
