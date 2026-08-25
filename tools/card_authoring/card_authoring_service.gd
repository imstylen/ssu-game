class_name CardAuthoringService
extends RefCounted

const DEFAULT_OUTPUT_ROOT := "res://cards/definitions"

var created_card: CardDefinition


func create_card(
	payload: Dictionary,
	catalog,
	schema: Dictionary,
	output_root: String = DEFAULT_OUTPUT_ROOT,
) -> Dictionary:
	created_card = null
	var errors := PackedStringArray()
	if str(payload.get("schema_version", "")) != str(schema.get("schema_version", "")):
		errors.append("The card form has changed. Refresh the schema and resubmit this card.")
		return _failure(errors)
	var card_data = payload.get("card", {})
	if not card_data is Dictionary:
		errors.append("Card fields must be a JSON object.")
		return _failure(errors)
	var card := CardDefinition.new()
	_apply_fields(card, card_data, schema.get("fields", []), errors)
	var card_id := _available_id(card.display_name, catalog, output_root)
	if card_id.is_empty():
		errors.append("The card name must contain at least one English letter or number.")
	else:
		card.id = StringName(card_id)
	var style_id := str(payload.get("style_id", ""))
	var style_path := _resource_path_for(schema.get("styles", []), style_id)
	if style_path.is_empty():
		errors.append("Choose a visual style from the current card schema.")
	else:
		card.visual_style = load(style_path) as CardVisualStyle
		if card.visual_style == null:
			errors.append("The selected visual style could not be loaded: %s." % style_id)
	_apply_effect(card, payload.get("effect", {}), catalog, schema, errors)
	var artwork_source := str(payload.get("artwork_path", ""))
	var image := _validated_artwork(artwork_source, errors)
	for message in card.validation_errors():
		errors.append(message)
	if not errors.is_empty():
		return _failure(errors)
	var card_directory := output_root.path_join(card_id)
	var card_path := card_directory.path_join("%s.tres" % card_id)
	var artwork_path := card_directory.path_join("%s.png" % card_id)
	if FileAccess.file_exists(card_path) or FileAccess.file_exists(artwork_path):
		errors.append("Card output already exists for '%s'." % card_id)
		return _failure(errors)
	var absolute_directory := ProjectSettings.globalize_path(card_directory)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		errors.append("Could not create the card output directory (error %s)." % directory_error)
		return _failure(errors)
	var copy_error := DirAccess.copy_absolute(
		ProjectSettings.globalize_path(artwork_source),
		ProjectSettings.globalize_path(artwork_path),
	)
	if copy_error != OK:
		errors.append("Could not copy the normalized artwork (error %s)." % copy_error)
		_cleanup_outputs(card_directory, card_path, artwork_path)
		return _failure(errors)
	var texture := ImageTexture.create_from_image(image)
	texture.take_over_path(artwork_path)
	card.artwork = texture
	var save_error := ResourceSaver.save(card, card_path)
	if save_error != OK:
		errors.append("Could not save the card resource (error %s)." % save_error)
		_cleanup_outputs(card_directory, card_path, artwork_path)
		return _failure(errors)
	created_card = card
	var generated_files: Array[String] = [card_path, artwork_path]
	var import_path := "%s.import" % artwork_path
	if FileAccess.file_exists(import_path):
		generated_files.append(import_path)
	return {
		"ok": true,
		"schema_version": schema.schema_version,
		"card_id": card_id,
		"card_resource_path": card_path,
		"artwork_path": artwork_path,
		"expected_import_path": import_path,
		"generated_files": generated_files,
		"validation_errors": [],
	}


func slugify(display_name: String) -> String:
	var slug := ""
	var pending_separator := false
	for character in display_name.to_lower():
		var code := character.unicode_at(0)
		var is_ascii_letter := code >= 97 and code <= 122
		var is_digit := code >= 48 and code <= 57
		if is_ascii_letter or is_digit:
			if pending_separator and not slug.is_empty():
				slug += "_"
			slug += character
			pending_separator = false
		elif not slug.is_empty():
			pending_separator = true
	return slug


func _apply_effect(card: CardDefinition, value: Variant, catalog, schema: Dictionary, errors: PackedStringArray) -> void:
	var effect_data: Dictionary = value if value is Dictionary else {}
	var effect_id := StringName(str(effect_data.get("id", "")))
	if effect_id.is_empty():
		if card.card_type == CardDefinition.CardType.ACTION:
			errors.append("One-shot cards need an effect from the current card schema.")
		return
	var effect: CardEffectDefinition = catalog.get_effect(effect_id)
	if effect == null or not effect.available_for_submission:
		errors.append("The selected card effect is not available: %s." % effect_id)
		return
	if not effect.supports_card_type(card.card_type):
		errors.append("Effect '%s' does not support this card type." % effect_id)
		return
	var effect_schema := _entry_for(schema.get("effects", []), String(effect_id))
	if effect_schema.is_empty():
		errors.append("The selected card effect is missing from the current schema: %s." % effect_id)
		return
	var behavior := effect.create_behavior()
	if behavior == null:
		errors.append("The selected card effect could not create its behavior: %s." % effect_id)
		return
	var parameters = effect_data.get("parameters", {})
	if not parameters is Dictionary:
		errors.append("Effect parameters must be a JSON object.")
		return
	_apply_fields(behavior, parameters, effect_schema.get("fields", []), errors)
	card.behavior = behavior


func _apply_fields(resource: Resource, values: Dictionary, fields: Array, errors: PackedStringArray) -> void:
	for field in fields:
		if not field is Dictionary:
			continue
		var field_id := StringName(str(field.get("id", "")))
		var value = values.get(String(field_id), field.get("default"))
		_validate_field(field, value, errors)
		if errors.is_empty() or _field_value_is_valid(field, value):
			resource.set(field_id, _coerce_field_value(field, value))


func _validate_field(field: Dictionary, value: Variant, errors: PackedStringArray) -> void:
	if not _field_value_is_valid(field, value):
		errors.append("Invalid value for %s." % field.get("label", field.get("id", "field")))


func _field_value_is_valid(field: Dictionary, value: Variant) -> bool:
	if value == null:
		return not bool(field.get("required", true))
	match str(field.get("type", "")):
		"string":
			if not value is String and not value is StringName:
				return false
			var text := str(value)
			if bool(field.get("required", true)) and text.strip_edges().is_empty():
				return false
			return text.length() <= int(field.get("max_length", 4000))
		"integer":
			if not value is int and not value is float:
				return false
			var integer := int(value)
			if float(integer) != float(value):
				return false
			return integer >= int(field.get("minimum", -2147483648)) \
				and integer <= int(field.get("maximum", 2147483647))
		"enum":
			for option in field.get("options", []):
				if option is Dictionary and option.get("value") == value:
					return true
			return false
		"boolean":
			return value is bool
	return false


func _coerce_field_value(field: Dictionary, value: Variant) -> Variant:
	if str(field.get("type", "")) == "integer" or str(field.get("type", "")) == "enum":
		return int(value)
	if str(field.get("type", "")) == "string":
		return str(value)
	return value


func _validated_artwork(path: String, errors: PackedStringArray) -> Image:
	if path.is_empty() or path.get_extension().to_lower() != "png":
		errors.append("Artwork must be a normalized PNG file.")
		return null
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		errors.append("Artwork file does not exist: %s." % path)
		return null
	var image := Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		errors.append("Artwork is not a readable PNG image.")
		return null
	if image.get_width() != 1024 or image.get_height() != 1024:
		errors.append("Artwork must be exactly 1024x1024 pixels.")
		return null
	return image


func _available_id(display_name: String, catalog, output_root: String) -> String:
	var base := slugify(display_name)
	if base.is_empty():
		return ""
	var occupied := {}
	for card in catalog.get_all_cards():
		occupied[String(card.id).to_lower()] = true
	var candidate := base
	var suffix := 2
	while occupied.has(candidate.to_lower()) or DirAccess.dir_exists_absolute(
		ProjectSettings.globalize_path(output_root.path_join(candidate)),
	):
		candidate = "%s_%d" % [base, suffix]
		suffix += 1
	return candidate


func _resource_path_for(entries: Array, entry_id: String) -> String:
	var entry := _entry_for(entries, entry_id)
	return str(entry.get("resource_path", ""))


func _entry_for(entries: Array, entry_id: String) -> Dictionary:
	for entry in entries:
		if entry is Dictionary and str(entry.get("id", "")) == entry_id:
			return entry
	return {}


func _cleanup_outputs(directory: String, card_path: String, artwork_path: String) -> void:
	for path in [card_path, artwork_path, "%s.import" % artwork_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))


func _failure(errors: PackedStringArray) -> Dictionary:
	return {
		"ok": false,
		"validation_errors": Array(errors),
		"generated_files": [],
	}
