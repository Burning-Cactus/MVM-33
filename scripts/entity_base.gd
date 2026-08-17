extends CharacterBody3D
class_name Entity

@export var can_kick: bool = false
@export var can_push: bool = false
@export var can_pickup: bool = false
@export var can_throw: bool = false

@export var kick_force: float = 20
@export var push_force: float = 1.1
@export var throw_force: float = 10
@export var friction: float = 50.0

var disabled: bool = false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if disabled:
		velocity = Vector3.ZERO
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			velocity.z = move_toward(velocity.z, 0.0, friction * delta)
		
		move_and_slide()

func get_size() -> Vector3:
	# TODO: Support more shapes beside BoxShape3d
	return $CollisionShape3D.shape.get_size()
