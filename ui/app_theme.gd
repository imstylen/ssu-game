class_name AppTheme
extends RefCounted

const INK := Color("#4B315A")
const MUTED := Color("#7D6687")
const BACKGROUND := Color("#FFF4FA")
const SURFACE := Color("#FFFDF7")
const SURFACE_RAISED := Color("#FFE4F1")
const ACCENT := Color("#48CFAE")
const ACCENT_DARK := Color("#D6F8ED")
const DANGER := Color("#D9547F")
const GOLD := Color("#F4B942")
const FREDOKA: FontFile = preload("res://assets/fonts/Fredoka-Variable.ttf")


static func create_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = FREDOKA
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_shadow_color", "Label", Color.TRANSPARENT)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color("#A994B0"))
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_color("font_color", "ItemList", INK)
	theme.set_color("font_selected_color", "ItemList", INK)
	theme.set_color("font_color", "RichTextLabel", INK)
	theme.set_color("font_color", "ProgressBar", INK)
	theme.set_font_size("font_size", "Button", 17)
	theme.set_font_size("font_size", "LineEdit", 18)
	theme.set_constant("outline_size", "Label", 0)
	theme.set_stylebox("normal", "Button", style_box(SURFACE_RAISED, Color("#D985AD"), 16, 2, 12))
	theme.set_stylebox("hover", "Button", style_box(Color("#FFF0F7"), ACCENT, 16, 3, 12))
	theme.set_stylebox("pressed", "Button", style_box(ACCENT_DARK, Color("#279B82"), 16, 3, 12))
	theme.set_stylebox("disabled", "Button", style_box(Color("#F5EAF0"), Color("#CDBCC8"), 16, 1, 12))
	theme.set_stylebox("focus", "Button", style_box(Color.TRANSPARENT, INK, 16, 3, 12))
	theme.set_stylebox("panel", "Panel", style_box(SURFACE, Color("#E6B9CE"), 20, 2, 16))
	theme.set_stylebox("panel", "PanelContainer", style_box(SURFACE, Color("#E6B9CE"), 20, 2, 16))
	theme.set_stylebox("normal", "LineEdit", style_box(Color.WHITE, Color("#D9B5C8"), 12, 2, 10))
	theme.set_stylebox("focus", "LineEdit", style_box(Color.WHITE, INK, 12, 3, 10))
	theme.set_stylebox("panel", "ItemList", style_box(Color.WHITE, Color("#E6B9CE"), 14, 2, 8))
	theme.set_stylebox("selected", "ItemList", style_box(ACCENT_DARK, ACCENT, 7, 1, 6))
	theme.set_stylebox("selected_focus", "ItemList", style_box(ACCENT_DARK, INK, 7, 3, 6))
	theme.set_stylebox("background", "ProgressBar", style_box(Color("#F3DCE7"), Color("#D9B5C8"), 10, 1, 0))
	theme.set_stylebox("fill", "ProgressBar", style_box(DANGER, DANGER, 7, 0, 0))
	return theme


static func style_box(
	fill: Color,
	border: Color = Color.TRANSPARENT,
	radius: int = 10,
	border_width: int = 0,
	padding: int = 8
) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = padding
	box.content_margin_top = padding
	box.content_margin_right = padding
	box.content_margin_bottom = padding
	return box


static func make_background(parent: Control) -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(background)
	parent.move_child(background, 0)
	var glow := ColorRect.new()
	glow.color = Color("#48CFAE")
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	glow.custom_minimum_size.y = 8
	background.add_child(glow)


static func heading(text: String, size: int = 32, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


static func button(text: String, minimum_width: float = 0.0) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size = Vector2(minimum_width, 48)
	return control
