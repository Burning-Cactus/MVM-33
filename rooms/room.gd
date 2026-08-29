extends Node3D
class_name Room

var player:Player 
@export var is_boss_room:bool = false
@export var boss_enemy:PackedScene
@export var boss_id:String ="test_boss"
@export var boss_doors:Node3D #if its a boss room, you should drag the BossDoors node containing the doors here
@export var boss_trigger_area:Area3D
@export var boss_spawn_point:Marker3D

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
	
	if is_boss_room:
		if GameManager.permanent_flags.has(boss_id + "_defeated"):
			boss_trigger_area.queue_free()
			set_doors(false)
			return

			set_doors(false)
			boss_trigger_area.body_entered.connect(_on_player_entered_boss_area_trigger)
			
	for enemy: EnemyBase in enemies.get_children():
		enemy.tree_exited.connect(_on_enemy_death)

func set_doors(lock: bool):
	for door in boss_doors.get_children():
		door.lock(lock) #there is no door scene yet but it should be just a staticbody with a mesh, maybe an animation player if we want a fancier door animation instance of just tweening y position
		
func _on_player_entered_boss_area_trigger(body:Node3D):
	if body is Player:
		boss_trigger_area.body_entered.disconnect(_on_player_entered_boss_area_trigger)
		boss_trigger_area.queue_free()
		spawn_boss()
		
func spawn_boss():
	set_doors(true)
	var boss_instance = boss_enemy.instantiate()
	add_child(boss_instance)
	boss_instance.global_position = boss_spawn_point.global_position
		
	boss_instance.tree_exited.connect(_on_boss_death)
	UiLayer.show_boss_ui(boss_instance)#not implemented yet, connect take_damage/die to UI callbacks and show the bar
		
func _on_boss_death():
	set_doors(false)
	if not GameManager.permanent_flags.has(boss_id + "_defeated"):
		GameManager.permanent_flags.append(boss_id + "_defeated")
	UiLayer.hide_boss_ui()#not implemented yet, disconnect the ui update signals and hide the bar

func _on_enemy_death():
	if enemies.get_children().size() == 0:
		room_cleared.emit()
