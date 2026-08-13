extends Control

const CARD_BASE_SCENE := preload("res://ui/card_base.tscn")

var _deck_list: ItemList
var _name_edit: LineEdit
var _card_grid: GridContainer
var _validation_label: Label
var _count_label: Label
var _save_button: Button
var _play_button: Button
var _delete_button: Button
var _delete_dialog: ConfirmationDialog
var _working_deck_id: String = ""
var _working_ids: Array[StringName] = []


func _ready() -> void:
	theme = AppTheme.create_theme()
	AppTheme.make_background(self)
	_build_ui()
	_refresh_deck_list()
	_load_deck(ProfileStore.selected_deck_id)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_bottom", 26)
	add_child(margin)
	var root_stack := VBoxContainer.new()
	root_stack.add_theme_constant_override("separation", 16)
	margin.add_child(root_stack)
	var header := HBoxContainer.new()
	root_stack.add_child(header)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_stack)
	title_stack.add_child(AppTheme.heading("COZY DECK BUILDER", 34))
	var subtitle := Label.new()
	subtitle.text = "Mix 1–20 ally cards • up to 2 copies of each friend"
	subtitle.add_theme_color_override("font_color", AppTheme.SECONDARY_TEXT)
	title_stack.add_child(subtitle)
	var back := AppTheme.button("← COZY CORNER", 210)
	back.pressed.connect(SceneNavigator.go_to_main_menu)
	header.add_child(back)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root_stack.add_child(body)
	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size.x = 280
	body.add_child(sidebar)
	var side_stack := VBoxContainer.new()
	side_stack.add_theme_constant_override("separation", 10)
	sidebar.add_child(side_stack)
	side_stack.add_child(AppTheme.heading("YOUR DECKS", 20))
	_deck_list = ItemList.new()
	_deck_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_deck_list.item_selected.connect(_on_deck_selected)
	side_stack.add_child(_deck_list)
	var new_button := AppTheme.button("+ NEW ALLY DECK")
	new_button.pressed.connect(_new_deck)
	side_stack.add_child(new_button)
	_delete_button = AppTheme.button("REMOVE DECK")
	_delete_button.pressed.connect(_request_delete)
	side_stack.add_child(_delete_button)
	var editor_panel := PanelContainer.new()
	editor_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(editor_panel)
	var editor_stack := VBoxContainer.new()
	editor_stack.add_theme_constant_override("separation", 10)
	editor_panel.add_child(editor_stack)
	var name_row := HBoxContainer.new()
	editor_stack.add_child(name_row)
	var name_label := Label.new()
	name_label.text = "DECK NAME"
	name_label.custom_minimum_size.x = 120
	name_label.add_theme_color_override("font_color", AppTheme.SECONDARY_TEXT)
	name_row.add_child(name_label)
	_name_edit = LineEdit.new()
	_name_edit.max_length = 40
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.text_changed.connect(func(_value: String): _refresh_validation())
	name_row.add_child(_name_edit)
	_count_label = Label.new()
	_count_label.custom_minimum_size.x = 110
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name_row.add_child(_count_label)
	var separator := HSeparator.new()
	editor_stack.add_child(separator)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor_stack.add_child(scroll)
	_card_grid = GridContainer.new()
	_card_grid.columns = 3
	_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_grid.add_theme_constant_override("h_separation", 14)
	_card_grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(_card_grid)
	_validation_label = Label.new()
	_validation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_validation_label.custom_minimum_size.y = 28
	editor_stack.add_child(_validation_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	editor_stack.add_child(actions)
	_save_button = AppTheme.button("SAVE DECK", 180)
	_save_button.pressed.connect(_save_deck)
	actions.add_child(_save_button)
	_play_button = AppTheme.button("SAVE & START", 210)
	_play_button.pressed.connect(_save_and_play)
	actions.add_child(_play_button)
	var hint := Label.new()
	hint.text = "You can keep editing a deck that still needs a little help."
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", AppTheme.SECONDARY_TEXT)
	actions.add_child(hint)
	_delete_dialog = ConfirmationDialog.new()
	_delete_dialog.title = "Remove this deck?"
	_delete_dialog.dialog_text = "This removes the selected deck from this device. Your ally cards stay unlocked."
	_delete_dialog.confirmed.connect(_delete_deck)
	add_child(_delete_dialog)


func _refresh_deck_list() -> void:
	_deck_list.clear()
	var selected_index := 0
	var decks := ProfileStore.get_decks()
	for index in decks.size():
		var deck: DeckRecord = decks[index]
		_deck_list.add_item("%s  (%d)" % [deck.name, deck.card_ids.size()])
		_deck_list.set_item_metadata(index, deck.id)
		if deck.id == _working_deck_id or deck.id == ProfileStore.selected_deck_id:
			selected_index = index
	if not decks.is_empty():
		_deck_list.select(selected_index)
	_delete_button.disabled = decks.size() <= 1


func _load_deck(deck_id: String) -> void:
	var deck := ProfileStore.get_deck(deck_id)
	if deck == null:
		return
	_working_deck_id = deck.id
	_working_ids.assign(deck.card_ids)
	_name_edit.text = deck.name
	ProfileStore.select_deck(deck.id)
	_rebuild_catalog()
	_refresh_deck_list()
	_refresh_validation()


func _rebuild_catalog() -> void:
	for child in _card_grid.get_children():
		_card_grid.remove_child(child)
		child.queue_free()
	for definition in CardCatalog.get_all_cards():
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 6)
		_card_grid.add_child(cell)
		var count := _working_ids.count(definition.id)
		var view: CardBase = CARD_BASE_SCENE.instantiate()
		view.setup_definition(definition, "")
		view.set_compact()
		cell.add_child(view)
		var controls := HBoxContainer.new()
		cell.add_child(controls)
		var minus := AppTheme.button("−", 48)
		minus.disabled = count == 0
		minus.pressed.connect(_remove_card.bind(definition.id))
		controls.add_child(minus)
		var count_label := Label.new()
		count_label.text = "%d / %d" % [count, ProfileStore.deck_rules.duplicate_card_limit]
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls.add_child(count_label)
		var plus := AppTheme.button("+", 48)
		plus.disabled = not ProfileStore.deck_rules.can_add(_working_ids, definition.id)
		plus.pressed.connect(_add_card.bind(definition.id))
		controls.add_child(plus)
	var missing_ids: Array[StringName] = []
	for card_id in _working_ids:
		if not CardCatalog.has_card(card_id) and card_id not in missing_ids:
			missing_ids.append(card_id)
	for card_id in missing_ids:
		var missing_panel := PanelContainer.new()
		_card_grid.add_child(missing_panel)
		var missing_stack := VBoxContainer.new()
		missing_panel.add_child(missing_stack)
		var label := Label.new()
		label.text = "ALLY DETAILS MISSING\n%s\n%d copies" % [card_id, _working_ids.count(card_id)]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", AppTheme.DANGER_TEXT)
		missing_stack.add_child(label)
		var remove := AppTheme.button("REMOVE ONE")
		remove.pressed.connect(_remove_card.bind(card_id))
		missing_stack.add_child(remove)


func _refresh_validation(saved_message: String = "") -> void:
	_count_label.text = "%d / %d" % [_working_ids.size(), ProfileStore.deck_rules.maximum_deck_size]
	var errors := ProfileStore.deck_rules.validate(_working_ids, CardCatalog)
	if not saved_message.is_empty():
		_validation_label.text = saved_message
		_validation_label.add_theme_color_override("font_color", AppTheme.ACCENT_TEXT)
	elif errors.is_empty():
		_validation_label.text = "✓ Your allies are ready!"
		_validation_label.add_theme_color_override("font_color", AppTheme.ACCENT_TEXT)
	else:
		_validation_label.text = " • ".join(errors)
		_validation_label.add_theme_color_override("font_color", AppTheme.DANGER_TEXT)
	_save_button.disabled = _working_deck_id.is_empty()
	_play_button.disabled = not errors.is_empty()


func _add_card(card_id: StringName) -> void:
	if ProfileStore.deck_rules.can_add(_working_ids, card_id):
		_working_ids.append(card_id)
		_rebuild_catalog()
		_refresh_validation()


func _remove_card(card_id: StringName) -> void:
	var index := _working_ids.find(card_id)
	if index >= 0:
		_working_ids.remove_at(index)
		_rebuild_catalog()
		_refresh_validation()


func _save_deck() -> bool:
	if _working_deck_id.is_empty():
		return false
	var saved := ProfileStore.update_deck(_working_deck_id, _name_edit.text, _working_ids)
	_refresh_deck_list()
	_refresh_validation("Saved in your cozy corner." if saved else "That save did not work. Please try again.")
	return saved


func _save_and_play() -> void:
	if ProfileStore.deck_rules.validate(_working_ids, CardCatalog).is_empty() and _save_deck():
		SceneNavigator.go_to(SceneNavigator.BATTLE)


func _new_deck() -> void:
	var deck := ProfileStore.create_deck()
	_load_deck(deck.id)


func _request_delete() -> void:
	if ProfileStore.get_decks().size() > 1:
		_delete_dialog.popup_centered()


func _delete_deck() -> void:
	if ProfileStore.delete_deck(_working_deck_id):
		_load_deck(ProfileStore.selected_deck_id)


func _on_deck_selected(index: int) -> void:
	var deck_id: String = _deck_list.get_item_metadata(index)
	if deck_id != _working_deck_id:
		_load_deck(deck_id)
