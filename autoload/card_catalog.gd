extends Node

signal catalog_reloaded

const CARD_ROOT := "res://cards/definitions"
const ENEMY_ROOT := "res://enemies/definitions"

var cards_by_id: Dictionary = {}
var enemies_by_id: Dictionary = {}
var validation_errors: PackedStringArray = PackedStringArray()


func _ready() -> void:
	reload_catalog()


func reload_catalog() -> void:
	cards_by_id.clear()
	enemies_by_id.clear()
	validation_errors.clear()
	for path in _resource_paths(CARD_ROOT):
		var resource := load(path)
		if resource is CardDefinition:
			_register_card(resource, path)
		else:
			validation_errors.append("%s is not a CardDefinition" % path)
	for path in _resource_paths(ENEMY_ROOT):
		var resource := load(path)
		if resource is EnemyDefinition:
			_register_enemy(resource, path)
		else:
			validation_errors.append("%s is not an EnemyDefinition" % path)
	if cards_by_id.is_empty():
		validation_errors.append("The card catalog is empty")
	if enemies_by_id.is_empty():
		validation_errors.append("The enemy catalog is empty")
	for message in validation_errors:
		push_error("Content validation: %s" % message)
	catalog_reloaded.emit()


func get_card(card_id: StringName) -> CardDefinition:
	return cards_by_id.get(card_id)


func get_enemy(enemy_id: StringName) -> EnemyDefinition:
	return enemies_by_id.get(enemy_id)


func get_all_cards() -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []
	for card in cards_by_id.values():
		cards.append(card)
	cards.sort_custom(func(a: CardDefinition, b: CardDefinition): return a.display_name < b.display_name)
	return cards


func get_all_enemies() -> Array[EnemyDefinition]:
	var enemies: Array[EnemyDefinition] = []
	for enemy in enemies_by_id.values():
		enemies.append(enemy)
	enemies.sort_custom(func(a: EnemyDefinition, b: EnemyDefinition): return a.display_name < b.display_name)
	return enemies


func has_card(card_id: StringName) -> bool:
	return cards_by_id.has(card_id)


func _register_card(card: CardDefinition, path: String) -> void:
	for message in card.validation_errors():
		validation_errors.append("%s: %s" % [path, message])
	if cards_by_id.has(card.id):
		validation_errors.append("Duplicate card ID '%s' in %s" % [card.id, path])
		return
	cards_by_id[card.id] = card


func _register_enemy(enemy: EnemyDefinition, path: String) -> void:
	for message in enemy.validation_errors():
		validation_errors.append("%s: %s" % [path, message])
	if enemies_by_id.has(enemy.id):
		validation_errors.append("Duplicate enemy ID '%s' in %s" % [enemy.id, path])
		return
	enemies_by_id[enemy.id] = enemy


func _resource_paths(root: String) -> PackedStringArray:
	var results := PackedStringArray()
	var directory := DirAccess.open(root)
	if directory == null:
		validation_errors.append("Cannot open content directory: %s" % root)
		return results
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var path := root.path_join(entry)
			if directory.current_is_dir():
				results.append_array(_resource_paths(path))
			elif entry.get_extension().to_lower() == "tres":
				results.append(path)
		entry = directory.get_next()
	directory.list_dir_end()
	results.sort()
	return results
