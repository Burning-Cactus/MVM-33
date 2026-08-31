extends Area3D
class_name DamageArea

@export var attack_damage: int = 0
@export var attack_cooldown: float = 0.0
@export var independent: bool = false
@export var apply_knockback: bool = true
@export var damage_edge: float = 0.02

var player_ref: Player = null
var attack_timer: Timer = null

func _init() -> void:
	# Only monitor the player
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(2, true)
	set_collision_mask_value(2, true)
	
func _ready() -> void:
	var parent = get_parent()
	
	if attack_damage == 0 and "attack_damage" in parent:
		attack_damage = parent.attack_damage
		
		if attack_cooldown == 0 and "attack_cooldown" in parent:
			attack_cooldown = parent.attack_cooldown
	
	if not is_zero_approx(attack_cooldown):
		attack_timer = Timer.new()
		attack_timer.one_shot = true
		add_child(attack_timer)
	
	get_parent().ready.connect(_setup_collision)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
		
func _setup_collision() -> void:
	if not has_node("CollisionShape2D"):
		var parent = get_parent()
		
		var parent_collision := parent.get_node_or_null("CollisionShape3D")
		if parent_collision == null:
			return
			
		var collision = CollisionShape3D.new()
		collision.position = parent_collision.position
		collision.rotation = parent_collision.rotation
		
		var shape = parent_collision.shape.duplicate()
		
		if shape is BoxShape3D:
			shape.size += Vector3(damage_edge * 2.0, damage_edge * 2.0, damage_edge * 2.0)
		elif shape is CylinderShape3D:
			shape.radius += damage_edge
			shape.height += damage_edge * 2.0
		elif shape is CapsuleShape3D:
			shape.radius += damage_edge
			shape.height += damage_edge * 2.0
		else:
			print("Unsupported shape.")
			return
		
		collision.shape = shape

		add_child(collision)
		
func _process(delta: float) -> void:
	process_damage()
	
func process_damage() -> void:
	if player_ref == null:
		return
		
	if attack_timer != null:
		if not attack_timer.is_stopped():
			return
		
		attack_timer.start(attack_cooldown)
		
		player_ref.receive_damage(attack_damage, global_position.z, independent, apply_knockback)
	else:
		player_ref.receive_damage(attack_damage, global_position.z, independent, apply_knockback)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		player_ref = body

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		player_ref = null
