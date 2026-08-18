extends StaticBody3D
class_name CollapsiblePlatformBase

@export var collapse_delay: float = 1.5
@export var restore_delay: float = 0.0
@export var cancel_on_exit: bool = false

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var trigger_area: Area3D = $TriggerArea

var is_collapsed: bool = false
var _collapse_timer: Timer
var _entities: Array[Node3D] = []

func _ready() -> void:
	_collapse_timer = Timer.new()
	_collapse_timer.one_shot = true
	add_child(_collapse_timer)
	_collapse_timer.timeout.connect(_on_collapse_timeout)

	trigger_area.body_entered.connect(_on_body_entered)
	trigger_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if is_collapsed:
		return
		
	if body is Player or body is Entity:
		if not _entities.has(body):
			_entities.append(body)
			
		_collapse_timer.start(collapse_delay)

func _on_body_exited(body: Node3D) -> void:
	if _entities.has(body):
		_entities.erase(body)
		
	if (_entities.is_empty() and 
		cancel_on_exit and 
		not _collapse_timer.is_stopped()
	):
		_collapse_timer.stop()

func _on_collapse_timeout() -> void:
	if is_collapsed:
		restore()
	else:
		collapse()

func collapse() -> void:
	if is_collapsed:
		return
		
	is_collapsed = true
	collision.set_deferred("disabled", true)
	
	if restore_delay != 0.0:
		_collapse_timer.start(restore_delay)
		
func restore() -> void:
	if not is_collapsed:
		return
		
	is_collapsed = false
	collision.set_deferred("disabled", false)
