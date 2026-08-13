class_name EnemyInstance
extends RefCounted

var definition: EnemyDefinition
var current_health: int


func _init(enemy_definition: EnemyDefinition = null) -> void:
	definition = enemy_definition
	if definition != null:
		current_health = definition.maximum_health
