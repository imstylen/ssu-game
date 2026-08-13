class_name EnemyDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var artwork: Texture2D
@export_range(1, 1000) var maximum_health: int = 20
@export var behavior: EnemyBehavior


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("This ableism monster needs an internal ID.")
	if display_name.strip_edges().is_empty():
		errors.append("Ableism monster '%s' needs a display name." % id)
	if behavior == null:
		errors.append("Ableism monster '%s' needs a barrier pattern." % id)
	return errors
