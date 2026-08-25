extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments := _arguments(OS.get_cmdline_user_args())
	var output_path := str(arguments.get("output", ""))
	if output_path.is_empty():
		_fail("Usage: export_schema.gd -- --output <schema.json> [--source-commit <sha>]")
		return
	var catalog = load("res://autoload/card_catalog.gd").new()
	catalog.reload_catalog()
	if not catalog.validation_errors.is_empty():
		_fail("Card catalog is invalid:\n%s" % "\n".join(catalog.validation_errors))
		catalog.free()
		return
	var builder := CardSchemaBuilder.new()
	var schema := builder.build_schema(catalog, str(arguments.get("source-commit", "")))
	catalog.free()
	if not builder.errors.is_empty():
		_fail("Card submission schema is invalid:\n%s" % "\n".join(builder.errors))
		return
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		_fail("Could not write schema to %s (error %s)." % [output_path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(schema, "\t", true) + "\n")
	file.close()
	print("CARD_SCHEMA_OK: %s" % schema.schema_version)
	quit(0)


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
