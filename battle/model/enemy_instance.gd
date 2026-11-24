class_name EnemyInstance
extends RefCounted

var definition: EnemyDefinition
var current_health: int
## Calm: reduces the damage of the enemy's next damaging action.
var calm: int = 0
## Exposed: adds to the next instance of damage the enemy takes.
var exposed: int = 0


func _init(enemy_definition: EnemyDefinition = null) -> void:
	definition = enemy_definition
	if definition != null:
		current_health = definition.maximum_health
