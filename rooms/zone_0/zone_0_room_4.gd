extends Room

@onready var door_gate_left: GateDoor = $Objects/DoorGateLeft
@onready var door_gate_right: GateDoor = $Objects/DoorGateRight

var _right_door_state: bool = false

func _ready():
	super._ready()
	
	# Only lock in room the first time
	if not GameManager.switches.has(door_gate_left.switch_id):
		_right_door_state = GameManager.switches.get(door_gate_right.switch_id, false)
		GameManager.toggle_switch(door_gate_left.switch_id, false)
		door_gate_left.close_door()
		GameManager.toggle_switch(door_gate_right.switch_id, false)
		room_cleared.connect(_on_room_cleared)

func _on_room_cleared() -> void:
	GameManager.toggle_switch(door_gate_left.switch_id, true)
	door_gate_left.open_door()
	GameManager.toggle_switch(door_gate_right.switch_id, _right_door_state)
		
