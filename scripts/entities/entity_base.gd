extends RigidBody3D
class_name Entity

@export var can_kick: bool = false
@export var can_push: bool = false
@export var can_pickup: bool = false
@export var can_throw: bool = false

@export var kick_force: float = 60
@export var push_force: float = 1.1
@export var throw_force: float = 30

@onready var collision: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	axis_lock_linear_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true

func get_size() -> Vector3:
	# TODO: Support more shapes beside BoxShape3d
	return $CollisionShape3D.shape.get_size()
