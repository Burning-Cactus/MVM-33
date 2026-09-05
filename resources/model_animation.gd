extends Resource
class_name ModelAnimation

@export var anim_name: StringName = &""
@export var model_offset: Vector3 = Vector3.ZERO
@export var start_time: float = -1.0
@export var end_time: float = -1.0

func _init(anim_name_: StringName = &"") -> void:
	anim_name = anim_name_
