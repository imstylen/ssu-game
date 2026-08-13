extends Control

const CARD_BASE_SCENE := preload("res://ui/card_base.tscn")


func _ready() -> void:
	theme = AppTheme.create_theme()
	AppTheme.make_background(self)
	_build_ui()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	margin.add_child(stack)
	var header := HBoxContainer.new()
	stack.add_child(header)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_stack)
	title_stack.add_child(AppTheme.heading("ALLY ALBUM", 36))
	var subtitle := Label.new()
	subtitle.text = "Meet every disabled and neurodivergent animal ally. Everyone is unlocked."
	subtitle.add_theme_color_override("font_color", AppTheme.SECONDARY_TEXT)
	title_stack.add_child(subtitle)
	var back := AppTheme.button("← COZY CORNER", 210)
	back.pressed.connect(SceneNavigator.go_to_main_menu)
	header.add_child(back)
	var divider := HSeparator.new()
	stack.add_child(divider)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 22)
	scroll.add_child(grid)
	var selected := ProfileStore.get_selected_deck()
	for definition in CardCatalog.get_all_cards():
		var copies := selected.card_ids.count(definition.id) if selected != null else 0
		var card_view: CardBase = CARD_BASE_SCENE.instantiate()
		card_view.setup_definition(definition, "IN YOUR DECK: %d / %d" % [copies, ProfileStore.deck_rules.duplicate_card_limit])
		grid.add_child(card_view)
