extends AnimatableBody3D
class_name Door

@export var switch_id: StringName = &""
@export var is_open: bool = false
@export var global: bool = false

signal door_opened()
signal door_closed()

func _ready() -> void:
	if global and switch_id != &"":
		is_open = GameManager.switches.get(switch_id, false)
		GameManager.switch_toggled.connect(_on_switch_toggled)
		
func open_door() -> void:
	if not is_open:
		is_open = true
		door_opened.emit()
	
func close_door() -> void:
	if is_open:
		is_open = false
		door_closed.emit()

func _on_switch_toggled(switch_id_: StringName, is_on: bool) -> void:
	if switch_id_ != switch_id:
		return
		
	if is_on:
		open_door()
	else:
		close_door()
