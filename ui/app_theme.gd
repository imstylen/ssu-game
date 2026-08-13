class_name AppTheme
extends RefCounted

const INK := Color("#e8f0ff")
const MUTED := Color("#91a4c8")
const BACKGROUND := Color("#080d1c")
const SURFACE := Color("#111a31")
const SURFACE_RAISED := Color("#192541")
const ACCENT := Color("#43d9b5")
const ACCENT_DARK := Color("#173f42")
const DANGER := Color("#ff6f7d")
const GOLD := Color("#ffc857")


static func create_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.45))
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color("#53617c"))
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_color("font_color", "ItemList", INK)
	theme.set_color("font_selected_color", "ItemList", Color.WHITE)
	theme.set_color("font_color", "RichTextLabel", INK)
	theme.set_color("font_color", "ProgressBar", INK)
	theme.set_font_size("font_size", "Button", 17)
	theme.set_font_size("font_size", "LineEdit", 18)
	theme.set_constant("outline_size", "Label", 2)
	theme.set_stylebox("normal", "Button", style_box(SURFACE_RAISED, Color("#31456e"), 10, 2, 12))
	theme.set_stylebox("hover", "Button", style_box(Color("#233459"), ACCENT, 10, 2, 12))
	theme.set_stylebox("pressed", "Button", style_box(ACCENT_DARK, ACCENT, 10, 2, 12))
	theme.set_stylebox("disabled", "Button", style_box(Color("#10172a"), Color("#29344c"), 10, 1, 12))
	theme.set_stylebox("focus", "Button", style_box(Color.TRANSPARENT, ACCENT, 10, 2, 12))
	theme.set_stylebox("panel", "Panel", style_box(SURFACE, Color("#283a60"), 14, 1, 16))
	theme.set_stylebox("panel", "PanelContainer", style_box(SURFACE, Color("#283a60"), 14, 1, 16))
	theme.set_stylebox("normal", "LineEdit", style_box(Color("#0c1429"), Color("#31456e"), 8, 1, 10))
	theme.set_stylebox("focus", "LineEdit", style_box(Color("#0c1429"), ACCENT, 8, 2, 10))
	theme.set_stylebox("panel", "ItemList", style_box(Color("#0c1429"), Color("#283a60"), 10, 1, 8))
	theme.set_stylebox("selected", "ItemList", style_box(ACCENT_DARK, ACCENT, 7, 1, 6))
	theme.set_stylebox("selected_focus", "ItemList", style_box(ACCENT_DARK, ACCENT, 7, 2, 6))
	theme.set_stylebox("background", "ProgressBar", style_box(Color("#090f20"), Color("#283a60"), 7, 1, 0))
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
	glow.color = Color(0.08, 0.28, 0.32, 0.22)
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
