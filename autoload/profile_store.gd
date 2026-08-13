extends Node

signal profile_changed
signal save_failed(message: String)

const PROFILE_PATH := "user://profile.json"
const SCHEMA_VERSION := ProfileMigrator.SCHEMA_VERSION

var selected_deck_id: String = ""
var decks: Array[DeckRecord] = []
var deck_rules: DeckRules


func _ready() -> void:
	var battle_rules: BattleRules = load("res://battle/rules/battle_rules.tres")
	deck_rules = DeckRules.new(battle_rules)
	load_profile()


func load_profile() -> void:
	decks.clear()
	if not FileAccess.file_exists(PROFILE_PATH):
		_create_default_profile()
		save_profile()
		return
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		_create_default_profile()
		save_failed.emit("We could not open your cozy corner, so a fresh one is ready.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_create_default_profile()
		save_failed.emit("That profile was a little tangled, so a fresh cozy corner is ready.")
		return
	var migrated := ProfileMigrator.migrate_profile_data(parsed)
	parsed = migrated.data
	selected_deck_id = str(parsed.get("selected_deck_id", ""))
	for deck_data in parsed.get("decks", []):
		if deck_data is Dictionary:
			var deck := DeckRecord.from_dictionary(deck_data)
			if not deck.id.is_empty():
				decks.append(deck)
	if decks.is_empty():
		_create_default_profile()
	elif get_deck(selected_deck_id) == null:
		selected_deck_id = decks[0].id
	profile_changed.emit()
	if migrated.changed:
		save_profile()


func save_profile() -> bool:
	var serialized_decks: Array[Dictionary] = []
	for deck in decks:
		serialized_decks.append(deck.to_dictionary())
	var data := {
		"schema_version": SCHEMA_VERSION,
		"selected_deck_id": selected_deck_id,
		"decks": serialized_decks,
	}
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		var message := "We could not save your cozy corner (error %s)." % FileAccess.get_open_error()
		save_failed.emit(message)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


func get_decks() -> Array[DeckRecord]:
	return decks


func get_deck(deck_id: String) -> DeckRecord:
	for deck in decks:
		if deck.id == deck_id:
			return deck
	return null


func get_selected_deck() -> DeckRecord:
	return get_deck(selected_deck_id)


func get_selected_deck_definitions() -> Array[CardDefinition]:
	var definitions: Array[CardDefinition] = []
	var deck := get_selected_deck()
	if deck == null:
		return definitions
	for card_id in deck.card_ids:
		var definition := CardCatalog.get_card(card_id)
		if definition != null:
			definitions.append(definition)
	return definitions


func selected_deck_errors() -> PackedStringArray:
	var deck := get_selected_deck()
	if deck == null:
		return PackedStringArray(["Choose an ally deck before starting an adventure."])
	return deck_rules.validate(deck.card_ids, CardCatalog)


func select_deck(deck_id: String) -> bool:
	if get_deck(deck_id) == null:
		return false
	selected_deck_id = deck_id
	save_profile()
	profile_changed.emit()
	return true


func create_deck(deck_name: String = "New Ally Deck") -> DeckRecord:
	var unique_id := "deck_%d" % Time.get_ticks_usec()
	var deck := DeckRecord.new(unique_id, _unique_name(deck_name), [])
	decks.append(deck)
	selected_deck_id = deck.id
	save_profile()
	profile_changed.emit()
	return deck


func update_deck(deck_id: String, deck_name: String, card_ids: Array[StringName]) -> bool:
	var deck := get_deck(deck_id)
	if deck == null:
		return false
	deck.name = deck_name.strip_edges()
	if deck.name.is_empty():
		deck.name = "Untitled Ally Deck"
	deck.card_ids.assign(card_ids)
	selected_deck_id = deck.id
	var saved := save_profile()
	profile_changed.emit()
	return saved


func delete_deck(deck_id: String) -> bool:
	if decks.size() <= 1:
		return false
	var deck := get_deck(deck_id)
	if deck == null:
		return false
	decks.erase(deck)
	if selected_deck_id == deck_id:
		selected_deck_id = decks[0].id
	save_profile()
	profile_changed.emit()
	return true


func _create_default_profile() -> void:
	var starter_cards: Array[StringName] = []
	starter_cards.assign(ProfileMigrator.ACCESS_ALLIES_STARTER_IDS)
	var starter := DeckRecord.new("starter", "Access Allies", starter_cards)
	decks.assign([starter])
	selected_deck_id = starter.id
	profile_changed.emit()


func _unique_name(base_name: String) -> String:
	var clean_name := base_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "New Ally Deck"
	var candidate := clean_name
	var suffix := 2
	var names: Array[String] = []
	for deck in decks:
		names.append(deck.name)
	while candidate in names:
		candidate = "%s %d" % [clean_name, suffix]
		suffix += 1
	return candidate

