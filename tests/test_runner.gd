extends SceneTree

var _failures: int = 0
var _assertions: int = 0
var _shield_bot: CardDefinition
var _arc_bolt: CardDefinition
var _life_drain: CardDefinition
var _enemy: EnemyDefinition
var _catalog


func _init() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	_catalog = load("res://autoload/card_catalog.gd").new()
	_catalog.reload_catalog()
	_shield_bot = _catalog.get_card(&"shield_bot")
	_arc_bolt = _catalog.get_card(&"arc_bolt")
	_life_drain = _catalog.get_card(&"life_drain")
	_enemy = _catalog.get_enemy(&"siege_core")
	_test_content_resources()
	_test_card_base_artwork_and_style()
	_test_battle_setup()
	_test_damage_action()
	_test_life_drain()
	_test_summoning_sickness_and_attack()
	_test_spread_damage_and_overflow()
	_test_discard_reshuffle()
	_test_invalid_action_is_atomic()
	_test_victory_and_defeat()
	_test_complete_battle_loop()
	_test_deck_rules_and_serialization()
	_catalog.free()
	if _failures == 0:
		print("TESTS_OK: %d assertions" % _assertions)
	else:
		printerr("TESTS_FAILED: %d of %d assertions failed" % [_failures, _assertions])
	quit(_failures)


func _test_content_resources() -> void:
	_expect(_shield_bot is CardDefinition, "Shield Bot resource loads")
	_expect(_arc_bolt is CardDefinition, "Arc Bolt resource loads")
	_expect(_life_drain is CardDefinition, "Life Drain resource loads")
	_expect(_enemy is EnemyDefinition, "Siege Core resource loads")
	var ids := [_shield_bot.id, _arc_bolt.id, _life_drain.id]
	_expect(ids.size() == _unique_values(ids).size(), "Card IDs are unique")
	for definition in [_shield_bot, _arc_bolt, _life_drain]:
		_expect(definition.validation_errors().is_empty(), "%s validates" % definition.display_name)
	_expect(_enemy.validation_errors().is_empty(), "Enemy validates")
	_expect(_catalog.validation_errors.is_empty(), "Catalog scan reports no content errors")


func _test_card_base_artwork_and_style() -> void:
	var card_scene: PackedScene = load("res://ui/card_base.tscn")
	_expect(card_scene != null, "Card base scene loads")
	var artwork_view: CardBase = card_scene.instantiate()
	artwork_view.setup_definition(_shield_bot)
	root.add_child(artwork_view)
	_expect(artwork_view.get_displayed_artwork() == _shield_bot.artwork, "Assigned artwork reaches the card TextureRect")
	var artwork_rect: TextureRect = artwork_view.get_node("%Artwork")
	_expect(artwork_rect.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Artwork uses aspect-preserving cover crop")
	artwork_view.set_compact()
	_expect(artwork_rect.visible and artwork_rect.is_visible_in_tree(), "Compact cards retain visible artwork")
	_expect(artwork_view.get_node("%ArtworkFrame").custom_minimum_size.y == artwork_view.compact_artwork_height, "Compact cards use the compact artwork height")

	var fallback_view: CardBase = card_scene.instantiate()
	fallback_view.setup_definition(_arc_bolt)
	root.add_child(fallback_view)
	_expect(fallback_view.get_displayed_artwork() == load("res://icon.svg"), "Missing artwork uses the project icon")

	var styled_definition: CardDefinition = _arc_bolt.duplicate(true)
	var visual_style := CardVisualStyle.new()
	visual_style.override_panel_color = true
	visual_style.panel_color = Color("#8f2454")
	visual_style.override_title_color = true
	visual_style.title_color = Color("#ffcfef")
	styled_definition.visual_style = visual_style
	var styled_view: CardBase = card_scene.instantiate()
	styled_view.setup_definition(styled_definition)
	root.add_child(styled_view)
	var styled_box := styled_view.get_theme_stylebox("normal") as StyleBoxFlat
	var plain_box := fallback_view.get_theme_stylebox("normal") as StyleBoxFlat
	_expect(styled_box != null and styled_box.bg_color.is_equal_approx(visual_style.panel_color), "Per-card panel color is applied")
	_expect(plain_box != null and not plain_box.bg_color.is_equal_approx(visual_style.panel_color), "Per-card style does not leak to another instance")
	var styled_title: Label = styled_view.get_node("%NameLabel")
	var plain_title: Label = fallback_view.get_node("%NameLabel")
	_expect(styled_title.get_theme_color("font_color").is_equal_approx(visual_style.title_color), "Per-card title color is applied")
	_expect(not plain_title.get_theme_color("font_color").is_equal_approx(visual_style.title_color), "Per-card text style remains isolated")

	artwork_view.free()
	fallback_view.free()
	styled_view.free()


func _test_battle_setup() -> void:
	var rules := BattleRules.new()
	var bundle := _start([_shield_bot, _arc_bolt, _life_drain], rules)
	var session: BattleSession = bundle.session
	_expect(session.phase == BattleSession.Phase.PLAYER_TURN, "Setup enters player turn")
	_expect(session.turn_number == 1, "Setup begins on turn one")
	_expect(session.player_health == 30, "Setup assigns player health")
	_expect(session.current_energy == 5, "Setup refills energy")
	_expect(session.hand.size() == 3, "Setup draws starting hand")


func _test_damage_action() -> void:
	var rules := BattleRules.new()
	rules.starting_hand_size = 1
	rules.cards_drawn_per_turn = 0
	var bundle := _start([_arc_bolt], rules)
	var session: BattleSession = bundle.session
	var resolver: ActionResolver = bundle.resolver
	var card := session.hand[0]
	var events := resolver.play_card(session, card.instance_id)
	_expect(not events.is_empty(), "Damage action produces events")
	_expect(session.enemy.current_health == 24, "Damage action harms enemy")
	_expect(session.current_energy == 3, "Damage action spends energy")
	_expect(session.hand.is_empty() and session.discard_pile.size() == 1, "Action moves to discard")


func _test_life_drain() -> void:
	var rules := BattleRules.new()
	rules.starting_hand_size = 1
	rules.cards_drawn_per_turn = 0
	var bundle := _start([_life_drain], rules)
	var session: BattleSession = bundle.session
	var resolver: ActionResolver = bundle.resolver
	session.player_health = 25
	resolver.play_card(session, session.hand[0].instance_id)
	_expect(session.enemy.current_health == 25, "Life Drain harms enemy")
	_expect(session.player_health == 28, "Life Drain heals player")


func _test_summoning_sickness_and_attack() -> void:
	var rules := BattleRules.new()
	rules.starting_hand_size = 1
	rules.cards_drawn_per_turn = 0
	var bundle := _start([_shield_bot], rules)
	var session: BattleSession = bundle.session
	var resolver: ActionResolver = bundle.resolver
	var unit_id: int = session.hand[0].instance_id
	resolver.play_card(session, unit_id)
	_expect(session.battlefield.size() == 1, "Unit enters battlefield")
	_expect(not resolver.can_attack_enemy(session, unit_id), "New unit cannot attack")
	resolver.end_turn(session)
	_expect(session.turn_number == 2, "Enemy turn advances turn counter")
	_expect(session.battlefield[0].current_health == 1, "Frontline absorbs enemy damage")
	_expect(resolver.can_attack_enemy(session, unit_id), "Unit readies next turn")
	resolver.attack_enemy(session, unit_id)
	_expect(session.enemy.current_health == 26, "Unit attacks enemy")


func _test_spread_damage_and_overflow() -> void:
	var fragile := CardDefinition.new()
	fragile.id = &"fragile_test_unit"
	fragile.display_name = "Fragile Unit"
	fragile.card_type = CardDefinition.CardType.UNIT
	fragile.attack = 0
	fragile.health = 1
	fragile.cost = 0
	var rules := BattleRules.new()
	rules.starting_hand_size = 2
	rules.cards_drawn_per_turn = 0
	var bundle := _start([fragile, fragile], rules)
	var session: BattleSession = bundle.session
	var resolver: ActionResolver = bundle.resolver
	resolver.play_card(session, session.hand[0].instance_id)
	resolver.play_card(session, session.hand[0].instance_id)
	resolver.end_turn(session)
	_expect(session.battlefield.is_empty(), "Spread damage destroys depleted units")
	_expect(session.discard_pile.size() == 2, "Destroyed units enter discard")
	_expect(session.player_health == 28, "Remaining board damage overflows to player")


func _test_discard_reshuffle() -> void:
	var rules := BattleRules.new()
	rules.starting_hand_size = 1
	rules.cards_drawn_per_turn = 1
	var bundle := _start([_arc_bolt], rules)
	var session: BattleSession = bundle.session
	var resolver: ActionResolver = bundle.resolver
	resolver.play_card(session, session.hand[0].instance_id)
	resolver.end_turn(session)
	_expect(session.hand.size() == 1, "Discard reshuffles when draw pile is empty")
	_expect(session.hand[0].definition.id == &"arc_bolt", "Reshuffled card can be redrawn")
	_expect(session.discard_pile.is_empty(), "Reshuffle consumes discard")


func _test_invalid_action_is_atomic() -> void:
	var expensive := CardDefinition.new()
	expensive.id = &"expensive_test_action"
	expensive.display_name = "Too Expensive"
	expensive.card_type = CardDefinition.CardType.ACTION
	expensive.cost = 9
	var rules := BattleRules.new()
	rules.starting_hand_size = 1
	var bundle := _start([expensive], rules)
	var session: BattleSession = bundle.session
	var resolver: ActionResolver = bundle.resolver
	var events := resolver.play_card(session, session.hand[0].instance_id)
	_expect(events.is_empty(), "Invalid action produces no rule events")
	_expect(session.current_energy == 5, "Invalid action does not spend energy")
	_expect(session.hand.size() == 1 and session.discard_pile.is_empty(), "Invalid action does not move cards")


func _test_victory_and_defeat() -> void:
	var weak_enemy := EnemyDefinition.new()
	weak_enemy.id = &"weak_test_enemy"
	weak_enemy.display_name = "Weak Enemy"
	weak_enemy.maximum_health = 3
	weak_enemy.behavior = PatternEnemyBehavior.new()
	var rules := BattleRules.new()
	rules.starting_hand_size = 1
	var victory_bundle := _start([_arc_bolt], rules, weak_enemy)
	var victory_session: BattleSession = victory_bundle.session
	victory_bundle.resolver.play_card(victory_session, victory_session.hand[0].instance_id)
	_expect(victory_session.phase == BattleSession.Phase.VICTORY, "Lethal enemy damage causes victory")
	var lethal_behavior := PatternEnemyBehavior.new()
	lethal_behavior.attack_pattern = PackedInt32Array([100])
	var lethal_enemy := EnemyDefinition.new()
	lethal_enemy.id = &"lethal_test_enemy"
	lethal_enemy.display_name = "Lethal Enemy"
	lethal_enemy.maximum_health = 20
	lethal_enemy.behavior = lethal_behavior
	var defeat_bundle := _start([_arc_bolt], rules, lethal_enemy)
	var defeat_session: BattleSession = defeat_bundle.session
	defeat_bundle.resolver.end_turn(defeat_session)
	_expect(defeat_session.phase == BattleSession.Phase.DEFEAT, "Lethal player damage causes defeat")


func _test_complete_battle_loop() -> void:
	var deck := [_shield_bot, _shield_bot, _arc_bolt, _arc_bolt, _life_drain, _life_drain]
	var bundle := _start(deck, BattleRules.new())
	var session: BattleSession = bundle.session
	var resolver: ActionResolver = bundle.resolver
	var safety_turns := 30
	while not session.is_finished() and safety_turns > 0:
		var made_play := true
		while made_play and not session.is_finished():
			made_play = false
			for card in session.hand.duplicate():
				if resolver.can_play_card(session, card.instance_id):
					resolver.play_card(session, card.instance_id)
					made_play = true
					break
		for unit in session.battlefield.duplicate():
			if resolver.can_attack_enemy(session, unit.instance_id):
				resolver.attack_enemy(session, unit.instance_id)
		if not session.is_finished():
			resolver.end_turn(session)
		safety_turns -= 1
	_expect(session.is_finished(), "A full battle reaches a terminal result")
	_expect(session.phase == BattleSession.Phase.VICTORY, "Starter deck can defeat the MVP enemy")


func _test_deck_rules_and_serialization() -> void:
	var rules := DeckRules.new(BattleRules.new())
	var empty: Array[StringName] = []
	_expect(not rules.validate(empty).is_empty(), "Empty deck is invalid")
	var valid: Array[StringName] = [&"shield_bot", &"shield_bot", &"arc_bolt"]
	_expect(rules.validate(valid).is_empty(), "Valid deck passes rules")
	valid.append(&"shield_bot")
	_expect(not rules.validate(valid).is_empty(), "Duplicate limit is enforced")
	var record := DeckRecord.new("test", "Test Deck", [&"arc_bolt", &"life_drain"])
	var restored := DeckRecord.from_dictionary(record.to_dictionary())
	_expect(restored.id == record.id and restored.card_ids == record.card_ids, "Deck record round-trips")


func _start(definitions: Array, rules: BattleRules, enemy_override: EnemyDefinition = null) -> Dictionary:
	var session := BattleSession.new()
	session.initialize(definitions, enemy_override if enemy_override != null else _enemy, rules, 12345)
	var resolver := ActionResolver.new()
	resolver.start_battle(session)
	return {"session": session, "resolver": resolver}


func _unique_values(values: Array) -> Array:
	var unique: Array = []
	for value in values:
		if value not in unique:
			unique.append(value)
	return unique


func _expect(condition: bool, message: String) -> void:
	_assertions += 1
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)
