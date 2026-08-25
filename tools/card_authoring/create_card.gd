extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments := _arguments(OS.get_cmdline_user_args())
	var input_path := str(arguments.get("input", ""))
	var output_path := str(arguments.get("output", ""))
	if input_path.is_empty() or output_path.is_empty():
		_fail("Usage: create_card.gd -- --input <submission.json> --output <manifest.json>")
		return
	var payload = JSON.parse_string(FileAccess.get_file_as_string(input_path))
	if not payload is Dictionary:
		_fail("Card submission must be a JSON object.")
		return
	var catalog = load("res://autoload/card_catalog.gd").new()
	catalog.reload_catalog()
	if not catalog.validation_errors.is_empty():
		_fail("Card catalog is invalid:\n%s" % "\n".join(catalog.validation_errors))
		catalog.free()
		return
	var builder := CardSchemaBuilder.new()
	var schema := builder.build_schema(catalog, str(arguments.get("source-commit", "")))
	if not builder.errors.is_empty():
		_fail("Card submission schema is invalid:\n%s" % "\n".join(builder.errors))
		catalog.free()
		return
	var service := CardAuthoringService.new()
	var manifest := service.create_card(
		payload,
		catalog,
		schema,
		str(arguments.get("output-root", CardAuthoringService.DEFAULT_OUTPUT_ROOT)),
	)
	catalog.free()
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		_fail("Could not write manifest to %s (error %s)." % [output_path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(manifest, "\t", true) + "\n")
	file.close()
	if manifest.ok:
		print("CARD_CREATE_OK: %s" % manifest.card_id)
		quit(0)
	else:
		printerr("CARD_CREATE_FAILED:\n%s" % "\n".join(manifest.validation_errors))
		quit(1)


func _arguments(values: PackedStringArray) -> Dictionary:
	var parsed := {}
	var index := 0
	while index < values.size():
		var key := values[index]
		if key.begins_with("--") and index + 1 < values.size():
			parsed[key.trim_prefix("--")] = values[index + 1]
			index += 2
		else:
			index += 1
	return parsed


func _fail(message: String) -> void:
	printerr(message)
	quit(1)
