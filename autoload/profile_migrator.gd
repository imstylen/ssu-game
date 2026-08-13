class_name ProfileMigrator
extends RefCounted

const SCHEMA_VERSION := 2
const LEGACY_STARTER_IDS: Array[StringName] = [
	&"shield_bot", &"shield_bot",
	&"arc_bolt", &"arc_bolt",
	&"life_drain", &"life_drain",
]
const ACCESS_ALLIES_STARTER_IDS: Array[StringName] = [
	&"shield_bot", &"shield_bot",
	&"autistic_axolotl", &"autistic_axolotl",
	&"deaf_deer", &"deaf_deer",
	&"adhd_red_panda", &"adhd_red_panda",
	&"dyslexic_duckling", &"dyslexic_duckling",
	&"prosthetic_paw_puppy", &"prosthetic_paw_puppy",
	&"grounding_alpaca", &"grounding_alpaca",
	&"arc_bolt", &"arc_bolt",
	&"life_drain", &"life_drain",
	&"low_vision_lynx", &"low_vision_lynx",
]


static func migrate_profile_data(source: Dictionary) -> Dictionary:
	var migrated: Dictionary = source.duplicate(true)
	var changed := false
	var schema_version := int(migrated.get("schema_version", 1))
	if schema_version < SCHEMA_VERSION:
		var migrated_decks: Array = migrated.get("decks", [])
		for index in migrated_decks.size():
			var deck_data = migrated_decks[index]
			if not deck_data is Dictionary or str(deck_data.get("id", "")) != "starter":
				continue
			var card_ids := _string_name_array(deck_data.get("card_ids", []))
			if card_ids == LEGACY_STARTER_IDS:
				var upgraded: Dictionary = deck_data.duplicate(true)
				upgraded["name"] = "Access Allies"
				upgraded["card_ids"] = Array(ACCESS_ALLIES_STARTER_IDS, TYPE_STRING_NAME, &"", null)
				migrated_decks[index] = upgraded
				changed = true
		migrated["decks"] = migrated_decks
		migrated["schema_version"] = SCHEMA_VERSION
		changed = true
	return {"data": migrated, "changed": changed}


static func _string_name_array(values: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if values is Array:
		for value in values:
			result.append(StringName(str(value)))
	return result
