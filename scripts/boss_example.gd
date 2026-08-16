extends CharacterBody3D

@export var max_health: int = 500
@export var speed: float = 3.5
@export var rotation_speed: float = 12.0
const PROJECTILE_BASE = preload("uid://bmnfiqvwl81ih")

var current_health: int
var direction: int = -1 # Face left initially
var player_ref: CharacterBody3D = null
var is_attacking: bool = false
var state_timer: Timer

@onready var visuals = $Visuals
@onready var anim_player = $Visuals/AnimationPlayer

func _ready():
	current_health = max_health
	add_to_group("Enemy")
	
	# Find the player in the room scene tree dynamically
	player_ref = get_tree().get_first_node_in_group("Player")
	
	# Initialize an attack loop selection cadence
	state_timer = Timer.new()
	add_child(state_timer)
	state_timer.timeout.connect(choose_random_attack)
	state_timer.start(3.0) # Choose an attack phase every 3 seconds

func _physics_process(delta):
	# Apply standard falling gravity tracking
	if not is_on_floor():
		velocity += get_gravity() * delta

	# If not locked in an attack animation, move slowly towards the player's track
	if not is_attacking and player_ref:
		direction = sign(player_ref.global_position.z - global_position.z)
		velocity.z = direction * speed
		if anim_player.has_animation("walk"):
			anim_player.play("walk")
	elif is_attacking:
		# Gradually slow down sliding movement during attack actions
		velocity.z = move_toward(velocity.z, 0, speed * delta * 2)

	# 2.5D Plane Locking Constraints
	velocity.x = 0
	global_position.x = 0
	
	move_and_slide()
	handle_3d_rotation(delta)

func handle_3d_rotation(delta):
	var target_y_rot = 0.0 if direction > 0 else PI
	visuals.rotation.y = rotate_toward(visuals.rotation.y, target_y_rot, rotation_speed * delta)

func choose_random_attack():
	if is_attacking or not player_ref:
		return
		
	state_timer.stop()
	is_attacking = true
	
	# Randomly pick an attack variation (0, 1, or 2)
	var attack_choice = randi() % 3
	match attack_choice:
		0: attack_ground_slam()
		1: attack_dash_charge()
		2: attack_projectile_burst()

func end_attack_phase():
	is_attacking = false
	state_timer.start(randf_range(2.0, 3.5)) # Wait a moment before the next attack

func take_damage(amount: int, _source_z: float):
	current_health -= amount
	# Bosses ignore standard knockback forces to keep them intimidating!
	
	if current_health <= 0:
		die()

func die():
	# Play explosion or crumbling animations here
	queue_free()

# --- ATTACK VARIATION 1: HEAVY GROUND SLAM ---
func attack_ground_slam():
	anim_player.play("ground_slam")
	await get_tree().create_timer(0.6).timeout # Sync with slam visual impact point
	
	# Deal massive screen-wide shake or proximity footprint damage
	if player_ref and global_position.distance_to(player_ref.global_position) < 6.0:
		player_ref.receive_damage(35, global_position.z)
		
	await get_tree().create_timer(0.8).timeout # Recovery window
	end_attack_phase()

# --- ATTACK VARIATION 2: SPEED DASH CHARGE ---
func attack_dash_charge():
	anim_player.play("charge_tell") # Warning flash animation
	await get_tree().create_timer(0.7).timeout
	
	# Rocket forward horizontally across your Z-axis line track
	velocity.z = direction * (speed * 4.5) 
	anim_player.play("charge_dash")
	
	# Active collision damage scan check
	await get_tree().create_timer(0.5).timeout
	if player_ref and global_position.distance_to(player_ref.global_position) < 3.0:
		player_ref.receive_damage(25, global_position.z)
		
	end_attack_phase()

# --- ATTACK VARIATION 3: RANGED PROJECTILE BURST ---
func attack_projectile_burst():
	anim_player.play("cast_magic")
	
	# Fire 3 sequential spell balls down the pipeline tracking rail
	for i in range(3):
		if not player_ref: break
		await get_tree().create_timer(0.3).timeout
		spawn_boss_projectile()
		
	await get_tree().create_timer(0.5).timeout
	end_attack_phase()

func spawn_boss_projectile():
	if PROJECTILE_BASE:
		var proj = PROJECTILE_BASE.instantiate()
		get_parent().add_child(proj)
		proj.global_position = global_position + Vector3(0, 1.2, direction * 1.0)
		if proj.has_method("launch"):
			proj.launch(direction)
