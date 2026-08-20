extends Area3D


@export_file("*.tscn") var target_room_path: String # Path to the next room scene
@export var door_id: String = "Door_A"              # This door's unique identifier
@export var target_door_id: String = "Door_BA"       # The door ID in the NEXT room

@onready var spawn_marker: Marker3D = $Marker3D


func _ready():
	# Connect the collision signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check if the colliding object is the player
	if body is Player:
		# Save current player health before leaving
		
		# Execute the transition
		GameManager.transition_to_room(target_room_path, target_door_id)

func get_spawn_position() -> Vector3:
	return spawn_marker.global_position
