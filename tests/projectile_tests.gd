extends RefCounted
## Tests for attack projectiles: resolver source attribution on damage and healing
## events, ProjectileStyle selection, and the battle scene's paced presentation.

const Mechanics := preload("res://tests/card_mechanics_tests.gd")


static func run(check: Callable) -> void:
	_test_ally_attack_source(check)
	_test_card_effect_source(check)
	_test_enemy_spread_source(check)
	_test_shield_absorbed_hit(check)
	_test_triggered_unit_sources(check)
	_test_healing_sources(check)
	_test_style_selection(check)


static func run_scene(check: Callable, tree: SceneTree) -> void:
	await _test_instant_presentation(check, tree)
	await _test_paced_presentation(check, tree)
	await _test_reduce_motion_presentation(check, tree)


# ------------------------------------------------------------------ helpers

static func _of_kind(events: Array[BattleEvent], kind: StringName) -> Array[BattleEvent]:
	var result: Array[BattleEvent] = []
	for event in events:
		if event.kind == kind:
			result.append(event)
	return result


static func _source_is(event: BattleEvent, kind: String, instance_id: int = -1) -> bool:
	var source: Dictionary = event.data.get("source", {})
	if str(source.get("kind", "")) != kind:
		return false
	return instance_id < 0 or int(source.get("instance_id", -1)) == instance_id


static func _all_sourced(events: Array[BattleEvent], kind: String, instance_id: int = -1) -> bool:
	if events.is_empty():
		return false
	for event in events:
		if not _source_is(event, kind, instance_id):
			return false
	return true


# ------------------------------------------------------------------ domain

static func _test_ally_attack_source(check: Callable) -> void:
	var bundle := Mechanics.start([Mechanics.card(&"helper", 3, 5)], Mechanics.enemy([0]))
	var ally := Mechanics.to_circle(bundle.session, &"helper")
	var events: Array[BattleEvent] = bundle.resolver.attack_enemy(bundle.session, ally.instance_id)
	var damage := _of_kind(events, &"DamageApplied")
	check.call(damage.size() == 1 and _source_is(damage[0], "unit", ally.instance_id), "An ally attack's damage names that ally as its source")
	check.call(str(damage[0].data.source.get("card_id", "")) == "helper", "A unit source carries its card ID for projectile lookup")


static func _test_card_effect_source(check: Callable) -> void:
	var zap := Mechanics.card(&"zap", 0, 1, Mechanics.triggered("played_effects", [Mechanics.effect(CardEffect.Kind.DAMAGE_ENEMY, 3)]), false)
	var bundle := Mechanics.start([zap], Mechanics.enemy([0]))
	var played := Mechanics.to_hand(bundle.session, &"zap")
	var events: Array[BattleEvent] = bundle.resolver.play_card(bundle.session, played.instance_id)
	var damage := _of_kind(events, &"DamageApplied")
	check.call(damage.size() == 1 and _source_is(damage[0], "card", played.instance_id), "A played card's effect damage names the played card as its source")


static func _test_enemy_spread_source(check: Callable) -> void:
	var bundle := Mechanics.start([Mechanics.card(&"a", 0, 1), Mechanics.card(&"b", 0, 9)], Mechanics.enemy([4]))
	Mechanics.to_circle(bundle.session, &"a")
	Mechanics.to_circle(bundle.session, &"b")
	var events: Array[BattleEvent] = bundle.resolver.end_turn(bundle.session)
	var damage := _of_kind(events, &"DamageApplied")
	check.call(damage.size() == 4, "Spread damage still arrives one point per event")
	check.call(_all_sourced(damage, "enemy"), "Every spread hit names the enemy as its source")
	check.call(damage[0].data.source.get("action") is EnemyAction, "Enemy sources carry the action that caused them")
	var started := _of_kind(events, &"EnemyActionStarted")
	check.call(started.size() == 1 and started[0].data.get("action") == damage[0].data.source.action, "EnemyActionStarted names the same action as its hits")

	bundle = Mechanics.start([Mechanics.card(&"lonely", 0, 1)], Mechanics.enemy([3]))
	Mechanics.to_circle(bundle.session, &"lonely")
	events = bundle.resolver.end_turn(bundle.session)
	var spill := _of_kind(events, &"DamageApplied").filter(func(event: BattleEvent): return event.data.target == "player")
	check.call(spill.size() == 1 and _source_is(spill[0], "enemy"), "Damage spilling onto Team Heart names the enemy as its source")


static func _test_shield_absorbed_hit(check: Callable) -> void:
	var bundle := Mechanics.start([Mechanics.card(&"tank", 0, 9)], Mechanics.enemy([0]))
	var tank := Mechanics.to_circle(bundle.session, &"tank")
	tank.shield = 2
	var events: Array[BattleEvent] = []
	var context := EffectContext.new(bundle.session, bundle.resolver, events, {"kind": "enemy"})
	context.damage_unit(tank.instance_id, 5)
	var absorbed := _of_kind(events, &"ShieldAbsorbed")
	var damage := _of_kind(events, &"DamageApplied")
	check.call(absorbed.size() == 1 and _source_is(absorbed[0], "enemy"), "A Shield block names the source of the blocked hit")
	check.call(damage.size() == 1 and int(damage[0].data.get("absorbed", 0)) == 2 and int(damage[0].data.amount) == 3, "Damage after a Shield block records how much the Shield absorbed")

	events.clear()
	tank.shield = 4
	context.damage_unit(tank.instance_id, 1)
	check.call(_of_kind(events, &"DamageApplied").is_empty() and _of_kind(events, &"ShieldAbsorbed").size() == 1, "A fully blocked hit has no damage event")


static func _test_triggered_unit_sources(check: Callable) -> void:
	var pinger := Mechanics.card(&"pinger", 0, 9, Mechanics.triggered("round_start_effects", [Mechanics.effect(CardEffect.Kind.DAMAGE_ENEMY, 1)]))
	var avenger := Mechanics.card(&"avenger", 0, 1, Mechanics.triggered("knocked_out_effects", [Mechanics.effect(CardEffect.Kind.DAMAGE_ENEMY, 2)]))
	var bundle := Mechanics.start([pinger, avenger], Mechanics.enemy([1]))
	var avenger_card := Mechanics.to_circle(bundle.session, &"avenger")
	var pinger_card := Mechanics.to_circle(bundle.session, &"pinger")
	var events: Array[BattleEvent] = bundle.resolver.end_turn(bundle.session)
	var enemy_hits := _of_kind(events, &"DamageApplied").filter(func(event: BattleEvent): return event.data.target == "enemy")
	var from_avenger := enemy_hits.filter(func(event: BattleEvent): return _source_is(event, "unit", avenger_card.instance_id))
	var from_pinger := enemy_hits.filter(func(event: BattleEvent): return _source_is(event, "unit", pinger_card.instance_id))
	check.call(from_avenger.size() == 1 and int(from_avenger[0].data.amount) == 2, "A knocked-out ally's own effect names that ally as its source")
	check.call(from_pinger.size() == 1, "A round-start effect names the ally that owns it")


static func _test_healing_sources(check: Callable) -> void:
	var medic := Mechanics.card(&"medic", 0, 1, Mechanics.triggered("played_effects", [
		Mechanics.effect(CardEffect.Kind.HEAL_PLAYER, 3),
		Mechanics.effect(CardEffect.Kind.HEAL_ALLY, 2, CardEffect.Target.ALL_ALLIES),
	]), false)
	var bundle := Mechanics.start([medic, Mechanics.card(&"hurt", 0, 9)], Mechanics.enemy([0]))
	var hurt := Mechanics.to_circle(bundle.session, &"hurt")
	hurt.current_health = 4
	bundle.session.player_health = 20
	var played := Mechanics.to_hand(bundle.session, &"medic")
	var events: Array[BattleEvent] = bundle.resolver.play_card(bundle.session, played.instance_id)
	var heals := _of_kind(events, &"HealingApplied")
	check.call(heals.size() == 2 and _all_sourced(heals, "card", played.instance_id), "Healing from a played card names that card as its source")

	bundle = Mechanics.start([Mechanics.card(&"x", 0, 9)], Mechanics.enemy([0]))
	bundle.session.enemy.current_health = 30
	events.clear()
	var action := HealEnemyAction.new(5)
	action.resolve(EffectContext.new(bundle.session, bundle.resolver, events, {"kind": "enemy", "action": action}))
	heals = _of_kind(events, &"HealingApplied")
	check.call(heals.size() == 1 and _source_is(heals[0], "enemy") and heals[0].data.target == "enemy", "An enemy healing itself is a self-targeted effect")


static func _test_style_selection(check: Callable) -> void:
	var config: ProjectilePresentationConfig = load("res://battle/projectiles/default_projectile_config.tres")
	check.call(config != null, "The default projectile config loads")
	if config == null:
		return
	for style in [config.ally_attack, config.card_effect, config.healing, config.enemy_attack]:
		check.call(style != null and style.texture != null, "Every default projectile style has a texture")
	var plain := Mechanics.card(&"plain", 1, 1)
	var fancy := Mechanics.card(&"fancy", 1, 1)
	var brick: ProjectileStyle = load("res://battle/projectiles/barrier_brick.tres")
	fancy.projectile = brick
	var definitions := {&"plain": plain, &"fancy": fancy}
	var monster := Mechanics.enemy([1])
	var unit_hit := BattleEvent.new(&"DamageApplied", {"target": "enemy", "source": {"kind": "unit", "card_id": "plain"}})
	var card_hit := BattleEvent.new(&"DamageApplied", {"target": "enemy", "source": {"kind": "card", "card_id": "plain"}})
	var fancy_hit := BattleEvent.new(&"DamageApplied", {"target": "enemy", "source": {"kind": "card", "card_id": "fancy"}})
	var heal := BattleEvent.new(&"HealingApplied", {"target": "player", "source": {"kind": "card", "card_id": "fancy"}})
	var enemy_hit := BattleEvent.new(&"DamageApplied", {"target": "unit", "source": {"kind": "enemy", "action": DamageBoardAction.new(1)}})
	check.call(config.style_for(unit_hit, definitions, monster) == config.ally_attack, "Ally attacks default to the ally projectile")
	check.call(config.style_for(card_hit, definitions, monster) == config.card_effect, "Card effects default to the card-effect projectile")
	check.call(config.style_for(fancy_hit, definitions, monster) == brick, "A card's own projectile overrides the default")
	check.call(config.style_for(heal, definitions, monster) == config.healing, "Healing always uses the healing projectile")
	check.call(config.style_for(enemy_hit, definitions, monster) == config.enemy_attack, "Enemy hits default to the enemy projectile")
	monster.projectile = brick
	check.call(config.style_for(enemy_hit, definitions, monster) == brick, "An enemy's own projectile overrides the default")
	var heavy_action := DamageBoardAction.new(1)
	heavy_action.projectile = config.card_effect
	var heavy_hit := BattleEvent.new(&"DamageApplied", {"target": "unit", "source": {"kind": "enemy", "action": heavy_action}})
	check.call(config.style_for(heavy_hit, definitions, monster) == config.card_effect, "An enemy action's projectile overrides the enemy's")


# ------------------------------------------------------------------- scene

static func _open_battle(tree: SceneTree, delay: float, reduce_motion: bool) -> Node:
	var battle_ui = load("res://battle/battle_scene.tscn").instantiate()
	var controller: BattleController = battle_ui.get_node("BattleController")
	controller.presentation_delay = delay
	battle_ui.reduce_motion_override = 1 if reduce_motion else 0
	tree.root.add_child(battle_ui)
	await tree.process_frame
	await _settle(controller, tree)
	return battle_ui


## Waits (in real time, since headless frames can be very fast) until presentation unlocks input.
static func _settle(controller: BattleController, tree: SceneTree, watch: Control = null) -> int:
	var started := Time.get_ticks_msec()
	var most_in_flight := 0
	while controller.input_locked and Time.get_ticks_msec() - started < 10000:
		if watch != null:
			most_in_flight = maxi(most_in_flight, watch.get_child_count())
		await tree.process_frame
	return most_in_flight


static func _ally_vs(attack_pattern: Array) -> Dictionary:
	var rules := BattleRules.new()
	rules.starting_hand_size = 0
	rules.cards_drawn_per_turn = 0
	return {
		"deck": [Mechanics.card(&"helper", 2, 9), Mechanics.card(&"helper2", 2, 9)],
		"enemy": Mechanics.enemy(attack_pattern, 40),
		"rules": rules,
	}


static func _seat_allies(controller: BattleController) -> void:
	for id in [&"helper", &"helper2"]:
		var card := Mechanics.to_circle(controller.session, id)
		card.has_attacked_this_turn = false


static func _test_instant_presentation(check: Callable, tree: SceneTree) -> void:
	var battle_ui = await _open_battle(tree, 0.0, false)
	var controller: BattleController = battle_ui.get_node("BattleController")
	var setup := _ally_vs([3])
	controller.start_battle(setup.deck, setup.enemy, setup.rules, 1)
	_seat_allies(controller)
	controller.session_changed.emit()
	controller.request_end_turn()
	check.call(not controller.input_locked, "Instant presentation resolves a whole enemy round synchronously")
	var projectiles: Control = battle_ui.find_child("Projectiles", true, false)
	check.call(projectiles != null and projectiles.get_child_count() == 0, "Instant presentation launches no projectiles")
	var health_bar: ProgressBar = battle_ui.find_child("MonsterHealthBar", true, false)
	check.call(health_bar.value == controller.session.enemy.current_health, "Instant presentation ends on the final monster Heart")
	battle_ui.free()


static func _test_paced_presentation(check: Callable, tree: SceneTree) -> void:
	var battle_ui = await _open_battle(tree, 0.01, false)
	var controller: BattleController = battle_ui.get_node("BattleController")
	var setup := _ally_vs([3])
	controller.start_battle(setup.deck, setup.enemy, setup.rules, 1)
	await _settle(controller, tree)
	_seat_allies(controller)
	controller.session_changed.emit()
	var helper: CardInstance = controller.session.battlefield[0]
	var health_bar: ProgressBar = battle_ui.find_child("MonsterHealthBar", true, false)
	var before := int(health_bar.value)
	controller.request_attack_enemy(helper.instance_id)
	check.call(controller.input_locked, "Paced presentation locks input while a projectile flies")
	check.call(int(health_bar.value) == before, "Monster Heart waits for the projectile to land")
	var projectiles: Control = battle_ui.find_child("Projectiles", true, false)
	var launched := await _settle(controller, tree, projectiles) > 0
	check.call(launched, "An ally attack launches a projectile")
	check.call(not controller.input_locked, "Input unlocks after the projectile lands")
	check.call(int(health_bar.value) == before - 2, "Monster Heart drops when the projectile lands")

	var ally_view: CardBase = battle_ui._card_views_by_instance.get(controller.session.battlefield[0].instance_id)
	var ally_health_before := controller.session.battlefield[0].current_health
	controller.request_end_turn()
	var ally_view_health_mid := ally_view.get_displayed_health() if is_instance_valid(ally_view) else -1
	check.call(ally_view_health_mid == ally_health_before, "Ally Heart waits for enemy projectiles to land")
	var max_in_flight := await _settle(controller, tree, projectiles)
	check.call(max_in_flight >= 2, "A spread volley has several projectiles in flight at once")
	check.call(not controller.input_locked and projectiles.get_child_count() == 0, "The round ends only after every projectile has landed")
	battle_ui.free()


static func _test_reduce_motion_presentation(check: Callable, tree: SceneTree) -> void:
	var battle_ui = await _open_battle(tree, 0.01, true)
	var controller: BattleController = battle_ui.get_node("BattleController")
	var setup := _ally_vs([3])
	controller.start_battle(setup.deck, setup.enemy, setup.rules, 1)
	await _settle(controller, tree)
	_seat_allies(controller)
	controller.session_changed.emit()
	controller.request_end_turn()
	check.call(controller.input_locked, "Reduce motion still paces hits one at a time")
	var projectiles: Control = battle_ui.find_child("Projectiles", true, false)
	var launched := await _settle(controller, tree, projectiles) > 0
	check.call(not launched, "Reduce motion replaces flights with pulses")
	check.call(not controller.input_locked, "Reduce motion presentation completes")
	battle_ui.free()
