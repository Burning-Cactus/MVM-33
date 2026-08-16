extends Projectile


@export var initial_speed: float = 8.0
@export var return_acceleration: float = 12.0
@export var max_lifetime: float = 5.0
@export var spin_speed: float = 25.0 # How fast the 3D model rotates visually

var current_velocity: float = 0.0
var is_returning: bool = false
var spawn_z_position: float = 0.0

@onready var visuals: MeshInstance3D = $MeshInstance3D

func _ready():
	body_entered.connect(_on_body_entered)
	
	spawn_z_position = global_position.z
	
	await get_tree().create_timer(max_lifetime).timeout
	queue_free()

func launch(dir: float):
	move_direction = dir
	current_velocity = dir * initial_speed

func _physics_process(delta):
	# 1. BOOMERANG MATH: Pull the axe back toward the launch point over time
	# This constantly applies a force in the opposite direction of the initial throw
	current_velocity -= move_direction * return_acceleration * delta
	
	# Update the Z position along your 2.5D tracking line
	global_position.z += current_velocity * delta
	
	# 2. 2.5D CONSTRAINT: Force X axis to remain perfectly locked
	global_position.x = 0
	
	# 3. VISUAL SPIN: Rotate the 3D mesh rapidly on its X-axis to make it look like it's spinning
	if visuals:
		visuals.rotate_x(spin_speed * delta)
		
	# 4. OUT OF BOUNDS CHECK: Delete the axe if it travels too far past its spawn point on its return flight
	check_out_of_bounds()

func check_out_of_bounds() -> void:
	# Determine if the axe has crossed back over the point where it was originally thrown
	var relative_z = global_position.z - spawn_z_position
	
	# If thrown Right (+Z), it is out of bounds when it returns past the spawn point into Left (-Z)
	if move_direction > 0 and current_velocity < 0 and relative_z < -5.0:
		queue_free()
	# If thrown Left (-Z), it is out of bounds when it returns past the spawn point into Right (+Z)
	elif move_direction < 0 and current_velocity > 0 and relative_z > 5.0:
		queue_free()
		
func _on_body_entered(body):
	if body is Player:
		body.receive_damage(20, global_position.z)
