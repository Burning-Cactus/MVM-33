extends Node3D
class_name Ladder

@export_group("Ladder Style")
@export var ladder_type: LadderType = LadderType.FORWARD
@export var ladder_top: PackedScene = null
@export var ladder_center: PackedScene = null
@export var ladder_bottom: PackedScene = null

@export_group("Ladder Segments")
@export_range(2, 20, 1, "or_greater") var segment_count: int = 6
@export var segment_size: Vector3 = Vector3(0.1, 1.0, 1.0)
@export var segment_grab_length: float = 0.05

enum LadderType {
	FORWARD,
	LEFT,
	RIGHT,
	CENTER,
}

const FORWARD_OFFSET_X = 0.548

func _init() -> void:
	add_to_group(&"Ladders")

func _ready() -> void:
	generate_ladder()

func generate_ladder() -> void:
	clear_ladder()
	
	var current_position: Vector3
	
	if ladder_type == LadderType.FORWARD:
		# 0.5 is half of player size.x
		current_position = Vector3(-FORWARD_OFFSET_X - (segment_size.x / 2.0), -segment_size.y / 2.0, 0)
	elif ladder_type == LadderType.CENTER:
		current_position = Vector3(0, -segment_size.y / 2.0, 0)
	else:
		current_position = Vector3(segment_size.x / 2.0, -segment_size.y / 2.0, 0)
	
	for i in segment_count:
		var segment: Node3D
		if i == 0:
			segment = ladder_top.instantiate() as Node3D
		elif i == segment_count - 1:
			segment = ladder_bottom.instantiate() as Node3D
		else:
			segment = ladder_center.instantiate() as Node3D
			
		segment.position = current_position
		add_child(segment)
		
		current_position.y -= segment_size.y
		
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 0
	
	if ladder_type == LadderType.FORWARD:
		# Ladder
		area.set_collision_layer_value(7, true)
	else:
		# Ladder
		area.set_collision_layer_value(7, true)
		# Interact
		area.set_collision_layer_value(5, true)
	
	var collision := CollisionShape3D.new()
	collision.position.y = -segment_count * segment_size.y / 2.0
	
	var shape := BoxShape3D.new()
	if ladder_type == LadderType.FORWARD:
		shape.size = Vector3(
			2.0, 
			segment_count * segment_size.y, 
			segment_size.z
		)
	elif ladder_type == LadderType.CENTER:
		shape.size = Vector3(
			segment_size.x + (segment_grab_length * 2), 
			segment_count * segment_size.y, 
			segment_size.z
		)
	else:
		collision.position.x = (segment_grab_length / 2.0)
		shape.size = Vector3(
			segment_size.x + segment_grab_length, 
			segment_count * segment_size.y, 
			segment_size.z
		)
	collision.shape = shape
	
	area.add_child(collision)
	add_child(area)
	
	if ladder_type == LadderType.LEFT or ladder_type == LadderType.CENTER:
		rotation_degrees.y = 90.0
	elif ladder_type == LadderType.RIGHT:
		rotation_degrees.y = 270.0
			
		
func clear_ladder() -> void:
	for child in get_children():
		child.queue_free()
