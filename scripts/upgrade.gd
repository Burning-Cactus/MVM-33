extends Area3D

enum Type {MAX_HEALTH, DOUBLE_JUMP, SLIDE}

@export var upgrade_type: Type

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		if upgrade_type == Type.MAX_HEALTH:
			GameManager.update_max_health(20)
		else:
			var ability_name: String
			match upgrade_type:
				Type.DOUBLE_JUMP:
					ability_name = "double_jump"
				Type.SLIDE:
					ability_name = "slide"
			body.unlock_ability(ability_name)
		queue_free()
