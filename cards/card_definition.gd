class_name CardDefinition
extends Resource

enum CardType {
	UNIT,
	ACTION,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var artwork: Texture2D
@export var card_type: CardType = CardType.UNIT
@export_range(0, 100) var attack: int = 0
@export_range(1, 100) var health: int = 1
@export_range(0, 20) var cost: int = 0
@export var behavior: CardBehavior
@export var visual_style: CardVisualStyle


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("Card ID cannot be empty")
	if display_name.strip_edges().is_empty():
		errors.append("Card '%s' needs a display name" % id)
	if card_type == CardType.ACTION and attack != 0:
		errors.append("Action card '%s' must have zero attack" % id)
	return errors
