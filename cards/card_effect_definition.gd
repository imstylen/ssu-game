class_name CardEffectDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var behavior_script: Script
@export var allowed_card_types: PackedInt32Array = PackedInt32Array([
	CardDefinition.CardType.ACTION,
])
@export var available_for_submission: bool = true


func create_behavior() -> CardBehavior:
	if behavior_script == null or not behavior_script.can_instantiate():
		return null
	var behavior = behavior_script.new()
	return behavior as CardBehavior


func supports_card_type(card_type: CardDefinition.CardType) -> bool:
	return card_type in allowed_card_types


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("This card effect needs an internal ID.")
	if display_name.strip_edges().is_empty():
		errors.append("Card effect '%s' needs a display name." % id)
	if behavior_script == null:
		errors.append("Card effect '%s' needs a behavior script." % id)
	elif create_behavior() == null:
		errors.append("Card effect '%s' must create a CardBehavior." % id)
	if allowed_card_types.is_empty():
		errors.append("Card effect '%s' needs at least one allowed card type." % id)
	for card_type in allowed_card_types:
		if card_type not in [CardDefinition.CardType.UNIT, CardDefinition.CardType.ACTION]:
			errors.append("Card effect '%s' has an unknown card type: %s." % [id, card_type])
	return errors
