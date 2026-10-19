extends Node

signal profile_changed
signal save_failed(message: String)

const PROFILE_PATH := "user://profile.json"
const SCHEMA_VERSION := ProfileMigrator.SCHEMA_VERSION

var selected_deck_id: String = ""
var decks: Array[DeckRecord] = []
var deck_rules: DeckRules
var campaign: CampaignProgress
var campaign_error: String = ""
var last_save_error: String = ""
var profile_path: String = PROFILE_PATH
# Injectable disk boundary for persistence tests. Production uses atomic replacement.
var profile_writer: Callable
var _campaign_data: Variant = null


func _ready() -> void:
	var battle_rules: BattleRules = load("res://battle/rules/battle_rules.tres")
	deck_rules = DeckRules.new(battle_rules)
	load_profile()


func load_profile() -> void:
	decks.clear()
	campaign = null
	campaign_error = ""
	_campaign_data = null
	if not FileAccess.file_exists(profile_path):
		_create_default_profile()
		save_profile()
		return
	var file := FileAccess.open(profile_path, FileAccess.READ)
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
	_campaign_data = parsed.get("campaign")
	if _campaign_data != null:
		campaign_error = CampaignProgress.validation_error(_campaign_data)
		campaign = CampaignProgress.from_dictionary(_campaign_data)
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
		"campaign": _campaign_data,
	}
	last_save_error = ""
	var error: Error = profile_writer.call(data) if profile_writer.is_valid() else _write_profile(data)
	if error != OK:
		last_save_error = "We could not save your cozy corner (error %s). Your last saved campaign is unchanged. Please try again." % error
		save_failed.emit(last_save_error)
		return false
	return true


func _write_profile(data: Dictionary) -> Error:
	# Never truncate the previous good save before the replacement is fully written.
	var temporary := profile_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(profile_path))


func initialize_campaign() -> bool:
	if not campaign_error.is_empty():
		return false
	if campaign != null:
		return true
	return _save_campaign(CampaignProgress.new())


func reset_campaign() -> bool:
	return _save_campaign(CampaignProgress.new())


func commit_campaign(node_id: String) -> bool:
	if campaign == null or not campaign_error.is_empty() or not selected_deck_errors().is_empty():
		return false
	var candidate := CampaignProgress.from_dictionary(campaign.to_dictionary())
	if not candidate.commit(node_id):
		return false
	return _save_campaign(candidate)


func complete_campaign_encounter(node_id: String) -> bool:
	if campaign == null or not campaign_error.is_empty():
		return false
	if not campaign.completed.is_empty() and campaign.completed.back() == node_id:
		return true
	var candidate := CampaignProgress.from_dictionary(campaign.to_dictionary())
	if not candidate.complete(node_id):
		return false
	return _save_campaign(candidate)


func _save_campaign(candidate: CampaignProgress) -> bool:
	var previous: Variant = _campaign_data
	_campaign_data = candidate.to_dictionary()
	if not save_profile():
		_campaign_data = previous
		return false
	campaign = candidate
	campaign_error = ""
	profile_changed.emit()
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

