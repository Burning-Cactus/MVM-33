extends RigidBody3D
class_name Entity

@export var can_kick: bool = false
@export var can_push: bool = false
@export var can_pickup: bool = false
@export var can_throw: bool = false

@onready var collision: CollisionShape3D = $CollisionShape3D

func _init() -> void:
	# Entity
	set_collision_layer_value(4, true)
	set_collision_mask_value(4, true)
	
	# Rope
	set_collision_layer_value(6, true)
	set_collision_mask_value(6, true)

func _ready() -> void:
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	axis_lock_linear_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	continuous_cd = true
	
	# To prevent it from not falling after collapsible platform disapears
	can_sleep = false

func get_size() -> Vector3:
	# TODO: Support more shapes beside BoxShape3d
	return $CollisionShape3D.shape.get_size()
