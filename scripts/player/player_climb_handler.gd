extends Node3D
class_name PlayerClimbHandler

var player: Player = null

func _ready() -> void:
	player = get_parent()
	_add_center_area()
	
func _add_center_area() -> void:
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 0
	area.set_collision_mask_value(7, true)
	
	area.area_entered.connect(_on_center_area_entered)
	area.area_exited.connect(_on_center_area_exited)
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.0, 0.75, 0.75)
	collision.shape = shape
	area.add_child(collision)
	collision.position = Vector3(0.0, 0.125, 0)
	add_child(area)
	
func _add_top_area() -> void:
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 0
	area.set_collision_mask_value(7, true)
	
	area.area_entered.connect(_on_top_area_entered)
	area.area_exitedd.connect(_on_top_area_exited)
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.0, 0.75, 0.75)
	collision.shape = shape
	area.add_child(collision)
	collision.position = Vector3(0.0, 0.125, 0)
	add_child(area)
	
func _on_center_area_entered(area: Area3D) -> void:
	pass
func _on_center_area_exited(area: Area3D) -> void:
	pass

func _on_left_area_entered(area: Area3D) -> void:
	pass
func _on_left_area_exited(area: Area3D) -> void:
	pass
	
func _on_right_area_entered(area: Area3D) -> void:
	pass
func _on_right_area_exited(area: Area3D) -> void:
	pass
	
func _on_top_area_entered(area: Area3D) -> void:
	pass
func _on_top_area_exited(area: Area3D) -> void:
	pass
	
func _on_bottom_area_entered(area: Area3D) -> void:
	pass
func _on_bottom_area_exited(area: Area3D) -> void:
	pass
