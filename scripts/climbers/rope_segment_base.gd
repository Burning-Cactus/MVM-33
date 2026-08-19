extends RigidBody3D
class_name RopeSegment

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# Kill any X velocity
	var vel = state.linear_velocity
	vel.x = 0.0
	state.linear_velocity = vel

	# Snap (or spring) position back to X = 0
	var pos = state.transform.origin
	pos.x = 0.0
	state.transform.origin = pos

	# Zero angular velocity around the axes that leave the plane
	var ang = state.angular_velocity
	ang.y = 0.0 
	ang.z = 0.0
	state.angular_velocity = ang
