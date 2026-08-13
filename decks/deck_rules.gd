class_name DeckRules
extends RefCounted

var minimum_deck_size: int = 1
var maximum_deck_size: int = 20
var duplicate_card_limit: int = 2
var decks_with_missing_cards_remain_editable: bool = true


func _init(battle_rules: BattleRules = null) -> void:
	if battle_rules != null:
		maximum_deck_size = battle_rules.maximum_deck_size
		duplicate_card_limit = battle_rules.duplicate_card_limit


func validate(card_ids: Array[StringName], catalog = null) -> PackedStringArray:
	var errors := PackedStringArray()
	if card_ids.size() < minimum_deck_size:
		errors.append("Add at least %d ally card to this deck." % minimum_deck_size)
	if card_ids.size() > maximum_deck_size:
		errors.append("This deck can hold at most %d cards." % maximum_deck_size)
	var counts: Dictionary = {}
	for card_id in card_ids:
		counts[card_id] = int(counts.get(card_id, 0)) + 1
		if catalog != null and not catalog.has_card(card_id):
			errors.append("We could not find ally card: %s" % card_id)
	for card_id in counts:
		if counts[card_id] > duplicate_card_limit:
			errors.append("Keep up to %d copies of %s in one deck." % [
			duplicate_card_limit,
			card_id,
		])
	return errors


func can_add(card_ids: Array[StringName], card_id: StringName) -> bool:
	if card_ids.size() >= maximum_deck_size:
		return false
	return card_ids.count(card_id) < duplicate_card_limit
