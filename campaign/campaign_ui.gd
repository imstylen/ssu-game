extends Control

var _map: Control
var _preview: Label
var _portrait: TextureRect
var _notice: Label
var _start: Button
var _save_retry: Button
var _reset_dialog: ConfirmationDialog
var _selected: String = ""
var _definition := CampaignDefinition.new()


func _ready() -> void:
	theme = AppTheme.create_theme()
	AppTheme.make_background(self)
	_build_ui()
	ProfileStore.profile_changed.connect(_refresh)
	_initialize()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)
	var header := HBoxContainer.new()
	stack.add_child(header)
	var title := AppTheme.heading("THE ALLIES' ZOO TRAIL", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var home := AppTheme.button("COZY CORNER", 190)
	home.pressed.connect(SceneNavigator.go_to_main_menu)
	header.add_child(home)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(columns)
	_map = load("res://campaign/campaign_map.gd").new()
	_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map.node_inspected.connect(_inspect)
	columns.add_child(_map)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 380
	columns.add_child(panel)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 12)
	panel.add_child(details)
	details.add_child(AppTheme.heading("PLAN YOUR PATH", 25))
	var help := Label.new()
	help.text = "Five encounters. One shared adventure.\nInspect any friend-sized barrier below.\nOnly Start Battle commits your route."
	help.add_theme_font_size_override("font_size", 17)
	details.add_child(help)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(220, 180)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	details.add_child(_portrait)
	_preview = Label.new()
	_preview.custom_minimum_size = Vector2(340, 120)
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview.add_theme_font_size_override("font_size", 21)
	details.add_child(_preview)
	_start = AppTheme.button("START BATTLE")
	_start.pressed.connect(_start_encounter)
	details.add_child(_start)
	_notice = Label.new()
	_notice.custom_minimum_size.x = 340
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.add_theme_font_size_override("font_size", 17)
	details.add_child(_notice)
	_save_retry = AppTheme.button("RETRY SAVING")
	_save_retry.pressed.connect(_retry_save)
	details.add_child(_save_retry)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_child(spacer)
	var legend := Label.new()
	legend.text = "> Available    # Locked\n+ Completed    - Skipped\nGold connections: your chosen route"
	legend.add_theme_font_size_override("font_size", 17)
	details.add_child(legend)
	var decks := AppTheme.button("DECK BUILDER")
	decks.pressed.connect(func(): SceneNavigator.go_to(SceneNavigator.DECK_BUILDER))
	details.add_child(decks)
	var reset := AppTheme.button("START NEW CAMPAIGN")
	reset.pressed.connect(func(): _reset_dialog.popup_centered())
	details.add_child(reset)
	_reset_dialog = ConfirmationDialog.new()
	_reset_dialog.title = "Start New Campaign?"
	_reset_dialog.dialog_text = "Reset all campaign progress and your chosen route?\nYour decks and collection will be preserved."
	_reset_dialog.ok_button_text = "Reset Campaign Progress"
	_reset_dialog.confirmed.connect(_reset)
	add_child(_reset_dialog)


func _initialize() -> void:
	ProfileStore.initialize_campaign()
	_refresh()


func _inspect(id: String) -> void:
	_selected = id
	_refresh()


func _refresh() -> void:
	_map.progress = ProfileStore.campaign
	_map.refresh()
	_start.disabled = true
	_save_retry.visible = false
	_notice.text = "Tab to inspect encounters; Enter or Space activates buttons."
	if not ProfileStore.campaign_error.is_empty():
		_notice.text = ProfileStore.campaign_error
	elif ProfileStore.campaign == null:
		_notice.text = ProfileStore.last_save_error
		_save_retry.visible = true
	elif ProfileStore.campaign.is_complete():
		_notice.text = "CAMPAIGN COMPLETE!\nFive barriers overcome together. Your route is saved."
	else:
		var errors := ProfileStore.selected_deck_errors()
		if not errors.is_empty():
			_notice.text = "Your deck needs a little help:\n" + "\n".join(errors) + "\nUse Deck Builder, then return through the Cozy Corner."
		elif not _selected.is_empty():
			_start.disabled = ProfileStore.campaign.node_status(_selected) != "available"
	if _selected.is_empty():
		_portrait.texture = null
		_start.text = "START BATTLE"
		_preview.text = "Choose an encounter to see its Heart and repeating damage pattern."
		return
	var enemy := _definition.enemy_variant(_selected, CardCatalog)
	_portrait.texture = enemy.artwork
	var values := PackedStringArray()
	for damage in enemy.behavior.attack_pattern:
		values.append(str(damage))
	_preview.text = "%s\n%d maximum Heart\nDamage: %s (repeats)" % [enemy.display_name, enemy.maximum_health, " → ".join(values)]
	_start.text = "RETRY ENCOUNTER" if ProfileStore.campaign != null and ProfileStore.campaign.committed == _selected else "START BATTLE"


func _start_encounter() -> void:
	if _start.disabled:
		return
	if not SceneNavigator.start_campaign_battle(_selected):
		_notice.text = ProfileStore.last_save_error if not ProfileStore.last_save_error.is_empty() else "This encounter could not start. Please inspect an available encounter and try again."
		_save_retry.visible = not ProfileStore.last_save_error.is_empty()


func _retry_save() -> void:
	if ProfileStore.campaign == null:
		_initialize()
	else:
		_start_encounter()


func _reset() -> void:
	if ProfileStore.reset_campaign():
		_selected = ""
		_map.selected = ""
		_refresh()
	else:
		_notice.text = ProfileStore.last_save_error + "\nChoose Start New Campaign to try the reset again."
