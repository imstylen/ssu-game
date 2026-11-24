@tool
class_name CampaignEncounter
extends TextureButton

## One clickable encounter on an authored campaign map. Place it as a direct
## child of a CampaignMapCanvas, drag it into position, and pick the encounters
## it unlocks in Next Encounters.

const MAP_ART_SHADER := preload("res://campaign/map/map_art.gdshader")
const DEFAULT_SIZE := Vector2(200, 200)
const PLATE_HEIGHT := 40.0
const STATE_TEXT := {"available": "Available", "completed": "Completed", "locked": "Locked", "skipped": "Skipped"}
const STATE_SATURATION := {"available": 1.0, "completed": 1.0, "locked": 0.0, "skipped": 0.0}
const STATE_BRIGHTNESS := {"available": 1.0, "completed": 1.0, "locked": 0.95, "skipped": 0.7}

## Stable save identifier. Changing it invalidates saved routes that visited it.
@export var encounter_id: String = "":
	set(value):
		encounter_id = value
		_changed()
## Name shown on the map, e.g. the habitat. Falls back to the enemy's name.
@export var display_name: String = "":
	set(value):
		display_name = value
		_changed()
@export var enemy: EnemyDefinition:
	set(value):
		enemy = value
		_changed()
## Overrides the enemy's maximum Heart when greater than zero.
@export_range(0, 1000) var maximum_health_override: int = 0:
	set(value):
		maximum_health_override = value
		_changed()
## Replaces the enemy's repeating damage pattern when not empty.
@export var attack_pattern_override := PackedInt32Array():
	set(value):
		attack_pattern_override = value
		_changed()
## Habitat illustration. Falls back to the enemy artwork.
@export var map_art: Texture2D:
	set(value):
		map_art = value
		_changed()
## The campaign ends after winning this encounter. Exactly one per map.
@export var is_final := false:
	set(value):
		is_final = value
		_changed()
## Encounters unlocked after winning this one. Pick CampaignEncounter nodes.
# Typed as TextureButton: a script whose export is typed with its own class
# keeps itself alive and leaks at exit. Map validation rejects other nodes.
@export var next_encounters: Array[TextureButton] = []:
	set(value):
		next_encounters = value
		_changed()

# Runtime presentation state; empty in the editor (always shown in color).
var state: String = ""
var is_selected := false
var _art: TextureRect
var _overlay: Control
var _material: ShaderMaterial


func _init() -> void:
	size = DEFAULT_SIZE
	custom_minimum_size = DEFAULT_SIZE
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = MAP_ART_SHADER
	_art = TextureRect.new()
	_art.name = "Art"
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.material = _material
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.offset_bottom = -PLATE_HEIGHT * 0.6
	add_child(_art, false, Node.INTERNAL_MODE_FRONT)
	_overlay = Control.new()
	_overlay.name = "Overlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay, false, Node.INTERNAL_MODE_BACK)
	for signal_name in ["focus_entered", "focus_exited", "mouse_entered", "mouse_exited"]:
		connect(signal_name, _redraw_all)
	set_process(false)
	_changed()


func set_state(new_state: String, selected: bool) -> void:
	state = new_state
	is_selected = selected
	set_process(state == "available" and not Engine.is_editor_hint())
	_changed()


func center() -> Vector2:
	return position + size * 0.5


func art_texture() -> Texture2D:
	if map_art != null:
		return map_art
	return enemy.artwork if enemy != null else null


func label_text() -> String:
	if not display_name.strip_edges().is_empty():
		return display_name
	if enemy != null:
		return enemy.display_name
	return encounter_id if not encounter_id.is_empty() else "(no encounter_id)"


func art_saturation() -> float:
	return STATE_SATURATION.get(state, 1.0)


func _changed() -> void:
	if _art != null:
		_art.texture = art_texture()
		_material.set_shader_parameter("saturation", art_saturation())
		_material.set_shader_parameter("brightness", STATE_BRIGHTNESS.get(state, 1.0))
	var status: String = STATE_TEXT.get(state, "")
	var enemy_name := enemy.display_name if enemy != null else "no enemy"
	tooltip_text = "%s — %s%s" % [label_text(), enemy_name, (" (%s)" % status) if not status.is_empty() else ""]
	_redraw_all()
	if Engine.is_editor_hint() and is_inside_tree():
		update_configuration_warnings()
		var parent := get_parent()
		if parent is Control:
			parent.update_configuration_warnings()
			parent.queue_redraw()


func _redraw_all() -> void:
	queue_redraw()
	if _overlay != null:
		_overlay.queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# Drawn beneath the artwork: boss frame and the available glow.
	var middle := (size - Vector2(0, PLATE_HEIGHT * 0.6)) * 0.5
	var radius := minf(size.x, size.y - PLATE_HEIGHT * 0.6) * 0.5
	if state == "available":
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 260.0)
		draw_circle(middle, radius * (1.02 + 0.08 * pulse), Color(AppTheme.ACCENT, 0.30 + 0.25 * pulse))
	if is_final:
		var ring_color := AppTheme.GOLD if state in ["", "available", "completed"] else Color("9a9a9a")
		draw_arc(middle, radius * 0.98, 0.0, TAU, 64, ring_color, 10.0, true)


func _draw_overlay() -> void:
	var font: Font = AppTheme.FREDOKA
	var muted := state in ["locked", "skipped"]
	# Name plate.
	var plate := Rect2(Vector2(4, size.y - PLATE_HEIGHT), Vector2(size.x - 8, PLATE_HEIGHT))
	var fill := Color("ececec") if muted else AppTheme.SURFACE
	var border := AppTheme.INK if has_focus() or is_selected or is_hovered() else (AppTheme.MUTED if muted else AppTheme.INK)
	_overlay.draw_style_box(AppTheme.style_box(fill, border, 14, 3, 0), plate)
	var font_size := 19
	var text := label_text()
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	if text_width > plate.size.x - 12:
		font_size = 15
	var baseline := plate.position.y + (PLATE_HEIGHT + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var text_color := AppTheme.SECONDARY_TEXT if muted else AppTheme.INK
	if Engine.is_editor_hint() and (encounter_id.is_empty() or enemy == null):
		text_color = AppTheme.DANGER_TEXT
	_overlay.draw_string(font, Vector2(plate.position.x, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, font_size, text_color)
	# Focus and selection rings make keyboard position visible without color.
	if has_focus():
		_overlay.draw_style_box(AppTheme.style_box(Color(0, 0, 0, 0), AppTheme.INK, 22, 5, 0), Rect2(Vector2(-8, -8), size + Vector2(16, 16)))
	elif is_selected:
		_overlay.draw_style_box(AppTheme.style_box(Color(0, 0, 0, 0), AppTheme.ACCENT_TEXT, 22, 4, 0), Rect2(Vector2(-6, -6), size + Vector2(12, 12)))
	if not state.is_empty():
		_draw_badge(Vector2(size.x - 24, 24))


# Every state has a distinct symbol so status never depends on color alone.
func _draw_badge(at: Vector2) -> void:
	var radius := 21.0
	var fill := Color.WHITE
	if state == "completed":
		fill = AppTheme.GOLD
	elif state == "available":
		fill = AppTheme.ACCENT_DARK
	_overlay.draw_circle(at, radius, fill)
	_overlay.draw_arc(at, radius, 0.0, TAU, 32, AppTheme.INK, 3.0, true)
	match state:
		"available":
			_overlay.draw_colored_polygon(PackedVector2Array([at + Vector2(-6, -10), at + Vector2(11, 0), at + Vector2(-6, 10)]), AppTheme.ACCENT_TEXT)
		"completed":
			_overlay.draw_polyline(PackedVector2Array([at + Vector2(-10, 0), at + Vector2(-3, 8), at + Vector2(11, -8)]), AppTheme.INK, 4.5, true)
		"locked":
			_overlay.draw_arc(at + Vector2(0, -3), 7.0, PI, TAU, 16, AppTheme.INK, 3.5, true)
			_overlay.draw_line(at + Vector2(-7, -3), at + Vector2(-7, 1), AppTheme.INK, 3.5)
			_overlay.draw_line(at + Vector2(7, -3), at + Vector2(7, 1), AppTheme.INK, 3.5)
			_overlay.draw_rect(Rect2(at + Vector2(-11, 0), Vector2(22, 13)), AppTheme.INK)
		"skipped":
			_overlay.draw_line(at + Vector2(-8, -8), at + Vector2(8, 8), AppTheme.SECONDARY_TEXT, 4.5, true)
			_overlay.draw_line(at + Vector2(8, -8), at + Vector2(-8, 8), AppTheme.SECONDARY_TEXT, 4.5, true)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if encounter_id.strip_edges().is_empty():
		warnings.append("Set an encounter_id; saved routes refer to it.")
	if enemy == null:
		warnings.append("Assign an enemy definition.")
	if not get_parent() is CampaignMapCanvas:
		warnings.append("Encounters must be direct children of a CampaignMapCanvas.")
	return warnings
