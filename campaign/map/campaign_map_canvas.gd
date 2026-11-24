@tool
class_name CampaignMapCanvas
extends Control

## Root of an authored campaign map scene. Children are one CampaignEntrance
## and any number of CampaignEncounter nodes, positioned in canvas pixels.
## Connections are drawn from each node's Next Encounters, live in the editor.

const LINE_COLOR := Color("416651")
const LINE_UNDER := Color("fffcdf")
const ROUTE_COLOR := AppTheme.GOLD
const PIN_COLOR := AppTheme.DANGER

@export var background: Texture2D:
	set(value):
		background = value
		queue_redraw()
## Logical size of the map. Node positions are stored in this space, so
## replacement art at any resolution keeps every encounter in place.
@export var canvas_size := Vector2(2560, 2880):
	set(value):
		canvas_size = value
		custom_minimum_size = value
		size = value
		queue_redraw()
## Draw connection lines in game. Arrows always show in the editor.
@export var show_connections := true:
	set(value):
		show_connections = value
		queue_redraw()

# Runtime presentation state.
var route: Array[String] = []
var states: Dictionary = {}
# CampaignEntrance or CampaignEncounter where the "You are here" pin sits.
var current_point: Control
var _overlay: Control


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _ready() -> void:
	custom_minimum_size = canvas_size
	size = canvas_size
	_overlay = Control.new()
	_overlay.name = "PinOverlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_draw_pin)
	add_child(_overlay, false, Node.INTERNAL_MODE_BACK)
	if Engine.is_editor_hint():
		child_order_changed.connect(update_configuration_warnings)
	# Editor: redraw each frame so arrows follow nodes while they are dragged.
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	queue_redraw()


func get_entrance() -> CampaignEntrance:
	for child in get_children():
		if child is CampaignEntrance:
			return child
	return null


func get_encounters() -> Array[CampaignEncounter]:
	var encounters: Array[CampaignEncounter] = []
	for child in get_children():
		if child is CampaignEncounter:
			encounters.append(child)
	return encounters


func get_encounter(id: String) -> CampaignEncounter:
	for encounter in get_encounters():
		if encounter.encounter_id == id:
			return encounter
	return null


## Reads the authored graph into UI-independent campaign data.
func build_definition() -> CampaignDefinition:
	var definition := CampaignDefinition.new()
	var entrances: Array[CampaignEntrance] = []
	for child in get_children():
		if child is CampaignEntrance:
			entrances.append(child)
		elif child is CampaignEncounter:
			var id: String = child.encounter_id.strip_edges()
			if id.is_empty():
				definition.authoring_errors.append("Encounter node '%s' needs an encounter_id." % child.name)
				continue
			if definition.nodes.has(id):
				definition.authoring_errors.append("Encounter ID '%s' is used more than once (node '%s')." % [id, child.name])
				continue
			definition.add_encounter(id, {
				"display_name": child.display_name,
				"enemy": child.enemy,
				"maximum_health": child.maximum_health_override,
				"attack_pattern": child.attack_pattern_override,
				"next": _linked_ids(child.next_encounters, child.name, definition),
				"is_final": child.is_final,
			})
	if entrances.size() != 1:
		definition.authoring_errors.append("The map needs exactly one CampaignEntrance (found %d)." % entrances.size())
	else:
		definition.start.assign(_linked_ids(entrances[0].next_encounters, entrances[0].name, definition))
	return definition


func _linked_ids(links: Array, owner_name: String, definition: CampaignDefinition) -> Array[String]:
	var ids: Array[String] = []
	for link in links:
		if link is CampaignEncounter and link.get_parent() == self and not link.encounter_id.strip_edges().is_empty():
			ids.append(link.encounter_id.strip_edges())
		else:
			definition.authoring_errors.append("'%s' links to a missing or unnamed encounter." % owner_name)
	return ids


## Applies saved progress to every encounter's look, the route lines, and the pin.
func apply_progress(progress: CampaignProgress, selected: String) -> void:
	states.clear()
	route.clear()
	for encounter in get_encounters():
		var status := progress.node_status(encounter.encounter_id) if progress != null else "locked"
		states[encounter.encounter_id] = status
		encounter.set_state(status, encounter.encounter_id == selected)
	current_point = get_entrance()
	if progress != null:
		route.assign(progress.completed)
		if not progress.committed.is_empty():
			route.append(progress.committed)
		var position_id := progress.current_position()
		if not position_id.is_empty():
			current_point = get_encounter(position_id)
	queue_redraw()
	if _overlay != null:
		_overlay.queue_redraw()


func current_center() -> Vector2:
	if current_point != null:
		return current_point.position + current_point.size * 0.5
	return canvas_size * 0.5


func _draw() -> void:
	if background != null:
		draw_texture_rect(background, Rect2(Vector2.ZERO, canvas_size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, canvas_size), Color("9fd27a"))
	var editing := Engine.is_editor_hint()
	if not show_connections and not editing:
		return
	var points: Array = []
	var entrance := get_entrance()
	if entrance != null:
		points.append(entrance)
	points.append_array(get_encounters())
	var route_path: Array = [""] + route
	for point in points:
		var from_id: String = point.encounter_id if point is CampaignEncounter else ""
		for target in point.next_encounters:
			if not target is CampaignEncounter or not is_instance_valid(target):
				continue
			var chosen := false
			var index := route_path.find(from_id)
			if index >= 0 and index + 1 < route_path.size() and route_path[index + 1] == target.encounter_id:
				chosen = true
			var faded: bool = not editing and (states.get(from_id) == "skipped" or states.get(target.encounter_id) == "skipped")
			_draw_connection(point, target, chosen, faded)


func _draw_connection(from, to, chosen: bool, faded: bool) -> void:
	var start: Vector2 = from.center()
	var finish: Vector2 = to.center()
	var direction: Vector2 = (finish - start).normalized()
	if direction == Vector2.ZERO:
		return
	var from_size: Vector2 = from.size
	var to_size: Vector2 = to.size
	start += direction * minf(from_size.x, from_size.y) * 0.45
	finish -= direction * minf(to_size.x, to_size.y) * 0.5
	var alpha := 0.35 if faded else 1.0
	var color := ROUTE_COLOR if chosen else LINE_COLOR
	draw_line(start, finish, Color(LINE_UNDER, alpha), 14.0 if chosen else 11.0, true)
	draw_line(start, finish, Color(color, alpha), 8.0 if chosen else 4.0, true)
	var side: Vector2 = direction.orthogonal() * 11.0
	var tip: Vector2 = finish
	var back: Vector2 = finish - direction * 22.0
	draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), Color(color, alpha))


func _draw_pin() -> void:
	if Engine.is_editor_hint() or current_point == null:
		return
	var tip := current_point.position + Vector2(current_point.size.x * 0.5, -6)
	var head := tip - Vector2(0, 46)
	_overlay.draw_colored_polygon(PackedVector2Array([tip, head + Vector2(-17, 8), head + Vector2(17, 8)]), PIN_COLOR)
	_overlay.draw_circle(head, 21.0, PIN_COLOR)
	_overlay.draw_arc(head, 21.0, 0.0, TAU, 32, AppTheme.INK, 3.0, true)
	_overlay.draw_circle(head, 8.0, Color.WHITE)
	var font: Font = AppTheme.FREDOKA
	var label := "You are here"
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 20
	var plate := Rect2(head + Vector2(28, -18), Vector2(width, 34))
	_overlay.draw_style_box(AppTheme.style_box(AppTheme.SURFACE, AppTheme.INK, 12, 2, 0), plate)
	_overlay.draw_string(font, plate.position + Vector2(10, 24), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, AppTheme.INK)


func _get_configuration_warnings() -> PackedStringArray:
	return build_definition().validation_errors()
