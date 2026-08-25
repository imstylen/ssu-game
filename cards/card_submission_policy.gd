class_name CardSubmissionPolicy
extends Resource

@export var field_overrides: Dictionary = {}


func override_for(field_id: StringName) -> Dictionary:
	var value = field_overrides.get(String(field_id), {})
	return value if value is Dictionary else {}
