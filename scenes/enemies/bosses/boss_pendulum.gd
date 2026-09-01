extends EnemyBase

func _physics_process(delta: float) -> void:
	play_animation(&"idle")
