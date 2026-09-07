extends Area3D
class_name Projectile

@export var travel_speed: float = 12.0
var move_direction: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	# Automatically clean up if it misses the player and flies off-screen
	await get_tree().create_timer(4.0).timeout
	queue_free()

func launch(dir: float):
	move_direction = dir

func _physics_process(delta):
	# Fly down the locked Z axis
	global_position.z += move_direction * travel_speed * delta
	global_position.x = 0 # Plane lock constraint

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.receive_damage(15, global_position.z)
		queue_free()
