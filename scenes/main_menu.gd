extends CanvasLayer

@onready var start_button: Button = $Control/ColorRect/Label/VBoxContainer/StartButton
@onready var continue_button: Button = $Control/ColorRect/Label/VBoxContainer/ContinueButton
@onready var settings_button: Button = $Control/ColorRect/Label/VBoxContainer/SettingsButton
@onready var exit_button: Button = $Control/ColorRect/Label/VBoxContainer/ExitButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().paused = false
	settings_button.disabled = true

	# Evaluate if continue buttons should be clickable or grayed out
	if FileAccess.file_exists(GameManager.SAVE_FILE_PATH):
		continue_button.disabled = false
		continue_button.grab_focus() # Good practice for keyboard/gamepad usability
	else:
		continue_button.disabled = true
		start_button.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://rooms/room_0.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_continue_button_pressed() -> void:
	var success = GameManager.load_game()
	if not success:
		print("Error loading data file configuration profiles.")
