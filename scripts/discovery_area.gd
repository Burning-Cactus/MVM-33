extends Area3D
class_name DiscoveryArea
#the game´s "tile size". Used as a measuring stick for designing rooms and updating map

@export_group("Area Settings")
@export var room_coordinates: Vector2i = Vector2i(0, 0)
@export var is_save_room: bool = false

@export_subgroup("Room Borders")
@export_enum("Wall", "Door", "None") var border_top: String = "Wall"
@export_enum("Wall", "Door", "None") var border_bottom: String = "Wall"
@export_enum("Wall", "Door", "None") var border_left: String = "Wall"
@export_enum("Wall", "Door", "None") var border_right: String = "Wall"

func _init() -> void:
	# Only monitor the player
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(2, true)
	set_collision_mask_value(2, true)
	
	# Disable until player is positoined
	monitoring = false

func _ready() -> void:
	var collision = CollisionShape3D.new()
	collision.position.y = 6.0
	
	var shape = BoxShape3D.new()
	shape.size = Vector3(12.0, 11.9, 15.9)
	
	collision.shape = shape
	
	add_child(collision)
	
	body_entered.connect(_on_body_entered)

func register_area() -> void:
	# We need to enable monitoring the player after it is 
	# positioned to not trigger from default player position
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	monitoring = true

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		var map_packet = {
			"is_save_room": is_save_room,
			"borders": {
				"top": border_top,
				"bottom": border_bottom,
				"left": border_left,
				"right": border_right
			}
		}
		GameManager.discover_room(room_coordinates, map_packet)
