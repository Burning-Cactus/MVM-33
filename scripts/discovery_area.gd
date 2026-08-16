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
