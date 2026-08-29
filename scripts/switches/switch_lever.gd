extends Switch
class_name LeverSwitch

@export var lever_angle: Vector3 = Vector3(0, 0, 35)
@export var lever_rate: float = 200

@onready var trigger_area: Area3D = $TriggerArea
@onready var lever: Node3D = $Lever

var _start_angle: Vector3
var _player: Player = null

func _ready() -> void:
	super._ready()
	
	_start_angle = lever.rotation_degrees
		
	if global and switch_id != &"":
		is_on = GameManager.switches.get(switch_id, false)
		
		# Should two switches point to the same id, ensure they are synced
		GameManager.switch_toggled.connect(_on_switch_toggled)
	
	if is_on:
		lever.rotation_degrees = _start_angle + lever_angle 
	else:
		lever.rotation_degrees = _start_angle - lever_angle
		
	trigger_area.body_entered.connect(_on_body_entered)
	trigger_area.body_exited.connect(_on_body_exited)
	
func _process(delta: float) -> void:
	if _player != null and _player.entity_handler.is_holding_entity():
		if Input.is_action_just_pressed(&"interact"):
			if is_on:
				toggle_off()
			else:
				toggle_on()
				
func _physics_process(delta: float) -> void:
	if is_on and lever.rotation_degrees != _start_angle + lever_angle:
		lever.rotation_degrees = lever.rotation_degrees.move_toward(
			_start_angle + lever_angle, 
			lever_rate * delta
		)
	elif not is_on and lever.rotation_degrees != _start_angle - lever_angle:
		lever.rotation_degrees = lever.rotation_degrees.move_toward(
			_start_angle - lever_angle, 
			lever_rate * delta
		)
	
func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		_player = body
	
func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		_player = null

func _on_switch_toggled(switch_id_: StringName, is_on_: bool) -> void:
	if switch_id_ == switch_id:
		is_on = is_on_
