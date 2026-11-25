extends Control

const CARD_BASE_SCENE := preload("res://ui/card_base.tscn")
const SPARK_AVAILABLE_TEXTURE: Texture2D = preload("res://battle/art/spark_available.png")
const SPARK_SPENT_TEXTURE: Texture2D = preload("res://battle/art/spark_spent.png")
const CAST_SECONDS := 0.16

## Default projectile styles and pacing for attacks shown in this battle.
@export var projectile_config: ProjectilePresentationConfig = preload("res://battle/projectiles/default_projectile_config.tres")
## -1 follows the saved profile setting; 0 or 1 forces reduce motion off or on (tests, previews).
@export_range(-1, 1) var reduce_motion_override: int = -1

@onready var controller: BattleController = $BattleController

var _turn_label: Label
var _player_health: ProgressBar
var _player_health_text: Label
var _spark_row: HBoxContainer
var _spark_icons: Array[TextureRect] = []
var _enemy_name: Label
var _enemy_status: Label
var _enemy_artwork: TextureRect
var _enemy_description: Label
var _enemy_health: ProgressBar
var _enemy_health_text: Label
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
var _cast_root: Control
var _presenter: ProjectilePresenter
## Played cards hovering above the hand while their effects resolve, by instance ID.
var _cast_views: Dictionary = {}
var _card_views_by_instance: Dictionary = {}
var _last_card_artwork_rects: Dictionary = {}
var _campaign_node: String = ""
var _victory_saved := false
var _save_attempted := false
var _retry_button: Button
var _home_button: Button
var _retreat_button: Button


func _ready() -> void:
	_campaign_node = SceneNavigator.campaign_encounter
	theme = AppTheme.create_theme()
	AppTheme.make_background(self)
	_build_ui()
	_build_presenter()
	controller.session_changed.connect(_refresh)
	controller.input_lock_changed.connect(_on_input_lock_changed)
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
	_retreat_button = retreat
	retreat.pressed.connect(_leave_battle)
	header.add_child(retreat)
	var enemy_panel := PanelContainer.new()
	enemy_panel.name = "EnemyEncounterPanel"
	enemy_panel.custom_minimum_size.y = 292
	enemy_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_stack.add_child(enemy_panel)
	var enemy_row := HBoxContainer.new()
	enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_row.add_theme_constant_override("separation", 22)
	enemy_panel.add_child(enemy_row)
	_enemy_artwork = TextureRect.new()
	_enemy_artwork.name = "EnemyArtwork"
	_enemy_artwork.custom_minimum_size = Vector2(240, 240)
	_enemy_artwork.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_enemy_artwork.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_enemy_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_enemy_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_enemy_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_row.add_child(_enemy_artwork)
	var encounter_details := VBoxContainer.new()
	encounter_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encounter_details.alignment = BoxContainer.ALIGNMENT_CENTER
	encounter_details.add_theme_constant_override("separation", 12)
	enemy_row.add_child(encounter_details)
	var enemy_header := HBoxContainer.new()
	encounter_details.add_child(enemy_header)
	_enemy_name = AppTheme.heading("ABLEISM MONSTER", 32, AppTheme.DANGER_TEXT)
	_enemy_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_header.add_child(_enemy_name)
	_enemy_description = Label.new()
	_enemy_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_enemy_description.add_theme_font_size_override("font_size", 18)
	_enemy_description.add_theme_color_override("font_color", AppTheme.SECONDARY_TEXT)
	encounter_details.add_child(_enemy_description)
	_intent_label = Label.new()
	_intent_label.add_theme_font_size_override("font_size", 19)
	_intent_label.add_theme_color_override("font_color", AppTheme.GOLD_TEXT)
	encounter_details.add_child(_intent_label)
	_enemy_status = Label.new()
	_enemy_status.name = "MonsterStatusBadge"
	_enemy_status.add_theme_font_size_override("font_size", 19)
	_enemy_status.add_theme_color_override("font_color", AppTheme.ACCENT_TEXT)
	_enemy_status.tooltip_text = "Calm lowers the monster's next barrier damage. Exposed adds to the next hit it takes."
	_enemy_status.mouse_filter = Control.MOUSE_FILTER_PASS
	_enemy_status.visible = false
	encounter_details.add_child(_enemy_status)
	var health_heading := Label.new()
	health_heading.text = "MONSTER HEALTH"
	health_heading.add_theme_font_size_override("font_size", 14)
	health_heading.add_theme_color_override("font_color", AppTheme.DANGER_TEXT)
	encounter_details.add_child(health_heading)
	var enemy_health_overlay := Control.new()
	enemy_health_overlay.custom_minimum_size.y = 44
	encounter_details.add_child(enemy_health_overlay)
	_enemy_health = ProgressBar.new()
	_enemy_health.name = "MonsterHealthBar"
	_enemy_health.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_enemy_health.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_health.show_percentage = false
	_enemy_health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_health_overlay.add_child(_enemy_health)
	_enemy_health_text = Label.new()
	_enemy_health_text.name = "MonsterHealthText"
	_enemy_health_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_enemy_health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_health_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_enemy_health_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enemy_health_text.add_theme_font_size_override("font_size", 21)
	_enemy_health_text.add_theme_color_override("font_color", AppTheme.INK)
	enemy_health_overlay.add_child(_enemy_health_text)
	var center_row := HBoxContainer.new()
	center_row.name = "PlayerBoardRow"
	center_row.custom_minimum_size.y = 242
	center_row.size_flags_vertical = Control.SIZE_FILL
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
	var spark_group := HBoxContainer.new()
	spark_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spark_group.add_theme_constant_override("separation", 10)
	controls.add_child(spark_group)
	var spark_label := AppTheme.heading("SPARK", 20, AppTheme.ACCENT_TEXT)
	spark_group.add_child(spark_label)
	_spark_row = HBoxContainer.new()
	_spark_row.name = "SparkIconRow"
	_spark_row.add_theme_constant_override("separation", 3)
	spark_group.add_child(_spark_row)
	_set_spark_icon_count(5)
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
	var player_health_stack := VBoxContainer.new()
	player_health_stack.name = "TeamHeartSection"
	player_health_stack.add_theme_constant_override("separation", 3)
	root_stack.add_child(player_health_stack)
	var player_health_heading := Label.new()
	player_health_heading.text = "TEAM HEART"
	player_health_heading.add_theme_font_size_override("font_size", 14)
	player_health_heading.add_theme_color_override("font_color", AppTheme.ACCENT_TEXT)
	player_health_stack.add_child(player_health_heading)
	var player_health_overlay := Control.new()
	player_health_overlay.custom_minimum_size.y = 42
	player_health_stack.add_child(player_health_overlay)
	_player_health = ProgressBar.new()
	_player_health.name = "TeamHeartBar"
	_player_health.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_player_health.show_percentage = false
	_player_health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_health.add_theme_stylebox_override("fill", AppTheme.style_box(AppTheme.ACCENT, AppTheme.ACCENT_TEXT, 12, 2, 0))
	player_health_overlay.add_child(_player_health)
	_player_health_text = Label.new()
	_player_health_text.name = "TeamHeartText"
	_player_health_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_player_health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_health_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_player_health_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_health_text.add_theme_font_size_override("font_size", 21)
	_player_health_text.add_theme_color_override("font_color", AppTheme.INK)
	player_health_overlay.add_child(_player_health_text)
	var hand_panel := PanelContainer.new()
	hand_panel.name = "PlayerHandPanel"
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


func _set_spark_icon_count(icon_count: int) -> void:
	while _spark_icons.size() < icon_count:
		var index := _spark_icons.size()
		var icon := TextureRect.new()
		icon.name = "Spark%d" % (index + 1)
		icon.custom_minimum_size = Vector2(42, 42)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = SPARK_SPENT_TEXTURE
		_spark_row.add_child(icon)
		_spark_icons.append(icon)
	while _spark_icons.size() > icon_count:
		var icon := _spark_icons.pop_back() as TextureRect
		_spark_row.remove_child(icon)
		icon.queue_free()


func _build_damage_overlay_layer() -> void:
	_damage_overlay_layer = CanvasLayer.new()
	_damage_overlay_layer.name = "DamageNumberLayer"
	_damage_overlay_layer.layer = 90
	add_child(_damage_overlay_layer)
	# Cast cards sit below projectiles, which sit below damage numbers.
	_cast_root = Control.new()
	_cast_root.name = "CastCards"
	_cast_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cast_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_overlay_layer.add_child(_cast_root)
	_damage_overlay_root = Control.new()
	_damage_overlay_root.name = "DamageNumbers"
	_damage_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_overlay_layer.add_child(_damage_overlay_root)


func _build_presenter() -> void:
	_presenter = ProjectilePresenter.new()
	_presenter.name = "ProjectilePresenter"
	_presenter.config = projectile_config
	_presenter.controller = controller
	_presenter.locate = _endpoint_rect
	_presenter.reduce_motion = ProfileStore.reduce_motion if reduce_motion_override < 0 else reduce_motion_override == 1
	add_child(_presenter)
	var projectile_overlay := Control.new()
	projectile_overlay.name = "ProjectileOverlay"
	projectile_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	projectile_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_overlay_layer.add_child(projectile_overlay)
	_damage_overlay_layer.move_child(projectile_overlay, _damage_overlay_root.get_index())
	_presenter.attach_overlay(projectile_overlay)
	_presenter.event_landed.connect(_on_event_landed)
	controller.presenter = _presenter


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
	_retry_button = retry
	retry.pressed.connect(_retry)
	stack.add_child(retry)
	var home := AppTheme.button("BACK TO THE COZY CORNER", 270)
	_home_button = home
	home.pressed.connect(_leave_battle)
	stack.add_child(home)
	if not _campaign_node.is_empty():
		retry.text = "RETRY ENCOUNTER"
		home.text = "RETURN TO CAMPAIGN"


func _start_battle() -> void:
	var errors := ProfileStore.selected_deck_errors()
	if not errors.is_empty():
		_show_blocking_error("DECK NEEDS A LITTLE HELP", "\n".join(errors))
		return
	var enemy: EnemyDefinition
	if _campaign_node.is_empty():
		enemy = CardCatalog.get_random_enemy()
	else:
		if ProfileStore.campaign == null or ProfileStore.campaign.committed != _campaign_node:
			_show_blocking_error("ENCOUNTER UNAVAILABLE", "Return to Campaign and choose an available encounter.")
			_retry_button.visible = false
			return
		enemy = CampaignDefinition.current().enemy_variant(_campaign_node)
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
	_show_team_heart(session.player_health)
	_enemy_name.text = session.enemy.definition.display_name.to_upper()
	_enemy_artwork.texture = session.enemy.definition.artwork if session.enemy.definition.artwork != null else load("res://icon.svg")
	_enemy_artwork.tooltip_text = session.enemy.definition.description
	_enemy_description.text = session.enemy.definition.description
	_show_monster_heart(session.enemy.current_health)
	_intent_label.text = controller.get_enemy_intent()
	_enemy_status.text = enemy_status_text(session.enemy)
	_enemy_status.visible = not _enemy_status.text.is_empty()
	_refresh_board(session)


func _show_team_heart(current: int) -> void:
	var maximum := controller.session.rules.player_starting_health
	_player_health.max_value = maximum
	_player_health.value = current
	_player_health_text.text = "%d / %d" % [current, maximum]
	_player_health.tooltip_text = "%d / %d Team Heart" % [current, maximum]
	var low_team_heart := current <= 10
	_player_health.add_theme_stylebox_override(
		"fill",
		AppTheme.style_box(
			AppTheme.DANGER if low_team_heart else AppTheme.ACCENT,
			AppTheme.DANGER_TEXT if low_team_heart else AppTheme.ACCENT_TEXT,
			12,
			2,
			0
		)
	)
	_player_health_text.add_theme_color_override("font_color", AppTheme.SURFACE if low_team_heart else AppTheme.INK)


func _show_monster_heart(current: int) -> void:
	var maximum := controller.session.enemy.definition.maximum_health
	_enemy_health.max_value = maximum
	_enemy_health.value = current
	_enemy_health_text.text = "%d / %d" % [current, maximum]
	_enemy_health.tooltip_text = "%d / %d monster Heart" % [current, maximum]


func _refresh_board(session: BattleSession) -> void:
	_clear_cast_views()
	_refresh_spark_icons(session.current_energy, session.rules.energy_per_turn)
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
		if not _campaign_node.is_empty():
			_refresh_campaign_result(won)


func _refresh_campaign_result(won: bool) -> void:
	if not won:
		_retry_button.text = "RETRY ENCOUNTER"
		return
	if not _save_attempted:
		_save_attempted = true
		_victory_saved = ProfileStore.complete_campaign_encounter(_campaign_node)
	_home_button.disabled = not _victory_saved
	_retreat_button.disabled = not _victory_saved
	_retry_button.visible = not _victory_saved
	if not _victory_saved:
		_retry_button.text = "RETRY SAVING VICTORY"
		_result_title.text = "VICTORY NOT SAVED YET"
		_result_body.text = ProfileStore.last_save_error + "\nKeep this battle open and retry saving."
	elif _campaign_node == CampaignDefinition.current().final_id:
		_result_title.text = "CAMPAIGN COMPLETE!"
		_result_body.text = "Every barrier on your route overcome together! Your completed zoo route is saved."
	else:
		_result_body.text += "\nRoute saved. Your next connected encounters are ready."


func _retry() -> void:
	if not _campaign_node.is_empty() and controller.session != null and controller.session.phase == BattleSession.Phase.VICTORY:
		_save_attempted = false
		_refresh()
		return
	get_tree().reload_current_scene()


func _leave_battle() -> void:
	if not _campaign_node.is_empty():
		if controller.session != null and controller.session.phase == BattleSession.Phase.VICTORY and not _victory_saved:
			return
		SceneNavigator.go_to(SceneNavigator.CAMPAIGN)
	else:
		SceneNavigator.go_to_main_menu()


func _refresh_spark_icons(current_spark: int, maximum_spark: int) -> void:
	var displayed_spark := maxi(current_spark, maximum_spark)
	_set_spark_icon_count(displayed_spark)
	_spark_row.tooltip_text = (
		"%d Spark available (%d base + %d bonus)" \
		% [current_spark, maximum_spark, current_spark - maximum_spark]
		if current_spark > maximum_spark
		else "%d of %d Spark available" % [current_spark, maximum_spark]
	)
	for index in _spark_icons.size():
		var available := index < current_spark
		_spark_icons[index].texture = SPARK_AVAILABLE_TEXTURE if available else SPARK_SPENT_TEXTURE
		_spark_icons[index].tooltip_text = "Available Spark" if available else "Spent Spark"


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
		container.add_child(_create_card_view(card, on_board))


func _create_card_view(card: CardInstance, on_board: bool) -> CardBase:
	var view: CardBase = CARD_BASE_SCENE.instantiate()
	var available := controller.can_attack_enemy(card.instance_id) if on_board else controller.can_play_card(card.instance_id)
	var footer := ally_footer_text(card, available) if on_board else ""
	view.setup_instance(card, footer)
	view.set_compact()
	view.set_battlefield_health_bar(on_board)
	view.set_interactive(available)
	view.card_activated.connect(controller.request_attack_enemy if on_board else controller.request_play_card)
	_card_views_by_instance[card.instance_id] = view
	return view


static func enemy_status_text(enemy: EnemyInstance) -> String:
	if enemy == null:
		return ""
	return status_text(enemy.calm, enemy.exposed)


static func status_text(calm: int, exposed: int) -> String:
	var parts: PackedStringArray = []
	if calm > 0:
		parts.append("CALM %d" % calm)
	if exposed > 0:
		parts.append("EXPOSED %d" % exposed)
	return "  •  ".join(parts)


static func ally_footer_text(card: CardInstance, ready_to_help: bool) -> String:
	var parts: PackedStringArray = []
	if card.shield > 0:
		parts.append("SHIELD %d" % card.shield)
	if ready_to_help:
		parts.append("READY TO HELP")
	return " • ".join(parts)


## Shows an event's effect. Hits arrive here when their projectile lands; everything
## else as it is presented. The full refresh after the queue makes the final state exact.
func _on_event_landed(event: BattleEvent, style: ProjectileStyle) -> void:
	var message := _event_message(event)
	if not message.is_empty():
		_log.append_text("• %s\n" % message)
	var impact_color := style.impact_color if style != null else AppTheme.DANGER
	match event.kind:
		&"BattleStarted": _refresh()
		&"TurnStarted":
			_turn_label.text = "ROUND %d  •  PLAYER TURN" % int(event.data.turn)
			_refresh_spark_icons(int(event.data.energy), controller.session.rules.energy_per_turn)
		&"EnergyChanged":
			_refresh_spark_icons(int(event.data.energy), controller.session.rules.energy_per_turn)
		&"EnemyActionStarted": _animate_attacker(_enemy_artwork)
		&"DamageApplied":
			_show_damage_number(event)
			match str(event.data.get("target", "")):
				"enemy":
					_show_monster_heart(int(event.data.health))
					_pulse(_enemy_health, AppTheme.DANGER)
					_shake(_enemy_artwork)
					_pulse(_enemy_artwork, impact_color)
				"player":
					_show_team_heart(int(event.data.health))
					_pulse(_player_health, AppTheme.DANGER)
				_:
					var target := _card_view(int(event.data.get("instance_id", -1)))
					if target != null:
						target.show_health(int(event.data.health))
						_shake(target)
						_pulse(target, impact_color)
					else:
						_pulse(_board_container, AppTheme.DANGER)
		&"HealingApplied":
			match str(event.data.get("target", "")):
				"enemy":
					_show_monster_heart(int(event.data.health))
					_pulse(_enemy_health, AppTheme.ACCENT)
				"unit":
					var ally := _card_view(int(event.data.get("instance_id", -1)))
					if ally != null:
						ally.show_health(int(event.data.health))
					_pulse(ally if ally != null else _board_container, AppTheme.ACCENT)
				_:
					_show_team_heart(int(event.data.health))
					_pulse(_player_health, AppTheme.ACCENT)
		&"ShieldAbsorbed":
			var shielded := _card_view(int(event.data.get("instance_id", -1)))
			if shielded != null:
				_pulse(shielded, ProjectilePresenter.SHIELD_COLOR)
		&"CardDrawn", &"CardCreated":
			_add_hand_view(int(event.data.get("instance_id", -1)))
			_pulse(_hand_container, AppTheme.ACCENT)
		&"CardPlayed": _begin_cast(int(event.data.instance_id))
		&"UnitSummoned": _summon_from_cast(int(event.data.instance_id))
		&"CardDiscarded": _end_cast(int(event.data.instance_id))
		&"CardDestroyed": _remove_board_view(int(event.data.instance_id))
		&"EnemyStatusChanged":
			_enemy_status.text = status_text(int(event.data.calm), int(event.data.exposed))
			_enemy_status.visible = not _enemy_status.text.is_empty()
			_pulse(_enemy_status, AppTheme.GOLD)
		&"UnitAttacked":
			_animate_attacker(_card_view(int(event.data.get("instance_id", -1))))
			_pulse(_board_container, AppTheme.GOLD)


func _on_input_lock_changed(locked: bool) -> void:
	if not locked:
		return
	# Keep the board as it was while events play out; only stop interaction.
	_end_turn_button.disabled = true
	for view in _card_views_by_instance.values():
		if is_instance_valid(view):
			view.set_interactive(false)


func _card_view(instance_id: int) -> CardBase:
	var view: CardBase = _card_views_by_instance.get(instance_id)
	return view if view != null and is_instance_valid(view) and not view.is_queued_for_deletion() else null


## Global rect of a presentation endpoint, falling back to where a card was last seen.
func _endpoint_rect(endpoint: Dictionary) -> Rect2:
	var instance_id := int(endpoint.get("instance_id", -1))
	match str(endpoint.get("kind", "")):
		"enemy":
			return _enemy_artwork.get_global_rect()
		"player":
			return _player_health.get_global_rect()
		"card":
			var cast: CardBase = _cast_views.get(instance_id)
			if cast != null and is_instance_valid(cast):
				return Rect2(cast.get_meta("cast_spot", cast.position), cast.size)
	var view := _card_view(instance_id)
	if view != null:
		return view.get_artwork_global_rect()
	if _last_card_artwork_rects.has(instance_id):
		return _last_card_artwork_rects[instance_id]
	return _board_container.get_global_rect()


func _remove_placeholders(container: Container) -> void:
	for child in container.get_children():
		if not child is CardBase:
			container.remove_child(child)
			child.queue_free()


func _add_hand_view(instance_id: int) -> void:
	if _card_view(instance_id) != null or controller.session == null:
		return
	var card := controller.session.find_hand_card(instance_id)
	if card == null:
		return
	_remove_placeholders(_hand_container)
	var view := _create_card_view(card, false)
	view.set_interactive(false)
	_hand_container.add_child(view)


## Lifts a played card above the hand, where its effects launch from until it settles.
func _begin_cast(instance_id: int) -> void:
	var hand_view := _card_view(instance_id)
	if hand_view == null or hand_view.instance == null:
		return
	var played := hand_view.instance
	var start := hand_view.get_global_rect()
	_last_card_artwork_rects[instance_id] = hand_view.get_artwork_global_rect()
	_card_views_by_instance.erase(instance_id)
	hand_view.get_parent().remove_child(hand_view)
	hand_view.queue_free()
	var cast: CardBase = CARD_BASE_SCENE.instantiate()
	cast.setup_instance(played)
	cast.set_compact()
	cast.hover_preview_enabled = false
	cast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cast_root.add_child(cast)
	cast.size = cast.get_combined_minimum_size()
	var hand_area := _hand_container.get_parent_control().get_global_rect()
	var spot := Vector2(hand_area.get_center().x - cast.size.x * 0.5, hand_area.position.y - cast.size.y - 16.0)
	cast.set_meta("cast_spot", spot)
	_cast_views[instance_id] = cast
	if _presenter.reduce_motion:
		cast.position = spot
		return
	cast.position = start.position
	var tween := cast.create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(cast, "position", spot, CAST_SECONDS)


func _summon_from_cast(instance_id: int) -> void:
	_free_cast_view(instance_id)
	if _card_view(instance_id) != null or controller.session == null:
		return
	var card := controller.session.find_battlefield_card(instance_id)
	if card == null:
		return
	_remove_placeholders(_board_container)
	var view := _create_card_view(card, true)
	view.set_interactive(false)
	_board_container.add_child(view)


func _end_cast(instance_id: int) -> void:
	var cast: CardBase = _cast_views.get(instance_id)
	_cast_views.erase(instance_id)
	if cast == null or not is_instance_valid(cast):
		return
	var tween := cast.create_tween()
	tween.set_parallel(true)
	tween.tween_property(cast, "modulate:a", 0.0, 0.25)
	tween.tween_property(cast, "position:y", cast.position.y + 40.0, 0.25)
	tween.chain().tween_callback(cast.queue_free)


func _free_cast_view(instance_id: int) -> void:
	var cast: CardBase = _cast_views.get(instance_id)
	_cast_views.erase(instance_id)
	if cast != null and is_instance_valid(cast):
		cast.queue_free()


func _clear_cast_views() -> void:
	for instance_id in _cast_views.keys():
		_free_cast_view(instance_id)


func _remove_board_view(instance_id: int) -> void:
	var view := _card_view(instance_id)
	if view == null:
		return
	_last_card_artwork_rects[instance_id] = view.get_artwork_global_rect()
	_card_views_by_instance.erase(instance_id)
	var tween := view.create_tween()
	tween.tween_property(view, "modulate:a", 0.0, 0.25)
	tween.tween_callback(view.queue_free)


## A quick side-to-side wobble; rotation is safe on controls placed by containers.
func _shake(control: Control) -> void:
	if control == null or not is_instance_valid(control) or _presenter.reduce_motion:
		return
	control.pivot_offset = control.size * 0.5
	var tween := control.create_tween()
	for angle in [0.06, -0.05, 0.03, 0.0]:
		tween.tween_property(control, "rotation", angle, 0.05)


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
			target_rect = _player_health.get_global_rect()
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
		&"HealingApplied":
			if event.data.target == "unit":
				return "%s restored %d Heart." % [event.data.name, event.data.amount]
			return "%s restored %d Heart." % ["The team" if event.data.target == "player" else "The monster", event.data.amount]
		&"ShieldGained": return "%s gained Shield %d." % [event.data.name, event.data.amount]
		&"ShieldAbsorbed": return "%s's Shield blocked %d." % [event.data.name, event.data.amount]
		&"UnitAttackChanged": return "%s now has %d Power." % [event.data.get("name", "An ally"), event.data.attack]
		&"CalmUsed": return "[color=#176B59]Calm softened the barrier by %d.[/color]" % event.data.amount
		&"ExposedUsed": return "[color=#A56716]Exposed added %d damage![/color]" % event.data.amount
		&"SparkBanked": return "%d Spark saved for next round." % event.data.amount
		&"CardCreated": return "%s joined your hand." % event.data.name
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
