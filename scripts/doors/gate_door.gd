extends Door
class_name GateDoor

@export var raise_amount: float = 2.5
@export var raise_rate: float = 1.5

@onready var trigger_area: Area3D = $TriggerArea

var _start_y: float

func _ready() -> void:
	super._ready()
	
	_start_y = position.y
	if is_open:
		position.y -= raise_amount
	
	trigger_area.body_entered.connect(_on_body_entered)
	trigger_area.body_exited.connect(_on_body_exited)
	
	if switch_id and global:
		GameManager.switch_toggled.connect(_on_switch_toggled)
	
func _physics_process(delta: float) -> void:
	if is_open and not is_equal_approx(position.y, _start_y + raise_amount):
		position.y = move_toward(position.y, _start_y + raise_amount, raise_rate * delta)
	elif not is_open and not is_equal_approx(position.y, _start_y):
		position.y = move_toward(position.y, _start_y, raise_rate * delta)
	
func _on_body_entered(body: Node3D) -> void:
	if switch_id == &"" and body is Player:
		open_door()
	
func _on_body_exited(body: Node3D) -> void:
	if switch_id == &"" and body is Player:
		close_door()
		
func _on_switch_toggled(switch_id_: StringName, is_on: bool) -> void:
	print(switch_id)
	if switch_id_ == switch_id:
		if is_on:
			open_door()
		else:
			close_door()
