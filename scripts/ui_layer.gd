extends CanvasLayer

@onready var healthbar: TextureProgressBar = $UI/MarginContainer/VBoxContainer/HPHBox/Healthbar
@onready var health_value: Label = $UI/MarginContainer/VBoxContainer/HPHBox/HealthValue
@onready var skills_h_box: HBoxContainer = $UI/MarginContainer/VBoxContainer/SkillsHBox
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var transition_bg: ColorRect = $TransitionBG
@onready var game_over_bg: ColorRect = $GameOverBG
@onready var boss_ui: Control = $UI/BossUI


func _ready():
	# Connect to global manager updates
	GameManager.player_health_changed.connect(update_health_display)
	GameManager.abilities_updated.connect(update_ability_icons)
	
	# Initial draw
	update_health_display(GameManager.player_data["health"], GameManager.player_data["max_health"])

func update_health_display(current: int, max_health: int):
	var old_value =  healthbar.value
	healthbar.max_value = max_health
	create_tween().tween_property(healthbar,"value",current,0.2)
	health_value.text = str(current) + " / " + str(max_health)

func update_ability_icons(unlocked_list: Array):
	# Clear out existing icons
	for child in skills_h_box.get_children():
		child.queue_free()
		
	# Instantiate an icon representation for each upgrade flag found
	for ability in unlocked_list:
		var icon = TextureRect.new()
		# Assumes textures are named after your items (e.g., "double_jump.png")
		icon.texture = load("res://assets/ability_icons/" + ability + ".png") 
		skills_h_box.add_child(icon)


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_continue_button_pressed() -> void:
	if FileAccess.file_exists(GameManager.SAVE_FILE_PATH):
		game_over_bg.hide()
		var success = GameManager.load_game()
		if not success:
			print("Error loading data file configuration profiles.")
	else:
		game_over_bg.hide()
		get_tree().change_scene_to_file("res://rooms/room_0.tscn")
	
