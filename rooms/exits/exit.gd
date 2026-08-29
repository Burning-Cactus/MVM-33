extends StaticBody3D

@export_file("*.tscn") var target_room_path: String # Path to the next room scene
@export var door_id: String = ""              # This door's unique identifier
@export var target_door_id: String = ""       # The door ID in the NEXT room
@export var exit_velocity: Vector3 = Vector3.ZERO
@export var maintain_velocity: bool = false
@export var maintain_direction: bool = false
@export var is_enabled: bool = true

@export_group("Switch")
@export var switch_id: StringName = &""
@export var global: bool = false

@onready var exit_area: Area3D = $ExitArea
@onready var spawn_marker: Marker3D = $Marker3D

func _ready():
	add_to_group(&"Exit")
	# Connect the collision signal
	exit_area.body_entered.connect(_on_exit_area_body_entered)
	
	if switch_id != &"" and global:
		is_enabled = GameManager.switches.get(switch_id, false)
		GameManager.switch_toggled.connect(_on_switch_toggled)
	
func _on_exit_area_body_entered(body: Node3D) -> void:
	if not is_enabled:
		return
		
	# Check if the colliding object is the player
	if body is Player:
		# Save current player health before leaving
		
		var door_offset: Vector3 = Vector3.ZERO
		
		# Vertical exit
		if is_zero_approx(spawn_marker.position.z):
			door_offset.z = body.global_position.z - spawn_marker.global_position.z
		else: # Horizontal exit
			door_offset.y = body.global_position.y - spawn_marker.global_position.y
			
		# Execute the transition
		GameManager.transition_to_room(
			target_room_path, 
			target_door_id,
			door_offset,
			body,
		)

func get_spawn_position() -> Vector3:
	return spawn_marker.global_position

func _on_switch_toggled(switch_id_: StringName, is_on: bool) -> void:
	if switch_id_ != switch_id:
		return
	
	is_enabled = is_on
