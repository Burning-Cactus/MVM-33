extends EnemyBase

@export_group("Movement")
@export var move_length_y: float = 2.0
@export var move_length_z: float = 8.0
@export var move_period: float = 7.0

@export_group("Spinning")
@export var spin_period: float = 2.0

@export_group("Pendulum")
@export var pendulum_max_angle: float = 40.0
@export var pendulum_period: float = 3.0
@export var pendulum_attack_damage: float = 15.0

var _pendulum_rest: Transform3D
var _pendulum_delta: float = 0.0
var _move_origin: Vector3
var _move_delta: float = 0.0
var _is_spinning: bool = false
var _spin_rotation: float
var _spin_delta: float = 0.0

@onready var pendulum: MeshInstance3D = $Visuals/Model/MAIN_002/Skeleton3D/FEET_003
@onready var pendulum_pivot_marker: Marker3D = $PendulumPivotMarker
@onready var pendulum_damage_area: DamageArea = $Visuals/Model/MAIN_002/Skeleton3D/FEET_003/DamageArea

func _ready() -> void:
	super._ready()
	_pendulum_rest = pendulum.transform
	_move_origin = global_position
	_spin_rotation = model.rotation.y
	
	pendulum_damage_area.attack_damage = pendulum_attack_damage
	pendulum_damage_area.attack_cooldown = attack_cooldown
	
func _physics_process(delta: float) -> void:
	play_animation(&"idle")

	if _is_spinning:
		_spin_delta += delta
		
		var weight: float = clampf(_spin_delta / spin_period, 0.0, 1.0)
		weight = smoothstep(0.0, 1.0, weight)
		print(weight, ": ", lerp_angle(0.0, TAU, weight))
		model.rotation.y = _spin_rotation + lerpf(0.0, TAU, weight)
		
		if _spin_delta >= spin_period:
			_is_spinning = false
			model.rotation.y = _spin_rotation

	# Movement
	_move_delta += delta
	var move_t := _move_delta * TAU / move_period
	global_position = _move_origin + Vector3(
		0.0,
		move_length_y * sin(move_t) * cos(move_t),
		(move_length_z * 0.5) * sin(move_t),
	)
	
	if _move_delta >= (move_period * 2.0) - (spin_period / 2.0):
		_is_spinning = true
		_spin_delta = 0.0
		
	if _move_delta >= (move_period * 2.0):
		_move_delta -= (move_period * 2.0)
	
	# Pendulum
	_pendulum_delta += delta
	var t: float = _pendulum_delta * TAU / pendulum_period
	var angle_deg := pendulum_max_angle * sin(t)
	rotate_pendulum(deg_to_rad(angle_deg))
	
func rotate_pendulum(angle: float) -> void:
	var pivot := pendulum_pivot_marker.position
	var offset := _pendulum_rest.origin - pivot
	offset = offset.rotated(Vector3.BACK, angle)
	pendulum.position = pivot + offset
	pendulum.basis = _pendulum_rest.basis.rotated(Vector3.BACK, angle)
