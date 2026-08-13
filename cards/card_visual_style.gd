class_name CardVisualStyle
extends Resource

## Optional visual overrides for a CardDefinition. Disabled or empty values inherit
## directly from the editor-authored card_base.tscn scene.

@export_group("Textures")
@export var background_texture: Texture2D
@export var frame_overlay_texture: Texture2D

@export_group("Fonts")
@export var title_font: Font
@export var body_font: Font
@export var stats_font: Font
@export_range(0, 96, 1) var title_font_size: int = 0
@export_range(0, 96, 1) var body_font_size: int = 0
@export_range(0, 96, 1) var stats_font_size: int = 0

@export_group("Background Tint")
@export var override_background_tint: bool = false
@export var background_tint: Color = Color.WHITE

@export_group("Panel Color")
@export var override_panel_color: bool = false
@export var panel_color: Color = Color("#14223e")

@export_group("Border Color")
@export var override_border_color: bool = false
@export var border_color: Color = Color("#34496e")

@export_group("Accent Color")
@export var override_accent_color: bool = false
@export var accent_color: Color = Color("#43d9b5")

@export_group("Title Color")
@export var override_title_color: bool = false
@export var title_color: Color = Color("#e8f0ff")

@export_group("Body Color")
@export var override_body_color: bool = false
@export var body_color: Color = Color("#91a4c8")

@export_group("Stats Color")
@export var override_stats_color: bool = false
@export var stats_color: Color = Color("#ffc857")
