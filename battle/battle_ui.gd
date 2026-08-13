extends Control

const CARD_BASE_SCENE := preload("res://ui/card_base.tscn")

@onready var controller: BattleController = $BattleController

var _turn_label: Label
var _player_label: Label
var _energy_label: Label
var _enemy_name: Label
var _enemy_artwork: TextureRect
var _enemy_description: Label
var _enemy_health: ProgressBar
var _intent_label: Label
var _board_container: HBoxContainer
var _hand_container: HBoxContainer
var _piles_label: Label
var _end_turn_button: Button
var _log: RichTextLabel
var _result_layer: Control
var _result_title: Label
var _result_body: Label
var _toast: Label
var _damage_overlay_layer: CanvasLayer
var _damage_overlay_root: Control
var _card_views_by_instance: Dictionary = {}
var _last_card_artwork_rects: Dictionary = {}


func _ready() -> void:
	theme = AppTheme.create_theme()
	AppTheme.make_background(self)
	_build_ui()
	controller.event_presented.connect(_on_event_presented)
	controller.session_changed.connect(_refresh)
	controller.input_lock_changed.connect(func(_locked: bool): _refresh())
	controller.invalid_action.connect(_show_message)
	call_deferred("_start_battle")


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	var root_stack := VBoxContainer.new()
	root_stack.add_theme_constant_override("separation", 10)
	margin.add_child(root_stack)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 52
	root_stack.add_child(header)
	var title := AppTheme.heading("BARRIER-BUSTING ADVENTURE", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_turn_label = Label.new()
	_turn_label.add_theme_color_override("font_color", AppTheme.SECONDARY_TEXT)
	header.add_child(_turn_label)
	var retreat := AppTheme.button("TAKE A BREAK", 160)
	retreat.pressed.connect(SceneNavigator.go_to_main_menu)
	header.add_child(retreat)
	var enemy_panel := PanelContainer.new()
	enemy_panel.custom_minimum_size.y = 118
	root_stack.add_child(enemy_panel)
	var enemy_row := HBoxContainer.new()
	enemy_row.add_theme_constant_override("separation", 14)
	enemy_panel.add_child(enemy_row)
	_enemy_artwork = TextureRect.new()
	_enemy_artwork.name = "EnemyArtwork"
	_enemy_artwork.custom_minimum_size = Vector2(88, 88)
	_enemy_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_enemy_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_enemy_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_row.add_child(_enemy_artwork)
	var enemy_identity := VBoxContainer.new()
	enemy_identity.custom_minimum_size.x = 330
	enemy_row.add_child(enemy_identity)
	_enemy_name = AppTheme.heading("ABLEISM MONSTER", 24, AppTheme.DANGER_TEXT)
	enemy_identity.add_child(_enemy_name)
	_enemy_description = Label.new()
	_enemy_description.custom_minimum_size.x = 330
	_enemy_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_enemy_description.add_theme_font_size_override("font_size", 13)
	_enemy_description.add_theme_color_override("font_color", AppTheme.SECONDARY_TEXT)
	enemy_identity.add_child(_enemy_description)
	_intent_label = Label.new()
	_intent_label.add_theme_color_override("font_color", AppTheme.GOLD_TEXT)
	enemy_identity.add_child(_intent_label)
	_enemy_health = ProgressBar.new()
	_enemy_health.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_health.custom_minimum_size.y = 38
	_enemy_health.show_percentage = false
	enemy_row.add_child(_enemy_health)
	_player_label = AppTheme.heading("TEAM HEART 30 / 30", 20)
	_player_label.custom_minimum_size.x = 230
	_player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	enemy_row.add_child(_player_label)
	var center_row := HBoxContainer.new()
	center_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_row.add_theme_constant_override("separation", 12)
	root_stack.add_child(center_row)
	var board_panel := PanelContainer.new()
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_row.add_child(board_panel)
	var board_stack := VBoxContainer.new()
	board_stack.add_theme_constant_override("separation", 6)
	board_panel.add_child(board_stack)
	var board_heading := Label.new()
	board_heading.text = "ALLY CIRCLE  •  Allies help automatically at the start of each round"
	board_heading.add_theme_font_size_override("font_size", 14)
	board_heading.add_theme_color_override("font_color", AppTheme.SECONDARY_TEXT)
	board_stack.add_child(board_heading)
	var board_scroll := ScrollContainer.new()
	board_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	board_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board_stack.add_child(board_scroll)
	_board_container = HBoxContainer.new()
	_board_container.add_theme_constant_override("separation", 10)
	board_scroll.add_child(_board_container)
	var log_panel := PanelContainer.new()
	log_panel.custom_minimum_size.x = 310
	center_row.add_child(log_panel)
	var log_stack := VBoxContainer.new()
	log_panel.add_child(log_stack)
	var log_heading := Label.new()
	log_heading.text = "STORY SO FAR"
	log_heading.add_theme_font_size_override("font_size", 14)
	log_heading.add_theme_color_override("font_color", AppTheme.ACCENT_TEXT)
	log_stack.add_child(log_heading)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_active = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 14)
	log_stack.add_child(_log)
	var controls := HBoxContainer.new()
	controls.custom_minimum_size.y = 48
	root_stack.add_child(controls)
	_energy_label = AppTheme.heading("SPARK 0 / 5", 22, AppTheme.ACCENT)
	_energy_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(_energy_label)
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toast.add_theme_color_override("font_color", AppTheme.SECONDARY_TEXT)
	controls.add_child(_toast)
	_piles_label = Label.new()
	_piles_label.add_theme_color_override("font_color", AppTheme.SECONDARY_TEXT)
	controls.add_child(_piles_label)
	_end_turn_button = AppTheme.button("END ROUND →", 170)
	_end_turn_button.pressed.connect(controller.request_end_turn)
	controls.add_child(_end_turn_button)
	var hand_panel := PanelContainer.new()
	hand_panel.custom_minimum_size.y = 212
	root_stack.add_child(hand_panel)
	var hand_stack := VBoxContainer.new()
	hand_stack.add_theme_constant_override("separation", 4)
	hand_panel.add_child(hand_stack)
	var hand_heading := Label.new()
	hand_heading.text = "YOUR HAND  •  Choose an ally card to play it"
	hand_heading.add_theme_font_size_override("font_size", 14)
	hand_heading.add_theme_color_override("font_color", AppTheme.SECONDARY_TEXT)
	hand_stack.add_child(hand_heading)
	var hand_scroll := ScrollContainer.new()
	hand_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_stack.add_child(hand_scroll)
	_hand_container = HBoxContainer.new()
	_hand_container.add_theme_constant_override("separation", 10)
	hand_scroll.add_child(_hand_container)
	_build_result_layer()
	_build_damage_overlay_layer()


func _build_damage_overlay_layer() -> void:
	_damage_overlay_layer = CanvasLayer.new()
	_damage_overlay_layer.name = "DamageNumberLayer"
	_damage_overlay_layer.layer = 90
	add_child(_damage_overlay_layer)
	_damage_overlay_root = Control.new()
	_damage_overlay_root.name = "DamageNumbers"
	_damage_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_overlay_layer.add_child(_damage_overlay_root)


func _build_result_layer() -> void:
	_result_layer = Control.new()
	_result_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_layer.visible = false
	add_child(_result_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.294, 0.192, 0.353, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(470, 280)
	center.add_child(panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 18)
	panel.add_child(stack)
	_result_title = AppTheme.heading("BARRIER BUSTED!", 42, AppTheme.ACCENT)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(_result_title)
	_result_body = Label.new()
	_result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_body.add_theme_color_override("font_color", AppTheme.SECONDARY_TEXT)
	stack.add_child(_result_body)
	var retry := AppTheme.button("TRY ANOTHER MONSTER", 270)
	retry.pressed.connect(func(): get_tree().reload_current_scene())
	stack.add_child(retry)
	var home := AppTheme.button("BACK TO THE COZY CORNER", 270)
	home.pressed.connect(SceneNavigator.go_to_main_menu)
	stack.add_child(home)


func _start_battle() -> void:
	var errors := ProfileStore.selected_deck_errors()
	if not errors.is_empty():
		_show_blocking_error("DECK NEEDS A LITTLE HELP", "\n".join(errors))
		return
	var enemy := CardCatalog.get_random_enemy()
	if enemy == null:
		_show_blocking_error("MONSTER TAKING A BREAK", "No ableism monster is ready for an adventure yet.")
		return
	var rules: BattleRules = load("res://battle/rules/battle_rules.tres")
	controller.start_battle(ProfileStore.get_selected_deck_definitions(), enemy, rules)


func get_enemy_portrait_texture() -> Texture2D:
	return _enemy_artwork.texture if _enemy_artwork != null else null


func get_enemy_description_text() -> String:
	return _enemy_description.text if _enemy_description != null else ""


func _refresh() -> void:
	if controller.session == null:
		return
	var session := controller.session
	_turn_label.text = "ROUND %d  •  %s" % [session.turn_number, session.phase_name().to_upper().replace("_", " ")]
	_player_label.text = "TEAM HEART  %d / %d" % [session.player_health, session.rules.player_starting_health]
	_player_label.add_theme_color_override("font_color", AppTheme.DANGER_TEXT if session.player_health <= 10 else AppTheme.INK)
	_enemy_name.text = session.enemy.definition.display_name.to_upper()
	_enemy_artwork.texture = session.enemy.definition.artwork if session.enemy.definition.artwork != null else load("res://icon.svg")
	_enemy_artwork.tooltip_text = session.enemy.definition.description
	_enemy_description.text = session.enemy.definition.description
	_enemy_health.max_value = session.enemy.definition.maximum_health
	_enemy_health.value = session.enemy.current_health
	_enemy_health.tooltip_text = "%d / %d monster Heart" % [session.enemy.current_health, session.enemy.definition.maximum_health]
	_intent_label.text = controller.get_enemy_intent()
	_energy_label.text = "SPARK  %d / %d" % [session.current_energy, session.rules.energy_per_turn]
	_piles_label.text = "DECK %d  •  REST PILE %d  •  HAND %d / %d     " % [
		session.draw_pile.size(),
		session.discard_pile.size(),
		session.hand.size(),
		session.rules.maximum_hand_size,
	]
	_end_turn_button.disabled = controller.input_locked or session.phase != BattleSession.Phase.PLAYER_TURN
	_card_views_by_instance.clear()
	_rebuild_cards(_board_container, session.battlefield, true)
	_rebuild_cards(_hand_container, session.hand, false)
	if session.is_finished():
		_result_layer.visible = true
		var won := session.phase == BattleSession.Phase.VICTORY
		_result_title.text = "BARRIER BUSTED!" if won else "TIME FOR A REST"
		_result_title.add_theme_color_override("font_color", AppTheme.ACCENT_TEXT if won else AppTheme.DANGER_TEXT)
		_result_body.text = "%s's barriers came tumbling down. Great teamwork!" % session.enemy.definition.display_name if won else "The team needs a rest after round %d. A new plan and a snack can help." % session.turn_number


func _rebuild_cards(container: HBoxContainer, cards: Array[CardInstance], on_board: bool) -> void:
	for child in container.get_children():
		if child is CardBase and child.instance != null:
			_last_card_artwork_rects[child.instance.instance_id] = child.get_artwork_global_rect()
		container.remove_child(child)
		child.queue_free()
	if cards.is_empty():
		var empty := Label.new()
		empty.text = "The Ally Circle has room for a friend." if on_board else "Your hand is empty for now."
		empty.add_theme_color_override("font_color", AppTheme.SECONDARY_TEXT)
		empty.custom_minimum_size = Vector2(180, 120)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		container.add_child(empty)
		return
	for card in cards:
		var view: CardBase = CARD_BASE_SCENE.instantiate()
		var available := controller.can_attack_enemy(card.instance_id) if on_board else controller.can_play_card(card.instance_id)
		var footer := "READY TO HELP" if on_board and available else ""
		view.setup_instance(card, footer)
		view.set_compact()
		view.set_interactive(available)
		view.card_activated.connect(controller.request_attack_enemy if on_board else controller.request_play_card)
		container.add_child(view)
		_card_views_by_instance[card.instance_id] = view


func _on_event_presented(event: BattleEvent) -> void:
	var message := _event_message(event)
	if not message.is_empty():
		_log.append_text("• %s\n" % message)
	match event.kind:
		&"EnemyActionStarted": _animate_attacker(_enemy_artwork)
		&"DamageApplied":
			_show_damage_number(event)
			if event.data.target == "enemy":
				_pulse(_enemy_health, AppTheme.DANGER)
			elif event.data.target == "player":
				_pulse(_player_label, AppTheme.DANGER)
			else:
				_pulse(_board_container, AppTheme.DANGER)
		&"HealingApplied": _pulse(_player_label, AppTheme.ACCENT)
		&"CardDrawn": _pulse(_hand_container, AppTheme.ACCENT)
		&"UnitAttacked":
			var attacker: CardBase = _card_views_by_instance.get(int(event.data.get("instance_id", -1)))
			_animate_attacker(attacker)
			_pulse(_board_container, AppTheme.GOLD)


func _animate_attacker(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE
	control.z_index = 30
	var tween := control.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2(1.16, 1.16), 0.12)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.16)
	tween.tween_callback(func():
		if is_instance_valid(control):
			control.z_index = 0
	)


func _show_damage_number(event: BattleEvent) -> void:
	if _damage_overlay_root == null or int(event.data.get("amount", 0)) <= 0:
		return
	var target_rect := Rect2()
	match str(event.data.get("target", "")):
		"enemy":
			target_rect = _enemy_artwork.get_global_rect()
		"player":
			target_rect = _player_label.get_global_rect()
		"unit":
			var instance_id := int(event.data.get("instance_id", -1))
			var card_view: CardBase = _card_views_by_instance.get(instance_id)
			if card_view != null and is_instance_valid(card_view):
				target_rect = card_view.get_artwork_global_rect()
			else:
				target_rect = _last_card_artwork_rects.get(instance_id, _board_container.get_global_rect())
	if target_rect.size == Vector2.ZERO:
		return
	var number := Label.new()
	number.text = "-%d" % int(event.data.amount)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.position = target_rect.position
	number.size = target_rect.size
	number.pivot_offset = target_rect.size * 0.5
	number.add_theme_font_override("font", AppTheme.FREDOKA)
	number.add_theme_font_size_override("font_size", 78)
	number.add_theme_color_override("font_color", AppTheme.DANGER)
	number.add_theme_color_override("font_outline_color", AppTheme.SURFACE)
	number.add_theme_constant_override("outline_size", 11)
	number.scale = Vector2(0.45, 0.45)
	_damage_overlay_root.add_child(number)
	var tween := number.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "scale", Vector2(1.12, 1.12), 0.30)
	tween.tween_property(number, "position:y", number.position.y - 48.0, 0.95)
	tween.tween_property(number, "modulate:a", 0.0, 0.85).set_delay(0.50)
	tween.chain().tween_callback(number.queue_free)


func _event_message(event: BattleEvent) -> String:
	match event.kind:
		&"BattleStarted": return "A barrier appeared: [color=#A52E57]%s[/color]." % event.data.enemy_name
		&"TurnStarted": return "[color=#176B59]Round %d started.[/color]" % event.data.turn
		&"CardDrawn": return "%s joined your hand." % event.data.name
		&"CardPlayed": return "[color=#A56716]%s[/color] joined the adventure." % event.data.name
		&"UnitAttacked": return "%s helped for %d Power." % [event.data.name, event.data.amount]
		&"EnemyActionStarted": return "The monster made a barrier: %s." % event.data.description
		&"DamageApplied":
			if event.data.target == "unit":
				return "%s lost %d Heart." % [event.data.name, event.data.amount]
			return "%s lost %d Heart." % ["The monster" if event.data.target == "enemy" else "The team", event.data.amount]
		&"HealingApplied": return "%s restored %d Heart." % ["The team" if event.data.target == "player" else "The monster", event.data.amount]
		&"CardDestroyed": return "[color=#A52E57]%s needs a rest.[/color]" % event.data.name
		&"DiscardReshuffled": return "The rest pile became a fresh deck."
		&"CardBurned": return "%s moved to the rest pile because your hand is full." % event.data.name
		&"BattleEnded": return "[color=#176B59]Barrier busted![/color]" if event.data.result == "victory" else "[color=#A52E57]The team needs a rest.[/color]"
	return ""


func _show_message(message: String) -> void:
	_toast.text = message
	_toast.add_theme_color_override("font_color", AppTheme.DANGER_TEXT)


func _show_blocking_error(title: String, body: String) -> void:
	_result_layer.visible = true
	_result_title.text = title.to_upper()
	_result_title.add_theme_color_override("font_color", AppTheme.DANGER_TEXT)
	_result_body.text = body


func _pulse(control: CanvasItem, color: Color) -> void:
	control.modulate = color
	var tween := create_tween()
	tween.tween_property(control, "modulate", Color.WHITE, 0.18)
