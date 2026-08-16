extends CharacterBody3D
class_name Player

@export_group("Knockback Settings")
@export var player_knockback_force: float = 8.0
@export var player_knockback_duration: float = 0.3

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var model: MeshInstance3D = $Model
@onready var attack_area: Area3D = $Model/AttackArea

@onready var damage_timer: Timer = $DamageTimer
var is_invincible: bool = false

var health:int  = 100
var attack_damage:int = 7

var double_jump_unlocked = false
var slide_unlocked = false

var input_disabled:bool = false

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _ready() -> void:
	health = GameManager.player_data["health"]
	attack_area.monitoring = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if input_disabled and is_on_floor():
		velocity.z = 0
	if not input_disabled:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			
		if Input.is_action_just_pressed("attack"):
			animation_player.play("attack")
			handle_attack()
		var input_dir := Input.get_vector("right", "left", "up", "down")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			if direction.x>0:
				model.rotation_degrees.y=180
			else:
				model.rotation_degrees.y=0
				
			velocity.z = direction.x * SPEED
		else:
			velocity.z = move_toward(velocity.x, 0, SPEED)

	velocity.x = 0
	global_position.x = 0
	move_and_slide()
	
	check_contact_damage()
	
	
func check_contact_damage():
	if is_invincible:
		return	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		
		if body and "attack_damage" in body:
			receive_damage(body.attack_damage,body.global_position.z)
			return 

func receive_damage(amount: int,source_position:float):
	if is_invincible:
		return 
	GameManager.update_health(-amount)
	health = GameManager.player_data["health"]
	#TODO invul visual flashing
	is_invincible = true
	apply_player_knockback(source_position)
	damage_timer.start(1.0) 
	await damage_timer.timeout
	is_invincible = false


func handle_attack():
	attack_area.monitoring = true
	input_disabled = true
	await get_tree().create_timer(0.4).timeout
	input_disabled = false
	attack_area.monitoring = false

func apply_player_knockback(source_position: float):
	input_disabled = true

	var knockback_dir = sign(global_position.z - source_position)
	if knockback_dir == 0:
		knockback_dir = 1

	velocity.z = knockback_dir * player_knockback_force
	velocity.y = player_knockback_force * 0.35 
	
	if animation_player.has_animation("hurt"):
		animation_player.play("hurt")

	await get_tree().create_timer(player_knockback_duration).timeout
	input_disabled = false


func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage") and body != self:
		body.take_damage(attack_damage,global_position.z)
