extends CanvasLayer

@onready var map_drawer: Control = $Background/MapContainer/MapDrawer

func _ready():
	visible = false

func _input(event):
	if event.is_action_pressed("map_t"):
		if visible:
			visible = false
			get_tree().paused = false
		else:
			visible = true
			get_tree().paused = true 

		if visible:
			map_drawer.queue_redraw()
