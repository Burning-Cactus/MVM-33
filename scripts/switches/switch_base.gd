extends StaticBody3D
class_name Switch

@export var switch_id: StringName = &""
@export var is_on: bool = false
@export var can_toggle_on: bool = true
@export var can_toggle_off: bool = true
@export var global: bool = false

signal switch_toggled(switch_id: StringName, is_on: bool)

func _ready() -> void:
	if global:
		GameManager.toggle_switch(switch_id, is_on)

func toggle_on() -> void:
	if can_toggle_on and not is_on:
		is_on = true
		switch_toggled.emit(switch_id, true)
		if global:
			GameManager.toggle_switch(switch_id, is_on)
	
func toggle_off() -> void:
	if can_toggle_off and is_on:
		is_on = false
		switch_toggled.emit(switch_id, false)
		if global:
			GameManager.toggle_switch(switch_id, is_on)
