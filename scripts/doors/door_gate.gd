extends Door
class_name GateDoor

@export var raise_amount: float = 2.5
@export var raise_rate: float = 1.5

@onready var trigger_area: Area3D = $TriggerArea

var _start: bool = false
var _start_y: float

func _ready() -> void:
	super._ready()
	
	_start_y = global_position.y

	if is_open:
		global_position.y = _start_y + raise_amount
		
	trigger_area.body_entered.connect(_on_body_entered)
	trigger_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	# We need to skip the first frame because after the scene has 
	# been loaded once, the _ready() global_position will get overridden 
	# by the below before its applied
	if not _start:
		_start = true
		return

	if is_open and not is_equal_approx(global_position.y, _start_y + raise_amount):
		global_position.y = move_toward(global_position.y, _start_y + raise_amount, raise_rate * delta)
	elif not is_open and not is_equal_approx(global_position.y, _start_y):
		global_position.y = move_toward(global_position.y, _start_y, raise_rate * delta)
	
func _on_body_entered(body: Node3D) -> void:
	if switch_id == &"" and body is Player:
		open_door()
	
func _on_body_exited(body: Node3D) -> void:
	if switch_id == &"" and body is Player:
		close_door()
