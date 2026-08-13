@tool
class_name CardBase
extends Button

signal card_activated(instance_id: int)

const FALLBACK_ARTWORK: Texture2D = preload("res://icon.svg")

@export_group("Editor Preview")
@export var editor_preview_definition: CardDefinition:
	set(value):
		editor_preview_definition = value
		_queue_editor_preview_refresh()
@export var editor_preview_compact: bool = false:
	set(value):
		editor_preview_compact = value
		_queue_editor_preview_refresh()

@export_group("Full Layout")
@export var full_minimum_size := Vector2(218, 330)
@export_range(0, 40, 1) var full_content_margin: int = 10
@export_range(0, 30, 1) var full_separation: int = 7
@export_range(1, 300, 1) var full_artwork_height: int = 118

@export_group("Compact Layout")
@export var compact_minimum_size := Vector2(164, 188)
@export_range(0, 40, 1) var compact_content_margin: int = 7
@export_range(0, 30, 1) var compact_separation: int = 3
@export_range(1, 300, 1) var compact_artwork_height: int = 70
@export_range(1, 96, 1) var compact_title_font_size: int = 16
@export_range(1, 96, 1) var compact_body_font_size: int = 11
@export_range(1, 96, 1) var compact_stats_font_size: int = 13

var definition: CardDefinition
var instance: CardInstance
var interactive: bool = false
var footer_text: String = ""
var compact: bool = false

@onready var _background: TextureRect = %CardBackground
@onready var _frame_overlay: TextureRect = %FrameOverlay
@onready var _content_margin: MarginContainer = %ContentMargin
@onready var _content_stack: VBoxContainer = %ContentStack
@onready var _name_label: Label = %NameLabel
@onready var _cost_label: Label = %CostLabel
@onready var _type_label: Label = %TypeLabel
@onready var _artwork_frame: PanelContainer = %ArtworkFrame
@onready var _artwork: TextureRect = %Artwork
@onready var _description_label: Label = %DescriptionLabel
@onready var _attack_label: Label = %AttackLabel
@onready var _health_label: Label = %HealthLabel
@onready var _action_label: Label = %ActionLabel
@onready var _footer_label: Label = %FooterLabel
@onready var _interactive_outline: Panel = %InteractiveOutline

var _base_background_texture: Texture2D
var _base_frame_overlay_texture: Texture2D
var _base_background_modulate := Color.WHITE
var _base_button_styles: Dictionary = {}
var _base_artwork_style: StyleBox
var _base_outline_style: StyleBox
var _base_label_colors: Dictionary = {}
var _base_label_fonts: Dictionary = {}
var _base_label_sizes: Dictionary = {}
var _preview_definition_connection: CardDefinition
var _preview_style_connection: CardVisualStyle


func _ready() -> void:
	_cache_scene_defaults()
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	if Engine.is_editor_hint():
		definition = editor_preview_definition
		instance = null
		compact = editor_preview_compact
		_connect_editor_preview_resources()
	_refresh()


func _exit_tree() -> void:
	_disconnect_editor_preview_resources()


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
		_apply_interaction_state()


func set_compact(enabled: bool = true) -> void:
	compact = enabled
	if is_node_ready():
		_refresh()


func get_displayed_artwork() -> Texture2D:
	return _artwork.texture if is_node_ready() else null


func _refresh() -> void:
	if not is_node_ready():
		return
	_restore_scene_defaults()
	_bind_card_data()
	_apply_layout()
	if definition != null and definition.visual_style != null:
		_apply_visual_style(definition.visual_style)
	_apply_interaction_state()


func _bind_card_data() -> void:
	if definition == null:
		_name_label.text = "Unknown Card"
		_cost_label.text = "-"
		_type_label.text = "MISSING"
		_artwork.texture = FALLBACK_ARTWORK
		_description_label.text = "This card definition could not be loaded."
		_attack_label.visible = false
		_health_label.visible = false
		_action_label.visible = true
		_action_label.text = "NO DATA"
		_footer_label.text = footer_text
		return
	_name_label.text = definition.display_name
	_cost_label.text = str(definition.cost)
	_type_label.text = "UNIT" if definition.card_type == CardDefinition.CardType.UNIT else "ACTION"
	_artwork.texture = definition.artwork if definition.artwork != null else FALLBACK_ARTWORK
	_description_label.text = definition.description
	if definition.card_type == CardDefinition.CardType.UNIT:
		var attack := instance.current_attack if instance != null else definition.attack
		var health := instance.current_health if instance != null else definition.health
		_attack_label.text = "ATK %d" % attack
		_health_label.text = "HP %d" % health
		_attack_label.visible = true
		_health_label.visible = true
		_action_label.visible = false
	else:
		_attack_label.visible = false
		_health_label.visible = false
		_action_label.visible = true
		_action_label.text = "ONE-SHOT"
	_footer_label.text = footer_text


func _apply_layout() -> void:
	custom_minimum_size = compact_minimum_size if compact else full_minimum_size
	var margin := compact_content_margin if compact else full_content_margin
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		_content_margin.add_theme_constant_override(side, margin)
	_content_stack.add_theme_constant_override(
		"separation",
		compact_separation if compact else full_separation
	)
	_artwork_frame.custom_minimum_size.y = compact_artwork_height if compact else full_artwork_height
	_description_label.visible = not compact
	_footer_label.visible = not footer_text.is_empty()
	if compact:
		_name_label.add_theme_font_size_override("font_size", compact_title_font_size)
		for label in [_type_label, _description_label, _footer_label]:
			label.add_theme_font_size_override("font_size", compact_body_font_size)
		for label in [_cost_label, _attack_label, _health_label, _action_label]:
			label.add_theme_font_size_override("font_size", compact_stats_font_size)


func _apply_visual_style(style: CardVisualStyle) -> void:
	if style.background_texture != null:
		_background.texture = style.background_texture
	if style.frame_overlay_texture != null:
		_frame_overlay.texture = style.frame_overlay_texture
	if style.override_background_tint:
		_background.modulate = style.background_tint
	if style.override_panel_color or style.override_border_color:
		_apply_button_style_colors(style)
	if style.override_border_color:
		_apply_border_color(_artwork_frame, "panel", style.border_color)
	if style.override_accent_color:
		for label in [_cost_label, _type_label, _footer_label]:
			label.add_theme_color_override("font_color", style.accent_color)
		_apply_border_color(_interactive_outline, "panel", style.accent_color)
	if style.override_title_color:
		_name_label.add_theme_color_override("font_color", style.title_color)
	if style.override_body_color:
		for label in [_type_label, _description_label, _footer_label]:
			label.add_theme_color_override("font_color", style.body_color)
	if style.override_stats_color:
		for label in [_cost_label, _attack_label, _health_label, _action_label]:
			label.add_theme_color_override("font_color", style.stats_color)
	if style.title_font != null:
		_name_label.add_theme_font_override("font", style.title_font)
	if style.body_font != null:
		for label in [_type_label, _description_label, _footer_label]:
			label.add_theme_font_override("font", style.body_font)
	if style.stats_font != null:
		for label in [_cost_label, _attack_label, _health_label, _action_label]:
			label.add_theme_font_override("font", style.stats_font)
	if style.title_font_size > 0:
		_name_label.add_theme_font_size_override("font_size", style.title_font_size)
	if style.body_font_size > 0:
		for label in [_type_label, _description_label, _footer_label]:
			label.add_theme_font_size_override("font_size", style.body_font_size)
	if style.stats_font_size > 0:
		for label in [_cost_label, _attack_label, _health_label, _action_label]:
			label.add_theme_font_size_override("font_size", style.stats_font_size)


func _apply_button_style_colors(style: CardVisualStyle) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var current := get_theme_stylebox(state)
		if not current is StyleBoxFlat:
			continue
		var box: StyleBoxFlat = current.duplicate(true)
		if style.override_panel_color:
			match state:
				"hover": box.bg_color = style.panel_color.lightened(0.08)
				"pressed": box.bg_color = style.panel_color.darkened(0.08)
				"disabled": box.bg_color = style.panel_color.darkened(0.25)
				_: box.bg_color = style.panel_color
		if style.override_border_color:
			box.border_color = style.border_color
		add_theme_stylebox_override(state, box)
	if style.override_border_color:
		_apply_border_color(self, "focus", style.border_color)


func _apply_border_color(control: Control, style_name: StringName, color: Color) -> void:
	var current := control.get_theme_stylebox(style_name)
	if not current is StyleBoxFlat:
		return
	var box: StyleBoxFlat = current.duplicate(true)
	box.border_color = color
	control.add_theme_stylebox_override(style_name, box)


func _apply_interaction_state() -> void:
	_interactive_outline.visible = interactive and not Engine.is_editor_hint()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW
	focus_mode = Control.FOCUS_ALL if interactive else Control.FOCUS_NONE


func _cache_scene_defaults() -> void:
	_base_background_texture = _background.texture
	_base_frame_overlay_texture = _frame_overlay.texture
	_base_background_modulate = _background.modulate
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := get_theme_stylebox(state)
		if box != null:
			_base_button_styles[state] = box.duplicate(true)
	var artwork_style := _artwork_frame.get_theme_stylebox("panel")
	if artwork_style != null:
		_base_artwork_style = artwork_style.duplicate(true)
	var outline_style := _interactive_outline.get_theme_stylebox("panel")
	if outline_style != null:
		_base_outline_style = outline_style.duplicate(true)
	for label in _all_labels():
		_base_label_colors[label] = label.get_theme_color("font_color")
		_base_label_fonts[label] = label.get_theme_font("font")
		_base_label_sizes[label] = label.get_theme_font_size("font_size")


func _restore_scene_defaults() -> void:
	_background.texture = _base_background_texture
	_background.modulate = _base_background_modulate
	_frame_overlay.texture = _base_frame_overlay_texture
	for state in _base_button_styles:
		add_theme_stylebox_override(state, _base_button_styles[state].duplicate(true))
	if _base_artwork_style != null:
		_artwork_frame.add_theme_stylebox_override("panel", _base_artwork_style.duplicate(true))
	if _base_outline_style != null:
		_interactive_outline.add_theme_stylebox_override("panel", _base_outline_style.duplicate(true))
	for label in _all_labels():
		label.add_theme_color_override("font_color", _base_label_colors[label])
		label.add_theme_font_override("font", _base_label_fonts[label])
		label.add_theme_font_size_override("font_size", _base_label_sizes[label])


func _all_labels() -> Array[Label]:
	return [
		_name_label,
		_cost_label,
		_type_label,
		_description_label,
		_attack_label,
		_health_label,
		_action_label,
		_footer_label,
	]


func _on_pressed() -> void:
	if interactive and not Engine.is_editor_hint():
		card_activated.emit(instance.instance_id if instance != null else -1)


func _queue_editor_preview_refresh() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	call_deferred("_refresh_editor_preview")


func _refresh_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	definition = editor_preview_definition
	instance = null
	compact = editor_preview_compact
	_connect_editor_preview_resources()
	_refresh()


func _connect_editor_preview_resources() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	_disconnect_editor_preview_resources()
	if editor_preview_definition != null:
		_preview_definition_connection = editor_preview_definition
		if not _preview_definition_connection.changed.is_connected(_on_editor_preview_resource_changed):
			_preview_definition_connection.changed.connect(_on_editor_preview_resource_changed)
		if editor_preview_definition.visual_style != null:
			_preview_style_connection = editor_preview_definition.visual_style
			if not _preview_style_connection.changed.is_connected(_on_editor_preview_resource_changed):
				_preview_style_connection.changed.connect(_on_editor_preview_resource_changed)


func _disconnect_editor_preview_resources() -> void:
	if _preview_definition_connection != null \
	and _preview_definition_connection.changed.is_connected(_on_editor_preview_resource_changed):
		_preview_definition_connection.changed.disconnect(_on_editor_preview_resource_changed)
	if _preview_style_connection != null \
	and _preview_style_connection.changed.is_connected(_on_editor_preview_resource_changed):
		_preview_style_connection.changed.disconnect(_on_editor_preview_resource_changed)
	_preview_definition_connection = null
	_preview_style_connection = null


func _on_editor_preview_resource_changed() -> void:
	_queue_editor_preview_refresh()
