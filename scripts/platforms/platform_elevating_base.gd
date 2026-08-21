extends AnimatableBody3D
class_name ElevatingPlatform

@export var switch_id: StringName = &""
@export var global: bool = false
@export var is_raised: bool = false
@export var raised_position: Vector3
@export var lowered_position: Vector3
@export var speed: float = 5.0

signal platform_raised()
signal platform_lowered()

func _ready() -> void:
	if global and switch_id != &"":
		is_raised = GameManager.switches.get(switch_id, false)
		GameManager.switch_toggled.connect(_on_switch_toggled)
		
	if is_raised:
		position = raised_position
	else:
		position = lowered_position
		
func _physics_process(delta: float) -> void:
	if is_raised and position != raised_position:
		position = position.move_toward(
			raised_position, 
			speed * delta
		)
	elif not is_raised and position != lowered_position:
		position = position.move_toward(
			lowered_position, 
			speed * delta
		)
		
func raise_platform() -> void:
	if not is_raised:
		is_raised = true
		platform_raised.emit()
	
func lower_platform() -> void:
	if is_raised:
		is_raised = false
		platform_lowered.emit()

func _on_switch_toggled(switch_id_: StringName, is_on: bool) -> void:
	if switch_id_ != switch_id:
		return
		
	if is_on:
		raise_platform()
	else:
		lower_platform()
