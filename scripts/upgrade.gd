class_name Upgrade
extends Area3D

enum Type {SWORD, HEAD, DOUBLE_JUMP, SLIDE, MAX_HEALTH}

@export var upgrade_type: Type

var anchor_position: Vector3
var time_alive: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_mask = 2
	collision_layer = 0
	anchor_position = position


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		if upgrade_type == Type.MAX_HEALTH:
			GameManager.update_max_health(20)
		else:
			var ability_name: String
			match upgrade_type:
				Type.HEAD:
					ability_name = "head"
				Type.DOUBLE_JUMP:
					ability_name = "double_jump"
				Type.SLIDE:
					ability_name = "slide"
			body.unlock_ability(ability_name)
		queue_free()

func _process(delta: float) -> void:
	const frequency := 2.0
	const wave_length: float = frequency * PI * 2.0
	time_alive += delta
	if time_alive > wave_length:
		time_alive = fmod(time_alive, wave_length)
	rotate(Vector3(0, 1, 0), 0.3 * delta)
	position.y = anchor_position.y + 0.1 * sin(frequency * time_alive)
