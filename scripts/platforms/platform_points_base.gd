extends Node3D
class_name PlatformPoints

@export var switch_id: StringName = &""
@export var global: bool = false
@export var points: Array[Vector3] = []
@export var radius: float = 2.5
@export var speed: float = 4.0
@export var platform_scene: PackedScene
@export var platform_count: int = 4
@export var is_moving: bool = false

var _path: Path3D
var _followers: Array[PathFollow3D] = []

signal started()
signal stopped()

func _ready() -> void:
	_build_path()
	_spawn_platforms()
	
	if global and switch_id != &"":
		is_moving = GameManager.switches.get(switch_id, false)
		GameManager.switch_toggled.connect(_on_switch_toggled)

func _physics_process(delta: float) -> void:
	if not is_moving:
		return
		
	for follower in _followers:
		follower.progress += speed * delta
		var platform: Node3D = follower.get_meta("platform")
		if platform is Rope:
			platform.anchor.global_transform = follower.global_transform
		else:
			platform.global_transform = follower.global_transform

func _build_path() -> void:
	_path = Path3D.new()
	add_child(_path)

	var curve := Curve3D.new()
	_path.curve = curve

	match points.size():
		0:
			return
		1:
			_add_circle_points(curve, points[0])
		_:
			_add_rounded_offset(curve, points, radius)
			
	curve.closed = true
	
func _add_circle_points(curve: Curve3D, center: Vector3) -> void:
	var segments := 32
	
	for i in segments:
		var angle := TAU * float(i) / segments
		var offset := Vector3(
			0.0,
			cos(angle) * radius,
			-sin(angle) * radius
		)
		curve.add_point(center + offset)

func _add_rounded_offset(curve: Curve3D, points: Array[Vector3], r: float) -> void:
	var n := points.size()
	
	if _signed_area(points) < 0.0:
		points.reverse()
		
	# Centroid to determine outward direction
	var centroid := Vector3.ZERO
	for p in points:
		centroid += p
	centroid /= float(n)

	# Compute outward edge normals
	var normals: Array[Vector3] = []
	for i in n:
		var a := points[i]
		var b := points[(i + 1) % n]
		var dir := (b - a)
		dir.x = 0.0
		if dir.length_squared() < 0.0001:
			normals.append(Vector3.ZERO)
			continue
		dir = dir.normalized()
		var normal := Vector3(0.0, -dir.z, dir.y)

		# Force outward
		var mid := (a + b) * 0.5
		if normal.dot(centroid - mid) > 0.0:
			normal = -normal
		normals.append(normal)

	var arc_segments := 16

	for i in n:
		var curr := points[i]
		var prev_n := normals[(i - 1 + n) % n]
		var next_n := normals[i]

		if prev_n.length_squared() < 0.0001 or next_n.length_squared() < 0.0001:
			continue

		# Offset points that define the start & end of the corner arc
		var arc_start := curr + prev_n * r
		var arc_end := curr + next_n * r

		# Straight segment that arrives at this corner 
		# from end of previous arc
		curve.add_point(arc_start)

		# Arc around the original vertex
		var start_angle := atan2(-prev_n.z, prev_n.y)
		var end_angle := atan2(-next_n.z, next_n.y)

		# Delta that turns the same way as the polygon (counter-clockwise)
		var delta := end_angle - start_angle
		
		# Bring delta into (-PI, PI]
		while delta <= -PI:
			delta += TAU
		while delta > PI:
			delta -= TAU

		# Start from one as arc_start already added
		for s in range(1, arc_segments):
			var t := float(s) / arc_segments
			var angle := start_angle + delta * t
			var offset := Vector3(0.0, cos(angle) * r, -sin(angle) * r)
			curve.add_point(curr + offset)

func _signed_area(points: Array[Vector3]) -> float:
	var area := 0.0
	var n := points.size()
	
	for i in n:
		var a := points[i]
		var b := points[(i + 1) % n]
		area += a.y * b.z - a.z * b.y
		
	return area

func _spawn_platforms() -> void:
	if not platform_scene or platform_count <= 0:
		return

	var length := _path.curve.get_baked_length()
	if length <= 0.0:
		return

	for i in platform_count:
		var follower := PathFollow3D.new()
		follower.loop = true
		follower.rotation_mode = PathFollow3D.ROTATION_NONE
		follower.cubic_interp = true
		follower.progress = length * float(i) / platform_count

		_path.add_child(follower)
		_followers.append(follower)

		var platform := platform_scene.instantiate()
		add_child(platform)
		follower.set_meta(&"platform", platform)

func start_moving() -> void:
	if not is_moving:
		is_moving = true
		started.emit()
	
func stop_moving() -> void:
	if is_moving:
		is_moving = false
		stopped.emit()

func _on_switch_toggled(switch_id_: StringName, is_on: bool) -> void:
	if switch_id_ != switch_id:
		return
		
	if is_on:
		start_moving()
	else:
		stop_moving()
