extends Control

var _deck_status: Label
var _battle_button: Button
var _notice: Label


func _ready() -> void:
	theme = AppTheme.create_theme()
	AppTheme.make_background(self)
	_build_ui()
	ProfileStore.profile_changed.connect(_refresh)
	_refresh()
	if "--smoke-test" in OS.get_cmdline_user_args():
		call_deferred("_run_scene_smoke_test")


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_right", 64)
	margin.add_theme_constant_override("margin_bottom", 44)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 36)
	margin.add_child(columns)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	identity.add_theme_constant_override("separation", 12)
	columns.add_child(identity)
	var eyebrow := Label.new()
	eyebrow.text = "A COZY CARD ADVENTURE"
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", AppTheme.ACCENT)
	identity.add_child(eyebrow)
	var title := AppTheme.heading("ACCESS ALLIES", 58)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity.add_child(title)
	var description := Label.new()
	description.text = "Disabled and neurodivergent animal allies sharing support, one barrier at a time."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 22)
	description.add_theme_color_override("font_color", AppTheme.MUTED)
	identity.add_child(description)
	var rule := HSeparator.new()
	rule.custom_minimum_size.y = 20
	identity.add_child(rule)
	var features := Label.new()
	features.text = "PLAY ALLIES • SHARE SUPPORT • BUST BARRIERS"
	features.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	features.add_theme_font_size_override("font_size", 15)
	features.add_theme_color_override("font_color", AppTheme.GOLD)
	identity.add_child(features)
	var menu_panel := PanelContainer.new()
	menu_panel.custom_minimum_size.x = 390
	columns.add_child(menu_panel)
	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 26)
	menu_margin.add_theme_constant_override("margin_top", 26)
	menu_margin.add_theme_constant_override("margin_right", 26)
	menu_margin.add_theme_constant_override("margin_bottom", 26)
	menu_panel.add_child(menu_margin)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 14)
	menu_margin.add_child(menu)
	menu.add_child(AppTheme.heading("YOUR COZY CORNER", 28))
	_deck_status = Label.new()
	_deck_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_deck_status.add_theme_color_override("font_color", AppTheme.MUTED)
	menu.add_child(_deck_status)
	_battle_button = AppTheme.button("START AN ADVENTURE")
	_battle_button.pressed.connect(_start_battle)
	menu.add_child(_battle_button)
	var decks_button := AppTheme.button("BUILD A DECK")
	decks_button.pressed.connect(func(): SceneNavigator.go_to(SceneNavigator.DECK_BUILDER))
	menu.add_child(decks_button)
	var collection_button := AppTheme.button("MEET THE ALLIES")
	collection_button.pressed.connect(func(): SceneNavigator.go_to(SceneNavigator.COLLECTION))
	menu.add_child(collection_button)
	_notice = Label.new()
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.add_theme_font_size_override("font_size", 14)
	_notice.add_theme_color_override("font_color", AppTheme.DANGER)
	menu.add_child(_notice)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu.add_child(spacer)
	var version := Label.new()
	version.text = "COZY OFFLINE PROFILE • SAVED ON THIS DEVICE"
	version.add_theme_font_size_override("font_size", 13)
	version.add_theme_color_override("font_color", AppTheme.MUTED)
	menu.add_child(version)


func _refresh() -> void:
	var deck := ProfileStore.get_selected_deck()
	var errors := ProfileStore.selected_deck_errors()
	if deck == null:
		_deck_status.text = "Choose an ally deck to begin."
	else:
		_deck_status.text = "READY: %s\n%d / %d cards" % [
			deck.name,
			deck.card_ids.size(),
			ProfileStore.deck_rules.maximum_deck_size,
		]
	_battle_button.disabled = not errors.is_empty()
	_notice.text = "Your deck needs a little help: %s" % errors[0] if not errors.is_empty() else "Saved here • Ready for an adventure!"
	_notice.add_theme_color_override("font_color", AppTheme.DANGER if not errors.is_empty() else AppTheme.ACCENT)


func _start_battle() -> void:
	if ProfileStore.selected_deck_errors().is_empty():
		SceneNavigator.go_to(SceneNavigator.BATTLE)


func _run_scene_smoke_test() -> void:
	await get_tree().process_frame
	var paths := [
		SceneNavigator.COLLECTION,
		SceneNavigator.DECK_BUILDER,
		SceneNavigator.BATTLE,
	]
	for path in paths:
		var packed: PackedScene = load(path)
		if packed == null:
			push_error("Smoke test could not load %s" % path)
			get_tree().quit(1)
			return
		var instance := packed.instantiate()
		instance.visible = false
		var battle_controller := instance.get_node_or_null("BattleController")
		if battle_controller != null:
			battle_controller.presentation_delay = 0.0
		get_tree().root.add_child(instance)
		await get_tree().process_frame
		await get_tree().process_frame
		instance.queue_free()
		await get_tree().process_frame
	print("SCENE_SMOKE_OK")
	get_tree().call_deferred("quit", 0)
