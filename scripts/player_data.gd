class_name PlayerData
extends Resource

var max_health = 100
var health = max_health
var unlocked_abilities = []

func _init(p_max_health: int, p_health: int) -> void:
	max_health = p_max_health
	health = p_health
