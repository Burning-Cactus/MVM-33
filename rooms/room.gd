extends Node3D
class_name Room

var player:Player 
@export var is_boss_room: bool = false
@export var boss_enemy: EnemyBase
@export var boss_switch_id: StringName = &""
@export var boss_trigger_area: Area3D

@onready var discovery_areas: Node3D = $DiscoveryAreas
@onready var enemies: Node3D = $Enemies

signal room_cleared

func _init() -> void:
	add_to_group("Room")

func _ready():
	get_tree().paused = false
	
	player = get_tree().get_first_node_in_group("Player")
	
	if player and GameManager.target_door != null:
		GameManager.register_player(player)

	for area_ in $DiscoveryAreas.get_children():
		if area_ is DiscoveryArea:
			area_.register_area()
	
	UiLayer.transition_bg.color = Color.BLACK
	UiLayer.animation_player.play_backwards("fade_to_black")
	
	if is_boss_room and boss_trigger_area:
		boss_trigger_area.body_entered.connect(_on_player_entered_boss_area_trigger)
	
	if enemies != null:
		for enemy: EnemyBase in enemies.get_children():
			enemy.tree_exited.connect(_on_enemy_death)
	
	
func _on_player_entered_boss_area_trigger(body: Node3D):
	if not body is Player:
		return
		
	boss_trigger_area.body_entered.disconnect(_on_player_entered_boss_area_trigger)
	boss_trigger_area.queue_free()
	
	if GameManager.permanent_flags.has(boss_enemy.unique_enemy_id + "_defeated"):
		return
		
	if boss_enemy == null:
		return
		
	if boss_switch_id != &"":
		GameManager.toggle_switch(boss_switch_id, false)
	
	boss_enemy.tree_exited.connect(_on_boss_death)
	
	UiLayer.show_boss_ui(boss_enemy)
		
func _on_boss_death():
	if not GameManager.permanent_flags.has(boss_enemy.unique_enemy_id + "_defeated"):
		GameManager.permanent_flags.append(boss_enemy.unique_enemy_id + "_defeated")
	UiLayer.hide_boss_ui()
	
	if boss_switch_id != &"":
		GameManager.toggle_switch(boss_switch_id, true)

func _on_enemy_death():
	if enemies.get_children().size() == 0:
		room_cleared.emit()
