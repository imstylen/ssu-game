class_name CardSchemaBuilder
extends RefCounted

const COMMUNITY_CARD_GROUP := "Community Card Fields"
const COMMUNITY_EFFECT_GROUP := "Community Effect Fields"
const POLICY_PATH := "res://cards/card_submission_policy.tres"
const STYLE_ROOT := "res://cards/styles"

var errors: PackedStringArray = PackedStringArray()


func build_schema(catalog, source_commit: String = "") -> Dictionary:
	errors.clear()
	var policy := load(POLICY_PATH) as CardSubmissionPolicy
	if policy == null:
		errors.append("Card submission policy could not be loaded: %s" % POLICY_PATH)
		policy = CardSubmissionPolicy.new()
	var fields := _fields_for(CardDefinition.new(), COMMUNITY_CARD_GROUP, policy)
	var effects := _effect_schemas(catalog, policy)
	var styles := _style_schemas()
	var card_types: Array = []
	for field in fields:
		if field.id == "card_type":
			card_types = field.get("options", [])
			break
	var versioned_shape := {
		"card_types": card_types,
		"fields": fields,
		"effects": effects,
		"styles": styles,
	}
	var canonical := JSON.stringify(versioned_shape, "", true)
	var existing_card_ids: Array[String] = []
	for card in catalog.get_all_cards():
		existing_card_ids.append(String(card.id))
	existing_card_ids.sort()
	return {
		"schema_version": canonical.sha256_text(),
		"source_commit": source_commit,
		"card_types": card_types,
		"fields": fields,
		"effects": effects,
		"styles": styles,
		"existing_card_ids": existing_card_ids,
	}


func _effect_schemas(catalog, policy: CardSubmissionPolicy) -> Array[Dictionary]:
	var schemas: Array[Dictionary] = []
	for effect in catalog.get_all_effects():
		if not effect.available_for_submission:
			continue
		var behavior: CardBehavior = effect.create_behavior()
		if behavior == null:
			errors.append("Effect '%s' cannot create its behavior." % effect.id)
			continue
		schemas.append({
			"id": String(effect.id),
			"display_name": effect.display_name,
			"description": effect.description,
			"allowed_card_types": Array(effect.allowed_card_types),
			"fields": _fields_for(behavior, COMMUNITY_EFFECT_GROUP, policy),
		})
	schemas.sort_custom(func(a: Dictionary, b: Dictionary): return a.id < b.id)
	return schemas


func _style_schemas() -> Array[Dictionary]:
	var schemas: Array[Dictionary] = []
	for path in _resource_paths(STYLE_ROOT):
		var style := load(path)
		if not style is CardVisualStyle:
			errors.append("Submission style is not a CardVisualStyle: %s" % path)
			continue
		var style_id := path.get_file().get_basename()
		schemas.append({
			"id": style_id,
			"display_name": style_id.capitalize(),
			"resource_path": path,
		})
	schemas.sort_custom(func(a: Dictionary, b: Dictionary): return a.id < b.id)
	return schemas


func _fields_for(resource: Resource, group_name: String, policy: CardSubmissionPolicy) -> Array[Dictionary]:
	var fields: Array[Dictionary] = []
	var in_group := false
	for property in resource.get_property_list():
		var usage := int(property.get("usage", 0))
		if usage & PROPERTY_USAGE_GROUP:
			in_group = str(property.get("name", "")) == group_name
			continue
		if not in_group or not usage & PROPERTY_USAGE_EDITOR:
			continue
		var field := _field_schema(resource, property, policy)
		if field.is_empty():
			errors.append("Unsupported submission field '%s' on %s." % [
				property.get("name", "unknown"),
				resource.get_class(),
			])
			continue
		fields.append(field)
	return fields


func _field_schema(resource: Resource, property: Dictionary, policy: CardSubmissionPolicy) -> Dictionary:
	var field_id := StringName(property.name)
	var override := policy.override_for(field_id)
	var field := {
		"id": String(field_id),
		"label": str(override.get("label", String(field_id).capitalize())),
		"description": str(override.get("description", "")),
		"required": bool(override.get("required", true)),
		"default": resource.get(field_id),
		"submitter_editable": true,
	}
	if override.has("visible_when"):
		field["visible_when"] = override.visible_when
	var type := int(property.get("type", TYPE_NIL))
	var hint := int(property.get("hint", PROPERTY_HINT_NONE))
	var hint_string := str(property.get("hint_string", ""))
	match type:
		TYPE_STRING, TYPE_STRING_NAME:
			field["type"] = "string"
			field["component"] = str(override.get(
				"component",
				"paragraph" if hint == PROPERTY_HINT_MULTILINE_TEXT else "text",
			))
			field["max_length"] = int(override.get("max_length", 4000))
		TYPE_INT:
			if hint == PROPERTY_HINT_ENUM:
				field["type"] = "enum"
				field["component"] = str(override.get("component", "select"))
				field["options"] = _enum_options(hint_string, override.get("option_labels", {}))
			elif hint == PROPERTY_HINT_RANGE:
				var range_parts := hint_string.split(",")
				if range_parts.size() < 2:
					return {}
				field["type"] = "integer"
				field["component"] = str(override.get("component", "text"))
				field["minimum"] = int(float(range_parts[0]))
				field["maximum"] = int(float(range_parts[1]))
				field["step"] = int(float(range_parts[2])) if range_parts.size() > 2 else 1
			else:
				field["type"] = "integer"
				field["component"] = str(override.get("component", "text"))
		TYPE_BOOL:
			field["type"] = "boolean"
			field["component"] = str(override.get("component", "select"))
			field["options"] = [
				{"id": "true", "label": "Yes", "value": true},
				{"id": "false", "label": "No", "value": false},
			]
		_:
			return {}
	return field


func _enum_options(hint_string: String, label_overrides: Dictionary = {}) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var next_value := 0
	for raw_option in hint_string.split(",", false):
		var parts := raw_option.split(":", true, 1)
		var value := int(parts[1]) if parts.size() > 1 else next_value
		var option_id := parts[0].strip_edges()
		options.append({
			"id": option_id.to_lower(),
			"label": str(label_overrides.get(str(value), option_id.capitalize())),
			"value": value,
		})
		next_value = value + 1
	return options


func _resource_paths(root: String) -> PackedStringArray:
	var results := PackedStringArray()
	var directory := DirAccess.open(root)
	if directory == null:
		errors.append("Could not open submission resource folder: %s" % root)
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
