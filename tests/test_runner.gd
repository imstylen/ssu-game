extends SceneTree

const EXPECTED_CARDS := {
	&"shield_bot": ["Rolling Rabbit", CardDefinition.CardType.UNIT, 2, 2, 5],
	&"autistic_axolotl": ["Autistic Axolotl", CardDefinition.CardType.UNIT, 2, 3, 3],
	&"deaf_deer": ["Signing Deer", CardDefinition.CardType.UNIT, 3, 4, 4],
	&"adhd_red_panda": ["ADHD Red Panda", CardDefinition.CardType.UNIT, 1, 2, 2],
	&"dyslexic_duckling": ["Dyslexic Duckling", CardDefinition.CardType.UNIT, 3, 5, 3],
	&"prosthetic_paw_puppy": ["Prosthetic-Paw Puppy", CardDefinition.CardType.UNIT, 4, 4, 7],
	&"grounding_alpaca": ["Grounding Alpaca", CardDefinition.CardType.UNIT, 2, 1, 6],
	&"arc_bolt": ["Speak Up!", CardDefinition.CardType.ACTION, 2, 0, 1],
	&"life_drain": ["Cup of Tea", CardDefinition.CardType.ACTION, 2, 0, 1],
	&"low_vision_lynx": ["Meditate & Plan", CardDefinition.CardType.ACTION, 1, 0, 1],
}

var EXPECTED_ENEMIES := {
	&"siege_core": ["Gatekeeping Gremlin", 30, PackedInt32Array([4, 5, 7])],
	&"assumption_golem": ["Assumption Golem", 34, PackedInt32Array([3, 6, 5])],
	&"barrier_blob": ["Barrier Blob", 26, PackedInt32Array([2, 4, 8])],
}

var _failures := 0
var _assertions := 0
var _catalog
var _cards: Dictionary = {}
var _enemies: Dictionary = {}


func _init() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	_catalog = load("res://autoload/card_catalog.gd").new()
	_catalog.reload_catalog()
	for card_id in EXPECTED_CARDS:
		_cards[card_id] = _catalog.get_card(card_id)
	for enemy_id in EXPECTED_ENEMIES:
		_enemies[enemy_id] = _catalog.get_enemy(enemy_id)
	_test_content_resources()
	_test_card_base_artwork_and_style()
	_test_battle_setup()
	_test_damage_one_shot()
	_test_heal_one_shot()
	_test_draw_one_shot()
	_test_full_hand_burn()
	_test_automatic_start_of_round_help()
	_test_spread_damage_and_overflow()
	_test_discard_reshuffle()
	_test_invalid_action_is_atomic()
	_test_victory_and_defeat()
	_test_random_enemy_selection()
	_test_complete_battles()
	_test_deck_rules_and_serialization()
	_test_profile_migration()
	_test_font_license_and_copy()
	_test_legible_theme_colors()
	await _test_enemy_portrait_binding()
	_catalog.free()
	if _failures == 0:
		print("TESTS_OK: %d assertions" % _assertions)
	else:
		printerr("TESTS_FAILED: %d of %d assertions failed" % [_failures, _assertions])
	quit(_failures)


func _test_content_resources() -> void:
	var cards: Array[CardDefinition] = _catalog.get_all_cards()
	var enemies: Array[EnemyDefinition] = _catalog.get_all_enemies()
	_expect(cards.size() == 10, "Catalog contains exactly ten unique cards")
	_expect(enemies.size() == 3, "Catalog contains exactly three ableism monsters")
	var allies := 0
	var one_shots := 0
	var style_paths: Dictionary = {}
	for card_id in EXPECTED_CARDS:
		var card: CardDefinition = _cards[card_id]
		var expected: Array = EXPECTED_CARDS[card_id]
		_expect(card != null, "%s resource loads" % card_id)
		if card == null:
			continue
		_expect(card.display_name == expected[0], "%s has its Access Allies name" % card_id)
		_expect(card.card_type == expected[1], "%s has the expected type" % card_id)
		_expect(card.cost == expected[2], "%s has the expected Spark cost" % card_id)
		_expect(card.attack == expected[3] and card.health == expected[4], "%s has expected Power and Heart" % card_id)
		_expect(not card.description.is_empty(), "%s has warm rules text" % card_id)
		_expect(card.artwork != null, "%s has assigned artwork" % card_id)
		_expect(card.artwork != null and card.artwork.get_width() == 1024 and card.artwork.get_height() == 1024, "%s artwork is 1024x1024" % card_id)
		_expect(card.visual_style != null, "%s has a reusable pastel variant" % card_id)
		if card.visual_style != null:
			style_paths[card.visual_style.resource_path] = true
		_expect(card.validation_errors().is_empty(), "%s validates" % card_id)
		if card.card_type == CardDefinition.CardType.UNIT:
			allies += 1
		else:
			one_shots += 1
	_expect(allies == 7, "Roster has seven allies")
	_expect(one_shots == 3, "Roster has three one-shots")
	_expect(style_paths.size() == 5, "Roster uses five reusable card color variants")
	for enemy_id in EXPECTED_ENEMIES:
		var enemy: EnemyDefinition = _enemies[enemy_id]
		var expected: Array = EXPECTED_ENEMIES[enemy_id]
		_expect(enemy != null, "%s resource loads" % enemy_id)
		if enemy == null:
			continue
		_expect(enemy.display_name == expected[0], "%s has its Access Allies name" % enemy_id)
		_expect(enemy.maximum_health == expected[1], "%s has expected Heart" % enemy_id)
		_expect(enemy.behavior is PatternEnemyBehavior and enemy.behavior.attack_pattern == expected[2], "%s has expected barrier rhythm" % enemy_id)
		_expect(not enemy.description.is_empty(), "%s has a barrier-themed description" % enemy_id)
		_expect(enemy.artwork != null, "%s has assigned artwork" % enemy_id)
		_expect(enemy.artwork != null and enemy.artwork.get_width() == 1024 and enemy.artwork.get_height() == 1024, "%s artwork is 1024x1024" % enemy_id)
		_expect(enemy.validation_errors().is_empty(), "%s validates" % enemy_id)
	_expect(_catalog.validation_errors.is_empty(), "Catalog scan reports no content errors")


func _test_card_base_artwork_and_style() -> void:
	var card_scene: PackedScene = load("res://ui/card_base.tscn")
	_expect(card_scene != null, "Editor-authorable card base scene loads")
	var view: CardBase = card_scene.instantiate()
	view.setup_definition(_cards[&"shield_bot"])
	root.add_child(view)
	var artwork_rect: TextureRect = view.get_node("%Artwork")
	_expect(view.get_displayed_artwork() == _cards[&"shield_bot"].artwork, "Assigned artwork reaches the card TextureRect")
	_expect(artwork_rect.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Artwork uses aspect-preserving cover crop")
	_expect(view.get_node("%TypeLabel").text == "ALLY", "Unit type is displayed as ALLY")
	_expect(view.get_node("%AttackLabel").text == "POWER 2", "Attack stat is displayed as POWER")
	_expect(view.get_node("%HealthLabel").text == "HEART 5", "Health stat is displayed as HEART")
	var health_progress: ProgressBar = view.get_node("%HealthProgress")
	_expect(not health_progress.visible, "Card health progress is hidden outside the battlefield")
	var battlefield_instance := CardInstance.new(_cards[&"shield_bot"], 9001)
	battlefield_instance.current_health = 3
	view.setup_instance(battlefield_instance)
	view.set_battlefield_health_bar()
	_expect(health_progress.visible and health_progress.max_value == 5.0 and health_progress.value == 3.0, "Battlefield card health bar binds current and maximum Heart")
	_expect(health_progress.tooltip_text == "3 / 5 Heart", "Battlefield health bar retains an exact accessible value")
	battlefield_instance.current_health = 1
	view.setup_instance(battlefield_instance)
	var low_health_fill := health_progress.get_theme_stylebox("fill") as StyleBoxFlat
	_expect(low_health_fill != null and low_health_fill.bg_color.is_equal_approx(AppTheme.DANGER), "Low-Heart card bar switches to berry danger styling")
	view.set_battlefield_health_bar(false)
	_expect(not health_progress.visible, "Battlefield health bar can be hidden for hand and catalog cards")
	view.set_compact()
	_expect(artwork_rect.visible and artwork_rect.is_visible_in_tree(), "Compact cards retain visible artwork")
	_expect(view.get_node("%ArtworkFrame").custom_minimum_size == Vector2.ONE * view.compact_artwork_size, "Compact artwork remains square")
	view.mouse_entered.emit()
	var hover_layer := root.get_node_or_null("CardHoverPreviewLayer") as CanvasLayer
	var hover_card: CardBase = hover_layer.get_node_or_null("FullCardPreview") if hover_layer != null else null
	_expect(hover_card != null and not hover_card.compact, "Hovering a compact card creates a full-card preview")
	_expect(hover_card != null and hover_card.get_node("%DescriptionLabel").visible, "Hover preview exposes readable description text")
	_expect(hover_card != null and hover_card.get_displayed_artwork() == _cards[&"shield_bot"].artwork, "Hover preview preserves artwork")
	view.mouse_exited.emit()
	_expect(root.get_node_or_null("CardHoverPreviewLayer") == null, "Hover preview closes on pointer exit")

	var missing := CardDefinition.new()
	missing.id = &"missing_art_test"
	missing.display_name = "Fallback Friend"
	var fallback_view: CardBase = card_scene.instantiate()
	fallback_view.setup_definition(missing)
	root.add_child(fallback_view)
	_expect(fallback_view.get_displayed_artwork() == load("res://icon.svg"), "Missing artwork uses the project icon")

	var styled_definition: CardDefinition = missing.duplicate(true)
	var visual_style := CardVisualStyle.new()
	visual_style.override_panel_color = true
	visual_style.panel_color = Color("#FFEEDD")
	visual_style.override_title_color = true
	visual_style.title_color = Color("#4B315A")
	styled_definition.visual_style = visual_style
	var styled_view: CardBase = card_scene.instantiate()
	styled_view.setup_definition(styled_definition)
	root.add_child(styled_view)
	var styled_box := styled_view.get_theme_stylebox("normal") as StyleBoxFlat
	var plain_box := fallback_view.get_theme_stylebox("normal") as StyleBoxFlat
	_expect(styled_box.bg_color.is_equal_approx(visual_style.panel_color), "Per-card panel color is applied")
	_expect(not plain_box.bg_color.is_equal_approx(visual_style.panel_color), "Per-card styling does not leak")
	_expect(view.editor_preview_definition != null and view.editor_preview_definition.id == &"life_drain", "Editor preview defaults to Cup of Tea's stable resource")
	view.free()
	fallback_view.free()
	styled_view.free()


func _test_battle_setup() -> void:
	var rules := BattleRules.new()
	var bundle := _start([_cards[&"shield_bot"], _cards[&"arc_bolt"], _cards[&"life_drain"]], rules)
	var session: BattleSession = bundle.session
	_expect(session.phase == BattleSession.Phase.PLAYER_TURN, "Setup enters the player's round")
	_expect(session.turn_number == 1 and session.player_health == 30, "Setup initializes round and Team Heart")
	_expect(session.current_energy == 5 and session.hand.size() == 3, "Setup fills Spark and starting hand")


func _test_damage_one_shot() -> void:
	var bundle := _forced_hand_bundle(_cards[&"arc_bolt"], [_cards[&"shield_bot"]])
	var events: Array[BattleEvent] = bundle.resolver.play_card(bundle.session, bundle.session.hand[0].instance_id)
	_expect(bundle.session.enemy.current_health == 26, "Speak Up deals exactly 4 damage")
	_expect(bundle.session.current_energy == 3, "Speak Up spends 2 Spark")
	_expect(bundle.session.hand.is_empty() and bundle.session.discard_pile.size() == 1, "Damage one-shot moves to the rest pile")
	_expect(_event_count(events, &"DamageApplied") == 1, "Damage one-shot emits one damage event")


func _test_heal_one_shot() -> void:
	var bundle := _forced_hand_bundle(_cards[&"life_drain"], [_cards[&"shield_bot"]])
	bundle.session.player_health = 27
	var enemy_health: int = bundle.session.enemy.current_health
	var events: Array[BattleEvent] = bundle.resolver.play_card(bundle.session, bundle.session.hand[0].instance_id)
	_expect(bundle.session.player_health == 30, "Cup of Tea heals up to maximum Team Heart")
	_expect(bundle.session.enemy.current_health == enemy_health, "Cup of Tea does not damage the monster")
	var healing := _first_event(events, &"HealingApplied")
	_expect(healing != null and healing.data.amount == 3, "Heal-5 effect reports only the clamped amount")
	var second := _forced_hand_bundle(_cards[&"life_drain"], [_cards[&"shield_bot"]])
	second.session.player_health = 20
	second.resolver.play_card(second.session, second.session.hand[0].instance_id)
	_expect(second.session.player_health == 25, "Cup of Tea heals exactly 5 when room is available")


func _test_draw_one_shot() -> void:
	var bundle := _forced_hand_bundle(_cards[&"low_vision_lynx"], [_cards[&"shield_bot"], _cards[&"arc_bolt"]])
	var events: Array[BattleEvent] = bundle.resolver.play_card(bundle.session, bundle.session.hand[0].instance_id)
	_expect(bundle.session.hand.size() == 2, "Meditate & Plan draws exactly 2 cards")
	_expect(_event_count(events, &"CardDrawn") == 2, "Draw-2 emits two draw events")
	_expect(bundle.session.discard_pile.size() == 1 and bundle.session.discard_pile[0].definition.id == &"low_vision_lynx", "Draw one-shot moves itself to the rest pile")


func _test_full_hand_burn() -> void:
	var definitions: Array = [_cards[&"low_vision_lynx"]]
	for _index in 9:
		definitions.append(_cards[&"shield_bot"])
	var rules := BattleRules.new()
	rules.starting_hand_size = 0
	rules.cards_drawn_per_turn = 0
	var bundle := _start(definitions, rules)
	_force_into_hand(bundle.session, &"low_vision_lynx")
	while bundle.session.hand.size() < 8:
		bundle.session.hand.append(bundle.session.draw_pile.pop_back())
	var events: Array[BattleEvent] = bundle.resolver.play_card(bundle.session, bundle.session.find_hand_card(_find_hand_id(bundle.session, &"low_vision_lynx")).instance_id)
	_expect(bundle.session.hand.size() == 8, "Draw-2 stops the hand at its maximum")
	_expect(_event_count(events, &"CardBurned") == 1, "The extra draw moves to the rest pile when hand is full")
	_expect(bundle.session.discard_pile.size() == 2, "Burned card and played one-shot both reach the rest pile")


func _test_automatic_start_of_round_help() -> void:
	var bundle := _forced_hand_bundle(_cards[&"shield_bot"], [_cards[&"arc_bolt"]])
	var unit_id: int = bundle.session.hand[0].instance_id
	bundle.resolver.play_card(bundle.session, unit_id)
	_expect(bundle.session.battlefield.size() == 1, "An ally joins the Ally Circle")
	_expect(not bundle.resolver.can_attack_enemy(bundle.session, unit_id), "A new ally rests until the next round")
	var events: Array[BattleEvent] = bundle.resolver.end_turn(bundle.session)
	_expect(bundle.session.turn_number == 2, "Ending a round advances the adventure")
	_expect(bundle.session.battlefield[0].current_health == 1, "The Ally Circle shares incoming barrier damage")
	_expect(bundle.session.enemy.current_health == 28, "Rolling Rabbit automatically helps for 2 Power at round start")
	_expect(_event_count(events, &"UnitAttacked") == 1, "Automatic help emits an attacker presentation event")
	_expect(not bundle.resolver.can_attack_enemy(bundle.session, unit_id), "An ally cannot help twice after its automatic attack")


func _test_spread_damage_and_overflow() -> void:
	var fragile := CardDefinition.new()
	fragile.id = &"fragile_test_ally"
	fragile.display_name = "Tiny Test Ally"
	fragile.health = 1
	fragile.cost = 0
	var rules := BattleRules.new()
	rules.starting_hand_size = 2
	rules.cards_drawn_per_turn = 0
	var bundle := _start([fragile, fragile], rules)
	bundle.resolver.play_card(bundle.session, bundle.session.hand[0].instance_id)
	bundle.resolver.play_card(bundle.session, bundle.session.hand[0].instance_id)
	bundle.resolver.end_turn(bundle.session)
	_expect(bundle.session.battlefield.is_empty(), "Allies at zero Heart need a rest")
	_expect(bundle.session.discard_pile.size() == 2, "Resting allies enter the rest pile")
	_expect(bundle.session.player_health == 28, "Remaining barrier damage reaches Team Heart")


func _test_discard_reshuffle() -> void:
	var rules := BattleRules.new()
	rules.starting_hand_size = 1
	rules.cards_drawn_per_turn = 1
	var bundle := _start([_cards[&"arc_bolt"]], rules)
	bundle.resolver.play_card(bundle.session, bundle.session.hand[0].instance_id)
	bundle.resolver.end_turn(bundle.session)
	_expect(bundle.session.hand.size() == 1 and bundle.session.hand[0].definition.id == &"arc_bolt", "Rest pile reshuffles into a fresh deck")
	_expect(bundle.session.discard_pile.is_empty(), "Reshuffle consumes the rest pile")


func _test_invalid_action_is_atomic() -> void:
	var expensive := CardDefinition.new()
	expensive.id = &"expensive_test_one_shot"
	expensive.display_name = "Big Spark Test"
	expensive.card_type = CardDefinition.CardType.ACTION
	expensive.cost = 9
	var bundle := _forced_hand_bundle(expensive, [])
	var events: Array[BattleEvent] = bundle.resolver.play_card(bundle.session, bundle.session.hand[0].instance_id)
	_expect(events.is_empty(), "Invalid play produces no rule events")
	_expect(bundle.session.current_energy == 5, "Invalid play does not spend Spark")
	_expect(bundle.session.hand.size() == 1 and bundle.session.discard_pile.is_empty(), "Invalid play does not move cards")


func _test_victory_and_defeat() -> void:
	var weak_enemy := EnemyDefinition.new()
	weak_enemy.id = &"weak_test_monster"
	weak_enemy.display_name = "Paper Barrier"
	weak_enemy.maximum_health = 3
	weak_enemy.behavior = PatternEnemyBehavior.new()
	var victory := _forced_hand_bundle(_cards[&"arc_bolt"], [], weak_enemy)
	victory.resolver.play_card(victory.session, victory.session.hand[0].instance_id)
	_expect(victory.session.phase == BattleSession.Phase.VICTORY, "Lethal monster damage busts the barrier")
	var lethal_behavior := PatternEnemyBehavior.new()
	lethal_behavior.attack_pattern = PackedInt32Array([100])
	var lethal_enemy := EnemyDefinition.new()
	lethal_enemy.id = &"lethal_test_monster"
	lethal_enemy.display_name = "Huge Test Barrier"
	lethal_enemy.maximum_health = 20
	lethal_enemy.behavior = lethal_behavior
	var defeat := _forced_hand_bundle(_cards[&"arc_bolt"], [], lethal_enemy)
	defeat.resolver.end_turn(defeat.session)
	_expect(defeat.session.phase == BattleSession.Phase.DEFEAT, "Zero Team Heart ends in a rest")


func _test_random_enemy_selection() -> void:
	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 778899
	second_rng.seed = 778899
	var first_sequence: Array[StringName] = []
	var second_sequence: Array[StringName] = []
	for _index in 24:
		var first: EnemyDefinition = _catalog.get_random_enemy(first_rng)
		var second: EnemyDefinition = _catalog.get_random_enemy(second_rng)
		first_sequence.append(first.id)
		second_sequence.append(second.id)
		_expect(first.id in EXPECTED_ENEMIES, "Random selection always returns a catalog monster")
	_expect(first_sequence == second_sequence, "Seeded random monster selection is deterministic")
	_expect(_unique_values(first_sequence).size() == 3, "Seeded sequence can reach all three monsters")
	var empty_catalog = load("res://autoload/card_catalog.gd").new()
	empty_catalog.enemies_by_id.clear()
	_expect(empty_catalog.get_random_enemy(first_rng) == null, "Empty catalog returns no random monster")
	empty_catalog.free()


func _test_complete_battles() -> void:
	var starter := _starter_definitions()
	_expect(starter.size() == 20, "Access Allies starter contains twenty cards")
	for enemy_id in EXPECTED_ENEMIES:
		var bundle := _start(starter, BattleRules.new(), _enemies[enemy_id])
		var safety_rounds := 40
		while not bundle.session.is_finished() and safety_rounds > 0:
			var made_play := true
			while made_play and not bundle.session.is_finished():
				made_play = false
				for card in bundle.session.hand.duplicate():
					if bundle.resolver.can_play_card(bundle.session, card.instance_id):
						bundle.resolver.play_card(bundle.session, card.instance_id)
						made_play = true
						break
			for ally in bundle.session.battlefield.duplicate():
				if bundle.resolver.can_attack_enemy(bundle.session, ally.instance_id):
					bundle.resolver.attack_enemy(bundle.session, ally.instance_id)
			if not bundle.session.is_finished():
				bundle.resolver.end_turn(bundle.session)
			safety_rounds -= 1
		_expect(bundle.session.phase == BattleSession.Phase.VICTORY, "Starter deck can bust %s" % _enemies[enemy_id].display_name)


func _test_deck_rules_and_serialization() -> void:
	var rules := DeckRules.new(BattleRules.new())
	var empty: Array[StringName] = []
	_expect(not rules.validate(empty).is_empty(), "Empty deck gives a precise warm instruction")
	var valid: Array[StringName] = []
	valid.assign(ProfileMigrator.ACCESS_ALLIES_STARTER_IDS)
	_expect(valid.size() == 20 and rules.validate(valid, _catalog).is_empty(), "Twenty-card starter respects the duplicate limit")
	valid.append(&"shield_bot")
	_expect(not rules.validate(valid, _catalog).is_empty(), "A third copy is rejected")
	var record := DeckRecord.new("test", "Test Ally Deck", [&"arc_bolt", &"life_drain"])
	var restored := DeckRecord.from_dictionary(record.to_dictionary())
	_expect(restored.id == record.id and restored.card_ids == record.card_ids, "Deck record round-trips")


func _test_profile_migration() -> void:
	var legacy := {
		"schema_version": 1,
		"selected_deck_id": "starter",
		"decks": [
			{"id": "starter", "name": "Starter Squad", "card_ids": ["shield_bot", "shield_bot", "arc_bolt", "arc_bolt", "life_drain", "life_drain"]},
			{"id": "personal", "name": "My Own Deck", "card_ids": ["arc_bolt"]},
		],
	}
	var migrated: Dictionary = ProfileMigrator.migrate_profile_data(legacy)
	_expect(migrated.changed and migrated.data.schema_version == 2, "Legacy profile migrates to schema 2")
	_expect(migrated.data.decks[0].name == "Access Allies" and migrated.data.decks[0].card_ids.size() == 20, "Untouched six-card starter upgrades and is renamed")
	_expect(migrated.data.decks[1] == legacy.decks[1], "User-created deck is preserved exactly")
	var customized := legacy.duplicate(true)
	customized.decks[0].card_ids.append("shield_bot")
	customized.decks[0].name = "My Customized Starter"
	var customized_result: Dictionary = ProfileMigrator.migrate_profile_data(customized)
	_expect(customized_result.data.decks[0] == customized.decks[0], "Customized starter remains untouched")
	var current: Dictionary = migrated.data.duplicate(true)
	var current_result: Dictionary = ProfileMigrator.migrate_profile_data(current)
	_expect(not current_result.changed and current_result.data == current, "Schema-2 profile is idempotent")


func _test_font_license_and_copy() -> void:
	var font := load("res://assets/fonts/Fredoka-Variable.ttf")
	_expect(font is FontFile, "Fredoka variable font loads")
	var license := FileAccess.get_file_as_string("res://assets/fonts/OFL-Fredoka.txt")
	_expect(license.contains("SIL OPEN FONT LICENSE") and license.contains("Version 1.1"), "Fredoka OFL license is bundled")
	var source_paths := [
		"res://main/main.gd", "res://collection/collection.gd", "res://decks/deck_builder.gd",
		"res://battle/battle_ui.gd", "res://ui/card_base.gd",
	]
	var player_copy := ""
	for path in source_paths:
		player_copy += FileAccess.get_file_as_string(path)
	for old_phrase in ["TACTICAL DECK COMMAND", "SSU // FRONTLINE", "FIELD OPERATION", "COMMANDER 30", "MISSION COMPLETE", "LINE OVERRUN", "READY TO ATTACK", "was destroyed", "Commander defeated"]:
		_expect(not player_copy.contains(old_phrase), "Old player-facing military phrase is absent: %s" % old_phrase)
	for required in ["ACCESS ALLIES", "A COZY CARD ADVENTURE", "ALLY ALBUM", "COZY DECK BUILDER", "BARRIER-BUSTING ADVENTURE", "TEAM HEART", "ALLY CIRCLE", "STORY SO FAR", "SPARK", "YOUR HAND", "BARRIER BUSTED!", "TIME FOR A REST"]:
		_expect(player_copy.contains(required), "Required warm interface string is present: %s" % required)


func _test_legible_theme_colors() -> void:
	for entry in [
		[AppTheme.INK, AppTheme.SURFACE, "primary text"],
		[AppTheme.SECONDARY_TEXT, AppTheme.SURFACE, "secondary text"],
		[AppTheme.ACCENT_TEXT, AppTheme.SURFACE, "positive text"],
		[AppTheme.DANGER_TEXT, AppTheme.SURFACE, "danger text"],
		[AppTheme.GOLD_TEXT, AppTheme.SURFACE, "highlight text"],
		[Color("#735D7A"), Color("#F5EAF0"), "disabled button text"],
	]:
		_expect(_contrast_ratio(entry[0], entry[1]) >= 4.5, "%s meets 4.5:1 contrast" % entry[2])
	var menu_source := FileAccess.get_file_as_string("res://main/main.gd")
	_expect(menu_source.contains("access_allies_menu_hero.png"), "Main menu references the dedicated hero artwork")


func _test_enemy_portrait_binding() -> void:
	var packed: PackedScene = load("res://battle/battle_scene.tscn")
	var battle_ui = packed.instantiate()
	var battle_controller: BattleController = battle_ui.get_node("BattleController")
	battle_controller.presentation_delay = 0.0
	battle_ui.visible = false
	root.add_child(battle_ui)
	await process_frame
	battle_controller.start_battle(_starter_definitions(), _enemies[&"barrier_blob"], BattleRules.new(), 24680)
	await process_frame
	_expect(battle_ui.get_enemy_portrait_texture() == _enemies[&"barrier_blob"].artwork, "Battle header binds selected monster artwork")
	_expect(battle_ui.get_enemy_description_text() == _enemies[&"barrier_blob"].description, "Battle header binds selected monster description")
	var damage_event := BattleEvent.new(&"DamageApplied", {"target": "enemy", "amount": 3, "health": 23})
	battle_ui._show_damage_number(damage_event)
	var damage_root: Control = battle_ui.find_child("DamageNumbers", true, false)
	_expect(damage_root != null and damage_root.get_child_count() == 1, "Enemy damage creates a large overlay number")
	var damage_number := damage_root.get_child(0) as Label if damage_root != null and damage_root.get_child_count() > 0 else null
	_expect(damage_number != null and damage_number.text == "-3" and damage_number.get_theme_color("font_color").is_equal_approx(AppTheme.DANGER), "Damage overlay shows the red negative amount")
	var enemy_artwork: Control = battle_ui.find_child("EnemyArtwork", true, false)
	var encounter_panel: Control = battle_ui.find_child("EnemyEncounterPanel", true, false)
	var board_row: Control = battle_ui.find_child("PlayerBoardRow", true, false)
	var team_heart_section: Control = battle_ui.find_child("TeamHeartSection", true, false)
	var player_hand_panel: Control = battle_ui.find_child("PlayerHandPanel", true, false)
	var monster_health_bar: ProgressBar = battle_ui.find_child("MonsterHealthBar", true, false)
	var monster_health_text: Label = battle_ui.find_child("MonsterHealthText", true, false)
	var team_heart_bar: ProgressBar = battle_ui.find_child("TeamHeartBar", true, false)
	var team_heart_text: Label = battle_ui.find_child("TeamHeartText", true, false)
	var spark_row: HBoxContainer = battle_ui.find_child("SparkIconRow", true, false)
	_expect(enemy_artwork != null and enemy_artwork.custom_minimum_size == Vector2(240, 240), "Expanded enemy section uses a large square portrait")
	_expect(encounter_panel != null and board_row != null and encounter_panel.custom_minimum_size.y > board_row.custom_minimum_size.y, "Enemy encounter is taller than the compact player board")
	_expect(team_heart_section != null and player_hand_panel != null and team_heart_section.get_parent() == player_hand_panel.get_parent() and team_heart_section.get_index() + 1 == player_hand_panel.get_index(), "Team Heart section is immediately above the player hand")
	_expect(monster_health_bar != null and monster_health_bar.max_value == 26.0 and monster_health_bar.value == 26.0, "Monster Health uses a bound progress bar")
	_expect(monster_health_text != null and monster_health_text.text == "26 / 26", "Monster Health progress bar retains exact numbers")
	_expect(team_heart_bar != null and team_heart_bar.max_value == 30.0 and team_heart_bar.value == 30.0, "Team Heart uses a bound progress bar")
	_expect(team_heart_text != null and team_heart_text.text == "30 / 30", "Team Heart progress bar retains exact numbers")
	_expect(spark_row != null and spark_row.get_child_count() == 5, "Spark is represented by exactly five icons")
	_expect(spark_row != null and spark_row.tooltip_text == "5 of 5 Spark available", "Spark icon row retains an exact accessible value")
	var available_spark := load("res://battle/art/spark_available.png")
	var spent_spark := load("res://battle/art/spark_spent.png")
	_expect(spark_row != null and spark_row.get_child(0).texture == available_spark and spark_row.get_child(4).texture == available_spark, "Full Spark displays five available icons")
	battle_ui._refresh_spark_icons(2, 5)
	_expect(spark_row.get_child(0).texture == available_spark and spark_row.get_child(1).texture == available_spark and spark_row.get_child(2).texture == spent_spark and spark_row.get_child(4).texture == spent_spark, "Spent Spark swaps individual icons without a numeric counter")
	battle_ui._animate_attacker(enemy_artwork)
	await process_frame
	_expect(enemy_artwork != null and enemy_artwork.scale.x > 1.0, "Monster artwork grows briefly when it attacks")
	battle_ui.free()


func _forced_hand_bundle(card: CardDefinition, extras: Array, enemy_override: EnemyDefinition = null) -> Dictionary:
	var definitions: Array = [card]
	definitions.append_array(extras)
	var rules := BattleRules.new()
	rules.starting_hand_size = 0
	rules.cards_drawn_per_turn = 0
	var bundle := _start(definitions, rules, enemy_override)
	_force_into_hand(bundle.session, card.id)
	return bundle


func _force_into_hand(session: BattleSession, card_id: StringName) -> void:
	for card in session.draw_pile:
		if card.definition.id == card_id:
			session.draw_pile.erase(card)
			session.hand.append(card)
			return


func _find_hand_id(session: BattleSession, card_id: StringName) -> int:
	for card in session.hand:
		if card.definition.id == card_id:
			return card.instance_id
	return -1


func _starter_definitions() -> Array[CardDefinition]:
	var result: Array[CardDefinition] = []
	for card_id in ProfileMigrator.ACCESS_ALLIES_STARTER_IDS:
		result.append(_cards[card_id])
	return result


func _start(definitions: Array, rules: BattleRules, enemy_override: EnemyDefinition = null) -> Dictionary:
	var session := BattleSession.new()
	session.initialize(definitions, enemy_override if enemy_override != null else _enemies[&"siege_core"], rules, 12345)
	var resolver := ActionResolver.new()
	resolver.start_battle(session)
	return {"session": session, "resolver": resolver}


func _event_count(events: Array[BattleEvent], kind: StringName) -> int:
	var count := 0
	for event in events:
		if event.kind == kind:
			count += 1
	return count


func _first_event(events: Array[BattleEvent], kind: StringName) -> BattleEvent:
	for event in events:
		if event.kind == kind:
			return event
	return null


func _unique_values(values: Array) -> Array:
	var unique: Array = []
	for value in values:
		if value not in unique:
			unique.append(value)
	return unique


func _contrast_ratio(foreground: Color, background: Color) -> float:
	var foreground_luminance := _relative_luminance(foreground)
	var background_luminance := _relative_luminance(background)
	return (maxf(foreground_luminance, background_luminance) + 0.05) / (minf(foreground_luminance, background_luminance) + 0.05)


func _relative_luminance(color: Color) -> float:
	var red := color.r / 12.92 if color.r <= 0.04045 else pow((color.r + 0.055) / 1.055, 2.4)
	var green := color.g / 12.92 if color.g <= 0.04045 else pow((color.g + 0.055) / 1.055, 2.4)
	var blue := color.b / 12.92 if color.b <= 0.04045 else pow((color.b + 0.055) / 1.055, 2.4)
	return 0.2126 * red + 0.7152 * green + 0.0722 * blue


func _expect(condition: bool, message: String) -> void:
	_assertions += 1
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)
