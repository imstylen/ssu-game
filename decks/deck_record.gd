class_name DeckRecord
extends RefCounted

var id: String
var name: String
var card_ids: Array[StringName] = []


func _init(deck_id: String = "", deck_name: String = "", cards: Array = []) -> void:
	id = deck_id
	name = deck_name
	for card_id in cards:
		card_ids.append(StringName(card_id))


func to_dictionary() -> Dictionary:
	var serialized_cards: Array[String] = []
	for card_id in card_ids:
		serialized_cards.append(String(card_id))
	return {
		"id": id,
		"name": name,
		"card_ids": serialized_cards,
	}


static func from_dictionary(data: Dictionary) -> DeckRecord:
	return DeckRecord.new(
		str(data.get("id", "")),
		str(data.get("name", "Untitled Deck")),
		data.get("card_ids", [])
	)


func duplicate_record() -> DeckRecord:
	return DeckRecord.new(id, name, card_ids)
