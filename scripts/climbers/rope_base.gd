extends Node3D
class_name RopeBase

@export_category("Rope")
@export var segment_count: int = 12
@export var segment_length: float = 0.4
@export var segment_radius: float = 0.05
@export var segment_mass: float = 0.5

@export_category("Physics")
@export var push_force: float = 2
@export var linear_damp: float = 0.05
@export var angular_damp: float = 0.1
@export var gravity_scale: float = 1.0

var anchor: StaticBody3D = null
var segments: Array[RigidBody3D] = []
var joints: Array[PinJoint3D] = []

func _ready() -> void:
	if not Engine.is_editor_hint():
		generate_chain()

func generate_chain() -> void:
	clear_chain()

	if anchor == null:
		anchor = StaticBody3D.new()
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

		segment.add_child(mesh_instance)
		segment.add_child(collision)
		add_child(segment)

		# Position under previous
		if i == 0:
			segment.position = prev_body.position - Vector3(0, segment_length * 0.5, 0)
		else:
			segment.position = segments[i-1].position - Vector3(0, segment_length, 0)

		segments.append(segment)

		var joint := PinJoint3D.new()
		joint.exclude_nodes_from_collision = true
		joint.node_a = prev_body.get_path()
		joint.node_b = segment.get_path()
		joint.position = segment.position + Vector3(0, segment_length * 0.5, 0)
		add_child(joint)

		joints.append(joint)
		
		#var joint_marker := MeshInstance3D.new()
#
		#var sphere := SphereMesh.new()
		#sphere.radius = 0.1
		#sphere.height = 0.2
#
		#joint_marker.mesh = sphere
		#joint_marker.position = joint.position
#
		#add_child(joint_marker)
		
		prev_body = segment

func clear_chain() -> void:
	for j in joints:
		j.queue_free()
		
	for s in segments:
		s.queue_free()
		
	joints.clear()
	segments.clear()
