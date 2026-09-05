extends Resource
class_name ModelAnimation

@export var anim_name: StringName = &""
@export var model_offset: Vector3 = Vector3.ZERO

func _init(anim_name_: StringName = &"") -> void:
	anim_name = anim_name_
