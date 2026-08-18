extends Switch
class_name PressureSwitch

@export var depression_amount: float = 0.15
@export var depression_rate: float = 0.5

@onready var trigger_area: Area3D = $TriggerArea

var _start_y: float
var _entities: Array[Node3D] = []

func _ready() -> void:
	super._ready()
	
	_start_y = position.y
	if is_on:
		position.y -= depression_amount
		
	trigger_area.body_entered.connect(_on_body_entered)
	trigger_area.body_exited.connect(_on_body_exited)
	
func _physics_process(delta: float) -> void:
	if is_on and not is_equal_approx(position.y, _start_y - depression_amount):
		position.y = move_toward(position.y, _start_y - depression_amount, depression_rate * delta)
	elif not is_on and not is_equal_approx(position.y, _start_y):
		position.y = move_toward(position.y, _start_y, depression_rate * delta)
	
func _on_body_entered(body: Node3D) -> void:
	if body is Player or body is Entity:
		if not _entities.has(body):
			_entities.append(body)
		toggle_on()
	
func _on_body_exited(body: Node3D) -> void:
	if body is Player or body is Entity:
		if _entities.has(body):
			_entities.erase(body)
			
		if _entities.size() == 0:
			toggle_off()
