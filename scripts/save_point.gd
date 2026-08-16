extends Area3D

var player_inside: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# Assumes you configured "interact" (e.g., E key or Gamepad Arrow Up) in Input Map
	print(player_inside)
	if player_inside and Input.is_action_just_pressed("up"):
		print("saving?")
		GameManager.update_health(GameManager.player_data["max_health"])
		var current_scene_file = get_tree().current_scene.scene_file_path
		GameManager.save_game(current_scene_file)
		print("game saved")

func _on_body_entered(body):
	print("penis")
	if body is Player:
		player_inside = true
		# Optionally display a floating screen UI prompt ("Press E to Save")

func _on_body_exited(body):
	if body is Player:
		player_inside = false
