class_name CardView
extends Button

signal card_activated(instance_id: int)

var definition: CardDefinition
var instance: CardInstance
var interactive: bool = false
var footer_text: String = ""
var compact: bool = false

var _name_label: Label
var _type_label: Label
var _description_label: Label
var _stats_label: Label
var _footer_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(218, 278)
	clip_contents = true
	_build_content()
	pressed.connect(_on_pressed)
	_refresh()


func setup_definition(card_definition: CardDefinition, footer: String = "") -> void:
	definition = card_definition
	instance = null
	footer_text = footer
	if is_node_ready():
		_refresh()


func setup_instance(card_instance: CardInstance, footer: String = "") -> void:
	instance = card_instance
	definition = instance.definition if instance != null else null
	footer_text = footer
	if is_node_ready():
		_refresh()


func set_interactive(enabled: bool) -> void:
	interactive = enabled
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if is_node_ready():
		_refresh_style()


func set_compact(enabled: bool = true) -> void:
	compact = enabled
	if is_node_ready():
		_apply_compact_layout()


func _build_content() -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	add_child(margin)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)
	_name_label = Label.new()
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.add_theme_font_size_override("font_size", 23)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_name_label)
	_type_label = Label.new()
	_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_type_label.add_theme_font_size_override("font_size", 14)
	_type_label.add_theme_color_override("font_color", AppTheme.ACCENT)
	stack.add_child(_type_label)
	var divider := HSeparator.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(divider)
	_description_label = Label.new()
	_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_description_label.add_theme_font_size_override("font_size", 16)
	_description_label.add_theme_color_override("font_color", AppTheme.MUTED)
	stack.add_child(_description_label)
	_stats_label = Label.new()
	_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_label.add_theme_font_size_override("font_size", 20)
	_stats_label.add_theme_color_override("font_color", AppTheme.GOLD)
	stack.add_child(_stats_label)
	_footer_label = Label.new()
	_footer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_footer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer_label.add_theme_font_size_override("font_size", 13)
	_footer_label.add_theme_color_override("font_color", AppTheme.MUTED)
	stack.add_child(_footer_label)
	_apply_compact_layout()


func _refresh() -> void:
	if _name_label == null:
		return
	if definition == null:
		_name_label.text = "Unknown Card"
		_type_label.text = "MISSING"
		_description_label.text = "This card definition could not be loaded."
		_stats_label.text = ""
		_footer_label.text = footer_text
		return
	_name_label.text = definition.display_name
	_type_label.text = "UNIT" if definition.card_type == CardDefinition.CardType.UNIT else "ACTION"
	_description_label.text = definition.description
	if definition.card_type == CardDefinition.CardType.UNIT:
		var attack := instance.current_attack if instance != null else definition.attack
		var health := instance.current_health if instance != null else definition.health
		_stats_label.text = "⚡ %d     ◆ %d     ♥ %d" % [definition.cost, attack, health]
	else:
		_stats_label.text = "⚡ %d     ONE-SHOT" % definition.cost
	_footer_label.text = footer_text
	_refresh_style()


func _refresh_style() -> void:
	if definition == null:
		return
	var border := AppTheme.ACCENT if interactive else Color("#34496e")
	var fill := Color("#14223e") if definition.card_type == CardDefinition.CardType.UNIT else Color("#251b3d")
	add_theme_stylebox_override("normal", AppTheme.style_box(fill, border, 14, 2, 12))
	add_theme_stylebox_override("hover", AppTheme.style_box(fill.lightened(0.08), AppTheme.ACCENT, 14, 3, 12))
	add_theme_stylebox_override("pressed", AppTheme.style_box(fill.darkened(0.08), AppTheme.GOLD, 14, 3, 12))
	add_theme_stylebox_override("focus", AppTheme.style_box(Color.TRANSPARENT, AppTheme.ACCENT, 14, 2, 12))


func _apply_compact_layout() -> void:
	if _description_label == null:
		return
	_description_label.visible = not compact
	_footer_label.visible = not compact or not footer_text.is_empty()
	custom_minimum_size = Vector2(164, 188) if compact else Vector2(218, 278)
	_name_label.add_theme_font_size_override("font_size", 18 if compact else 23)
	_stats_label.add_theme_font_size_override("font_size", 15 if compact else 20)


func _on_pressed() -> void:
	if interactive:
		card_activated.emit(instance.instance_id if instance != null else -1)
