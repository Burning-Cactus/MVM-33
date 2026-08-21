extends Node3D
class_name Rope

@export_category("Rope")
@export var segment_count: int = 12
@export var segment_length: float = 0.4
@export var segment_radius: float = 0.05
@export var segment_mass: float = 2
@export var segment_interact_radius: float = 0.05

@export_category("Physics")
@export var linear_damp: float = 0.05
@export var angular_damp: float = 5.0
@export var gravity_scale: float = 1.0

var anchor: AnimatableBody3D = null
var segments: Array[RigidBody3D] = []
var joints: Array[PinJoint3D] = []

func _init() -> void:
	add_to_group(&"Ropes")

func _ready() -> void:
	if not Engine.is_editor_hint():
		generate_rope()

func generate_rope() -> void:
	clear_rope()

	if anchor == null:
		anchor = AnimatableBody3D.new()
		anchor.collision_layer = 0
		anchor.collision_mask = 0
		add_child(anchor)
	
	var prev_body: PhysicsBody3D = anchor as PhysicsBody3D
	
	for i in segment_count:
		var segment := RigidBody3D.new()
		segment.mass = segment_mass
		segment.linear_damp = linear_damp
		segment.angular_damp = angular_damp
		segment.gravity_scale = gravity_scale
		segment.axis_lock_linear_x = true
		segment.axis_lock_angular_y = true
		segment.axis_lock_angular_z = true
		segment.continuous_cd = true
		segment.can_sleep = false
		
		segment.collision_layer = 0
		segment.collision_mask = 0
		segment.set_collision_mask_value(6, true)
		segment.set_collision_layer_value(6, true)

		var mesh_instance := MeshInstance3D.new()
	
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = segment_radius
		cylinder.bottom_radius = segment_radius
		cylinder.height = segment_length
		mesh_instance.mesh = cylinder
		
		var shape := CylinderShape3D.new()
		shape.radius = segment_radius
		shape.height = segment_length * 0.95
		
		var collision := CollisionShape3D.new()
		collision.shape = shape
		
		var interact_area := Area3D.new()
		interact_area.collision_layer = 0
		interact_area.collision_mask = 0
		interact_area.set_collision_layer_value(5, true)
		
		var interact_shape := CylinderShape3D.new()
		interact_shape.radius = segment_radius + segment_interact_radius
		interact_shape.height = segment_length * 0.95
		
		var interact_collision := CollisionShape3D.new()
		interact_collision.shape = interact_shape
		interact_area.add_child(interact_collision)
		

		segment.add_child(mesh_instance)
		segment.add_child(collision)
		segment.add_child(interact_area)
		add_child(segment)

		# Position under previous
		if i == 0:
			segment.position = prev_body.position - Vector3(0, segment_length * 0.5, 0)
		else:
			segment.position = segments[i-1].position - Vector3(0, segment_length, 0)

		segments.append(segment)

		var joint := PinJoint3D.new()
		joint.exclude_nodes_from_collision = true
		add_child(joint)
		
		joint.position = segment.position + Vector3(0, segment_length * 0.5, 0)
		joint.node_a = prev_body.get_path()
		joint.node_b = segment.get_path()

		joints.append(joint)
		
		prev_body = segment

func clear_rope() -> void:
	for j in joints:
		j.queue_free()
		
	for s in segments:
		s.queue_free()
		
	joints.clear()
	segments.clear()
