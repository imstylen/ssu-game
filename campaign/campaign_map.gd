extends Control

signal node_inspected(node_id: String)

const BACKDROP = preload("res://campaign/art/zoo_map.svg")
const STATE_LABELS := {"available": "> Available", "locked": "# Locked", "completed": "+ Completed", "skipped": "- Skipped"}
var definition := CampaignDefinition.new()
var progress: CampaignProgress
var buttons: Dictionary = {}
var selected: String = ""


func _ready() -> void:
	custom_minimum_size = Vector2(760, 680)
	var art := TextureRect.new()
	art.texture = BACKDROP
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	# Edges are drawn on a layer above the art and below the controls.
	var edges := Control.new()
	edges.name = "Connections"
	edges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edges.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edges.draw.connect(_draw_connections.bind(edges))
	add_child(edges)
	for id in definition.nodes:
		var enemy := definition.enemy_variant(id, CardCatalog)
		var button := Button.new()
		button.name = id
		button.icon = enemy.artwork
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 62)
		button.add_theme_font_size_override("font_size", 21)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_inspect.bind(id))
		button.focus_entered.connect(_inspect.bind(id))
		button.mouse_entered.connect(_inspect.bind(id))
		add_child(button)
		buttons[id] = button
	var entrance := Label.new()
	entrance.name = "Entrance"
	entrance.text = "ZOO ENTRANCE"
	entrance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	entrance.add_theme_font_size_override("font_size", 24)
	entrance.add_theme_color_override("font_color", Color("416651"))
	entrance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(entrance)
	resized.connect(_layout)
	_layout()
	refresh()


func _inspect(id: String) -> void:
	selected = id
	node_inspected.emit(id)
	refresh()


func center_for(id: String) -> Vector2:
	var node: Dictionary = definition.nodes[id]
	var count: int = [2, 3, 3, 2, 1][node.tier - 1]
	var fraction: float = (float(node.column) + 1.0) / (count + 1.0)
	return Vector2(size.x * fraction, size.y * (0.83 - (node.tier - 1) * 0.177))


func _layout() -> void:
	for id in buttons:
		var button: Button = buttons[id]
		button.size = Vector2(clampf(size.x * 0.235, 225, 288), 98)
		button.position = center_for(id) - button.size * 0.5
	get_node("Entrance").position = Vector2(size.x * 0.5 - 150, size.y * 0.927)
	get_node("Entrance").size = Vector2(300, 40)
	get_node("Connections").queue_redraw()


func refresh() -> void:
	for id in buttons:
		var status := progress.node_status(id) if progress != null else "locked"
		var label: String = STATE_LABELS[status]
		if progress != null and progress.committed == id:
			label = "> Available / Retry"
		var enemy := definition.enemy_variant(id, CardCatalog)
		var button: Button = buttons[id]
		button.text = "%s\n%s" % [enemy.display_name.replace("Gatekeeping ", "Gatekeeping\n"), label]
		if id == CampaignDefinition.BOSS:
			button.text = "BOSS: Gremlin\n" + label
		button.tooltip_text = "%s — %s. Inspect encounter." % [enemy.display_name, label]
		var border := AppTheme.ACCENT_TEXT if status == "available" else AppTheme.SECONDARY_TEXT
		if status == "completed" or id == CampaignDefinition.BOSS:
			border = AppTheme.GOLD_TEXT
		var fill := Color("fff9e8") if status in ["available", "completed"] else Color("e8eddf")
		button.add_theme_stylebox_override("normal", AppTheme.style_box(fill, border, 16, 4 if id == CampaignDefinition.BOSS or id == selected else 2, 10))
		button.add_theme_stylebox_override("hover", AppTheme.style_box(Color("ffffff"), AppTheme.ACCENT_TEXT, 16, 4, 10))
		button.add_theme_stylebox_override("focus", AppTheme.style_box(Color(0, 0, 0, 0), AppTheme.INK, 16, 4, 0))
		for color_name in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
			button.add_theme_color_override(color_name, AppTheme.INK)
	if is_node_ready():
		get_node("Connections").queue_redraw()


func _draw_connections(layer: Control) -> void:
	var route: Array = []
	if progress != null:
		route.assign(progress.completed)
		if not progress.committed.is_empty():
			route.append(progress.committed)
	for id in definition.nodes:
		for next in definition.nodes[id].next:
			var chosen: bool = id in route and next in route
			var start := center_for(id) - Vector2(0, 49)
			var finish := center_for(next) + Vector2(0, 49)
			layer.draw_line(start, finish, Color("fffcdf"), 12, true)
			layer.draw_line(start, finish, AppTheme.GOLD_TEXT if chosen else Color("416651"), 7 if chosen else 3, true)
