class_name BattleEvent
extends RefCounted

var kind: StringName
var data: Dictionary


func _init(event_kind: StringName = &"", event_data: Dictionary = {}) -> void:
	kind = event_kind
	data = event_data


func _to_string() -> String:
	return "%s %s" % [kind, data]
