class_name CardInstance
extends RefCounted

var instance_id: int
var definition: CardDefinition
var current_health: int
var current_attack: int
var has_attacked_this_turn: bool = false
var turn_played: int = -1


func _init(card_definition: CardDefinition = null, new_instance_id: int = 0) -> void:
	definition = card_definition
	instance_id = new_instance_id
	if definition != null:
		current_health = definition.health
		current_attack = definition.attack


func snapshot() -> Dictionary:
	return {
		"instance_id": instance_id,
		"card_id": String(definition.id),
		"health": current_health,
		"attack": current_attack,
		"has_attacked": has_attacked_this_turn,
		"turn_played": turn_played,
	}
