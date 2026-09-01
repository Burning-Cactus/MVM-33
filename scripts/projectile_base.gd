extends Area3D
class_name ProjectileBase

@export var max_life_span: float = 4.0

@export_group("Movement")
@export var speed: float = 12.0
@export var rotation_speed: float = 0.0

@export_group("Damage")
@export var attack_damage: int = 0
@export var independent: bool = false
@export var apply_knockback: bool = true

var target: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.ZERO

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Automatically clean up if it misses the player and flies off-screen
	await get_tree().create_timer(max_life_span).timeout
	queue_free()

func launch(target_: Vector3):
	target = target_

func _physics_process(delta):
	if direction == Vector3.ZERO:
		direction = (target - global_position).normalized()
		
	global_position += direction * speed * delta
	global_position.x = 0 # Plane lock constraint
	
	if not is_zero_approx(rotation_speed):
		rotation_degrees.x += rotation_speed * delta
		rotation.x = wrapf(rotation.x, 0.0, TAU)

func _on_body_entered(body):
	if body.is_in_group(&"Player"):
		body.receive_damage(attack_damage, global_position.z, independent, apply_knockback)
	
	queue_free()

func _on_area_entered(area: Area3D) -> void:
	print(area)
	if area.is_in_group(&"Attack"):
		queue_free()
