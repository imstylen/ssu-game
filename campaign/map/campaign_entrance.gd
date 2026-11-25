@tool
class_name CampaignEntrance
extends Control

## Where every campaign begins. Its Next Encounters are the starting choices.
## Exactly one per CampaignMapCanvas.

@export var next_encounters: Array[CampaignEncounter] = []:
	set(value):
		next_encounters = value
		_changed()
@export var art: Texture2D:
	set(value):
		art = value
		_changed()
@export var label_text := "ZOO ENTRANCE":
	set(value):
		label_text = value
		_changed()


func _init() -> void:
	size = Vector2(375, 375)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func center() -> Vector2:
	return position + size * 0.5


func _changed() -> void:
	queue_redraw()
	if Engine.is_editor_hint() and is_inside_tree():
		var parent := get_parent()
		if parent is Control:
			parent.update_configuration_warnings()
			parent.queue_redraw()


func _draw() -> void:
	var plate_height := 40.0
	if art != null:
		draw_texture_rect(art, Rect2(Vector2.ZERO, size - Vector2(0, plate_height * 0.5)), false)
	var font: Font = AppTheme.FREDOKA
	var plate := Rect2(Vector2(size.x * 0.15, size.y - plate_height), Vector2(size.x * 0.7, plate_height))
	draw_style_box(AppTheme.style_box(AppTheme.SURFACE, AppTheme.INK, 14, 3, 0), plate)
	var baseline := plate.position.y + (plate_height + font.get_ascent(20) - font.get_descent(20)) * 0.5
	draw_string(font, Vector2(plate.position.x, baseline), label_text, HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, 20, AppTheme.ACCENT_TEXT)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if next_encounters.is_empty():
		warnings.append("Pick the starting encounters in Next Encounters.")
	if not get_parent() is CampaignMapCanvas:
		warnings.append("The Entrance must be a direct child of a CampaignMapCanvas.")
	return warnings
