extends RefCounted
## Domain tests for card trigger hooks, data-driven effects, keywords and statuses.
## Uses synthetic definitions so rules are tested independently of card content.


static func run(check: Callable) -> void:
	_test_round_start_order_and_timing(check)
	_test_round_end_before_enemy(check)
	_test_knocked_out(check)
	_test_card_played_filters(check)
	_test_scaled_amounts(check)
	_test_bank_spark(check)
	_test_shared_single_ally_pick(check)
	_test_simple_effects(check)
	_test_guard(check)
	_test_shield(check)
	_test_quick(check)
	_test_calm(check)
	_test_exposed(check)
	_test_status_presentation_text(check)


# ------------------------------------------------------------------ helpers

static func effect(kind: CardEffect.Kind, amount: int, target := CardEffect.Target.THIS_CARD, scale := CardEffect.Scale.NONE) -> CardEffect:
	var result := CardEffect.new()
	result.kind = kind
	result.amount = amount
	result.target = target
	result.scale = scale
	return result


static func card(id: StringName, attack: int = 0, health: int = 5, behavior: CardBehavior = null, unit := true) -> CardDefinition:
	var definition := CardDefinition.new()
	definition.id = id
	definition.display_name = String(id)
	definition.card_type = CardDefinition.CardType.UNIT if unit else CardDefinition.CardType.ACTION
	definition.attack = attack if unit else 0
	definition.health = health
	definition.cost = 0
	definition.behavior = behavior
	return definition


static func triggered(hook: String, effects: Array, filter := TriggeredCardBehavior.CardFilter.ANY) -> TriggeredCardBehavior:
	var behavior := TriggeredCardBehavior.new()
	var typed: Array[CardEffect] = []
	typed.assign(effects)
	behavior.set(hook, typed)
	behavior.card_played_filter = filter
	return behavior


static func enemy(pattern: Array = [4], health: int = 40) -> EnemyDefinition:
	var definition := EnemyDefinition.new()
	definition.id = &"test_barrier"
	definition.display_name = "Test Barrier"
	definition.maximum_health = health
	var behavior := PatternEnemyBehavior.new()
	behavior.attack_pattern = PackedInt32Array(pattern)
	definition.behavior = behavior
	return definition


## Starts a battle with an empty hand and no per-round draws; cards stay in the draw pile.
static func start(definitions: Array, enemy_definition: EnemyDefinition = null) -> Dictionary:
	var rules := BattleRules.new()
	rules.starting_hand_size = 0
	rules.cards_drawn_per_turn = 0
	var session := BattleSession.new()
	session.initialize(definitions, enemy_definition if enemy_definition != null else enemy(), rules, 777)
	var resolver := ActionResolver.new()
	resolver.start_battle(session)
	return {"session": session, "resolver": resolver}


static func to_hand(session: BattleSession, id: StringName) -> CardInstance:
	for instance in session.draw_pile:
		if instance.definition.id == id:
			session.draw_pile.erase(instance)
			session.hand.append(instance)
			return instance
	return null


## Moves a card straight into the Ally Circle (ready to help next round) without playing it.
static func to_circle(session: BattleSession, id: StringName) -> CardInstance:
	for instance in session.draw_pile:
		if instance.definition.id == id:
			session.draw_pile.erase(instance)
			session.battlefield.append(instance)
			return instance
	return null


static func count(events: Array[BattleEvent], kind: StringName) -> int:
	var total := 0
	for event in events:
		if event.kind == kind:
			total += 1
	return total


# -------------------------------------------------------------------- hooks

static func _test_round_start_order_and_timing(check: Callable) -> void:
	var exposer := card(&"exposer", 0, 9, triggered("round_start_effects", [effect(CardEffect.Kind.APPLY_EXPOSED, 2)]))
	var pinger := card(&"pinger", 0, 9, triggered("round_start_effects", [effect(CardEffect.Kind.DAMAGE_ENEMY, 1)]))
	var bundle := start([exposer, pinger], enemy([0]))
	var session: BattleSession = bundle.session
	to_circle(session, &"exposer")
	to_circle(session, &"pinger")
	bundle.resolver.end_turn(session)
	check.call(session.enemy.current_health == 37, "Round-start hooks run in Ally Circle order (Exposed 2 then a 1 ping = 3)")
	check.call(session.enemy.exposed == 0, "The ping used up the Exposed stack")

	var helper := card(&"helper", 2, 9, triggered("round_start_effects", [effect(CardEffect.Kind.APPLY_EXPOSED, 1)]))
	bundle = start([helper], enemy([0]))
	session = bundle.session
	to_circle(session, &"helper")
	bundle.resolver.end_turn(session)
	check.call(session.enemy.current_health == 37, "Round-start hooks resolve before automatic ally help (2 Power + Exposed 1)")
	check.call(session.phase == BattleSession.Phase.PLAYER_TURN, "The player round resumes after round-start hooks")


static func _test_round_end_before_enemy(check: Callable) -> void:
	var calmer := card(&"calmer", 0, 9, triggered("round_end_effects", [effect(CardEffect.Kind.APPLY_CALM, 4)]))
	var bundle := start([calmer], enemy([4]))
	var session: BattleSession = bundle.session
	var ally := to_circle(session, &"calmer")
	var events: Array[BattleEvent] = bundle.resolver.end_turn(session)
	check.call(ally.current_health == 9 and session.player_health == 30, "Round-end Calm resolves before the enemy acts")
	check.call(session.enemy.calm == 0 and count(events, &"CalmUsed") == 1, "The enemy action used up the Calm")


static func _test_knocked_out(check: Callable) -> void:
	var drawer := card(&"drawer", 0, 1, triggered("knocked_out_effects", [
		effect(CardEffect.Kind.DRAW_CARDS, 1),
		effect(CardEffect.Kind.MODIFY_POWER, 1, CardEffect.Target.ALL_ALLIES),
	]))
	var sturdy := card(&"sturdy", 0, 20)
	var filler := card(&"filler", 0, 3)
	var bundle := start([drawer, sturdy, filler], enemy([2]))
	var session: BattleSession = bundle.session
	var falling := to_circle(session, &"drawer")
	var survivor := to_circle(session, &"sturdy")
	var events: Array[BattleEvent] = bundle.resolver.end_turn(session)
	check.call(session.find_battlefield_card(falling.instance_id) == null, "A 1-Heart ally is knocked out")
	check.call(session.hand.size() == 1 and session.hand[0].definition.id == &"filler", "Knocked-out hook draws a card")
	check.call(survivor.current_attack == 1 and falling.current_attack == 0, "Knocked-out ally has already left when its effect resolves")
	check.call(count(events, &"CardDestroyed") == 1, "Knock-out is reported once")

	var copier := card(&"copier", 0, 1, triggered("knocked_out_effects", [effect(CardEffect.Kind.COPY_TO_HAND, 1)]))
	bundle = start([copier], enemy([1]))
	session = bundle.session
	to_circle(session, &"copier")
	bundle.resolver.end_turn(session)
	check.call(session.hand.size() == 1 and session.hand[0].definition.id == &"copier", "A knocked-out ally can add a copy of itself to hand")


static func _test_card_played_filters(check: Callable) -> void:
	var one_shot_pinger := card(&"oneshot_pinger", 0, 9, triggered("card_played_effects", [effect(CardEffect.Kind.DAMAGE_ENEMY, 1)], TriggeredCardBehavior.CardFilter.ONE_SHOTS))
	var ally_buffer := card(&"ally_buffer", 0, 9, triggered("card_played_effects", [effect(CardEffect.Kind.MODIFY_POWER, 1, CardEffect.Target.NEWEST_ALLY)], TriggeredCardBehavior.CardFilter.ALLIES))
	var any_grower := card(&"any_grower", 0, 9, triggered("card_played_effects", [effect(CardEffect.Kind.MODIFY_POWER, 1)]))
	var spell := card(&"plain_spell", 0, 1, null, false)
	var friend := card(&"plain_friend", 1, 3)
	var bundle := start([one_shot_pinger, ally_buffer, any_grower, spell, friend], enemy([0]))
	var session: BattleSession = bundle.session
	to_circle(session, &"oneshot_pinger")
	var grower := to_hand(session, &"any_grower")
	bundle.resolver.play_card(session, grower.instance_id)
	check.call(grower.current_attack == 0, "An ally's on_card_played does not fire for itself")
	check.call(session.enemy.current_health == 40, "One-shot filter ignores a played ally")
	to_circle(session, &"ally_buffer")
	var spell_instance := to_hand(session, &"plain_spell")
	bundle.resolver.play_card(session, spell_instance.instance_id)
	check.call(session.enemy.current_health == 39, "One-shot filter fires when a one-shot is played")
	check.call(grower.current_attack == 1, "Any filter fires for another played card")
	var friend_instance := to_hand(session, &"plain_friend")
	bundle.resolver.play_card(session, friend_instance.instance_id)
	check.call(friend_instance.current_attack == 2, "Ally filter fires after the played ally joins, so it is the newest ally")
	check.call(session.enemy.current_health == 39, "One-shot filter still ignores allies")


static func _test_scaled_amounts(check: Callable) -> void:
	var march := card(&"march", 0, 1, triggered("played_effects", [effect(CardEffect.Kind.DAMAGE_ENEMY, 2, CardEffect.Target.THIS_CARD, CardEffect.Scale.ALLIES_IN_CIRCLE)]), false)
	var a := card(&"a", 0, 5)
	var b := card(&"b", 0, 5)
	var c := card(&"c", 0, 5)
	var bundle := start([march, a, b, c], enemy([0]))
	var session: BattleSession = bundle.session
	for id in [&"a", &"b", &"c"]:
		to_circle(session, id)
	bundle.resolver.play_card(session, to_hand(session, &"march").instance_id)
	check.call(session.enemy.current_health == 34, "Scaled damage counts allies in the circle (2 x 3)")

	var captain := card(&"captain", 0, 3, triggered("played_effects", [effect(CardEffect.Kind.DAMAGE_ENEMY, 2, CardEffect.Target.THIS_CARD, CardEffect.Scale.ALLIES_IN_CIRCLE)]))
	bundle = start([captain, a], enemy([0]))
	session = bundle.session
	to_circle(session, &"a")
	bundle.resolver.play_card(session, to_hand(session, &"captain").instance_id)
	check.call(session.enemy.current_health == 38, "An ally's own on_played counts only the other allies")

	var booster := card(&"booster", 0, 1, triggered("played_effects", [
		effect(CardEffect.Kind.APPLY_EXPOSED, 1),
		effect(CardEffect.Kind.APPLY_EXPOSED, 1, CardEffect.Target.THIS_CARD, CardEffect.Scale.ENEMY_EXPOSED),
	]), false)
	bundle = start([booster], enemy([0]))
	session = bundle.session
	session.enemy.exposed = 2
	bundle.resolver.play_card(session, to_hand(session, &"booster").instance_id)
	check.call(session.enemy.exposed == 6, "Exposed-scaled effect doubles the stack after adding 1 (2+1 -> 6)")


static func _test_bank_spark(check: Callable) -> void:
	var planner := card(&"planner", 0, 1, triggered("played_effects", [effect(CardEffect.Kind.BANK_SPARK, 3)]), false)
	var bundle := start([planner], enemy([0]))
	var session: BattleSession = bundle.session
	bundle.resolver.play_card(session, to_hand(session, &"planner").instance_id)
	check.call(session.current_energy == 5 and session.banked_energy == 3, "Banked Spark is not gained this round")
	bundle.resolver.end_turn(session)
	check.call(session.current_energy == 8 and session.banked_energy == 0, "Banked Spark arrives at the start of the next round")
	bundle.resolver.end_turn(session)
	check.call(session.current_energy == 5, "Banked Spark is a one-time bonus")


static func _test_shared_single_ally_pick(check: Callable) -> void:
	var service := card(&"service", 0, 1, triggered("played_effects", [
		effect(CardEffect.Kind.HEAL_ALLY, 3, CardEffect.Target.LOWEST_HEART_ALLY),
		effect(CardEffect.Kind.GIVE_SHIELD, 2, CardEffect.Target.LOWEST_HEART_ALLY),
	]), false)
	var low := card(&"low", 0, 5)
	var mid := card(&"mid", 0, 5)
	var bundle := start([service, low, mid], enemy([0]))
	var session: BattleSession = bundle.session
	var low_ally := to_circle(session, &"low")
	var mid_ally := to_circle(session, &"mid")
	low_ally.current_health = 1
	mid_ally.current_health = 3
	bundle.resolver.play_card(session, to_hand(session, &"service").instance_id)
	check.call(low_ally.current_health == 4 and low_ally.shield == 2, "Lines in one hook reuse the same lowest-Heart ally")
	check.call(mid_ally.shield == 0, "The other ally is not shielded")


static func _test_simple_effects(check: Callable) -> void:
	var kit := card(&"kit", 0, 1, triggered("played_effects", [
		effect(CardEffect.Kind.HEAL_PLAYER, 4),
		effect(CardEffect.Kind.GAIN_SPARK, 2),
		effect(CardEffect.Kind.DRAW_CARDS, 1),
		effect(CardEffect.Kind.HEAL_ALLY, 2, CardEffect.Target.ALL_ALLIES),
		effect(CardEffect.Kind.MODIFY_POWER, 2, CardEffect.Target.NEWEST_ALLY),
	]), false)
	var first := card(&"first", 1, 5)
	var second := card(&"second", 1, 5)
	var spare := card(&"spare", 0, 2)
	var bundle := start([kit, first, second, spare], enemy([0]))
	var session: BattleSession = bundle.session
	session.player_health = 20
	var first_ally := to_circle(session, &"first")
	var second_ally := to_circle(session, &"second")
	first_ally.current_health = 2
	second_ally.current_health = 4
	bundle.resolver.play_card(session, to_hand(session, &"kit").instance_id)
	check.call(session.player_health == 24, "Heal-player effect restores Team Heart")
	check.call(session.current_energy == 7, "Gain-Spark effect adds Spark this round")
	check.call(session.hand.size() == 1, "Draw effect draws a card")
	check.call(first_ally.current_health == 4 and second_ally.current_health == 5, "Heal-all-allies clamps at maximum Heart")
	check.call(second_ally.current_attack == 3 and first_ally.current_attack == 1, "Newest-ally Power buff targets the last ally to join")


# ------------------------------------------------------------ keywords/status

static func _test_guard(check: Callable) -> void:
	var normal := card(&"normal", 0, 5)
	var guard := card(&"guard", 0, 3)
	guard.guard = true
	var bundle := start([normal, guard], enemy([4]))
	var session: BattleSession = bundle.session
	var normal_ally := to_circle(session, &"normal")
	var guard_ally := to_circle(session, &"guard")
	bundle.resolver.end_turn(session)
	check.call(session.find_battlefield_card(guard_ally.instance_id) == null, "Guard ally absorbs board damage first and is knocked out")
	check.call(normal_ally.current_health == 4, "Only leftover damage reaches non-Guard allies")
	check.call(session.player_health == 30, "No damage spills while allies remain")

	var guard_a := card(&"guard_a", 0, 9)
	guard_a.guard = true
	var guard_b := card(&"guard_b", 0, 9)
	guard_b.guard = true
	bundle = start([normal, guard_a, guard_b], enemy([4]))
	session = bundle.session
	var plain := to_circle(session, &"normal")
	var ga := to_circle(session, &"guard_a")
	var gb := to_circle(session, &"guard_b")
	bundle.resolver.end_turn(session)
	check.call(ga.current_health == 7 and gb.current_health == 7 and plain.current_health == 5, "Damage spreads across multiple Guard allies, sparing others")


static func _test_shield(check: Callable) -> void:
	var shielder := card(&"shielder", 0, 1, triggered("played_effects", [effect(CardEffect.Kind.GIVE_SHIELD, 1, CardEffect.Target.ALL_ALLIES)]), false)
	var wall := card(&"wall", 0, 3, triggered("played_effects", [effect(CardEffect.Kind.GIVE_SHIELD, 2)]))
	var bundle := start([shielder, wall], enemy([3]))
	var session: BattleSession = bundle.session
	var wall_ally := to_hand(session, &"wall")
	bundle.resolver.play_card(session, wall_ally.instance_id)
	check.call(wall_ally.shield == 2, "An ally can shield itself as it joins")
	bundle.resolver.play_card(session, to_hand(session, &"shielder").instance_id)
	check.call(wall_ally.shield == 3, "Shield stacks")
	var events: Array[BattleEvent] = bundle.resolver.end_turn(session)
	check.call(wall_ally.current_health == 3 and wall_ally.shield == 0, "Shield absorbs damage before Heart")
	check.call(count(events, &"ShieldAbsorbed") == 3, "Each absorbed hit is reported")
	bundle.resolver.give_shield(session, wall_ally, 4, events)
	session.battlefield.erase(wall_ally)
	session.draw_pile.append(wall_ally)
	bundle.resolver.draw_cards(session, 1, events)
	check.call(wall_ally.shield == 0, "Shield resets when the card is redrawn")


static func _test_quick(check: Callable) -> void:
	var quick := card(&"quick", 3, 2)
	quick.quick = true
	var slow := card(&"slow", 3, 2)
	var bundle := start([quick, slow], enemy([0]))
	var session: BattleSession = bundle.session
	var quick_ally := to_hand(session, &"quick")
	var slow_ally := to_hand(session, &"slow")
	bundle.resolver.play_card(session, quick_ally.instance_id)
	bundle.resolver.play_card(session, slow_ally.instance_id)
	check.call(bundle.resolver.can_attack_enemy(session, quick_ally.instance_id), "Quick ally can help on the round it is played")
	check.call(not bundle.resolver.can_attack_enemy(session, slow_ally.instance_id), "Other allies still rest on their first round")
	bundle.resolver.attack_enemy(session, quick_ally.instance_id)
	check.call(session.enemy.current_health == 37, "Quick ally helps for its Power")


static func _test_calm(check: Callable) -> void:
	var bundle := start([card(&"target", 0, 9)], enemy([3, 6]))
	var session: BattleSession = bundle.session
	var ally := to_circle(session, &"target")
	var events: Array[BattleEvent] = []
	bundle.resolver.apply_enemy_status(session, 2, 0, events)
	bundle.resolver.apply_enemy_status(session, 3, 0, events)
	check.call(session.enemy.calm == 5, "Calm stacks")
	bundle.resolver.end_turn(session)
	check.call(ally.current_health == 9 and session.enemy.calm == 0, "Calm 5 prevents a 3-damage action and the whole stack is used up")
	bundle.resolver.end_turn(session)
	check.call(ally.current_health == 3, "The next enemy action deals full damage")
	bundle.resolver.apply_enemy_status(session, 2, 0, events)
	var direct := DamagePlayerAction.new(5)
	direct.resolve(EffectContext.new(session, bundle.resolver, events))
	check.call(session.player_health == 27 and session.enemy.calm == 0, "Calm also reduces direct Team Heart damage from the enemy")


static func _test_exposed(check: Callable) -> void:
	var bolt := card(&"bolt", 0, 1, triggered("played_effects", [effect(CardEffect.Kind.DAMAGE_ENEMY, 4)]), false)
	var bundle := start([bolt, bolt], enemy([0]))
	var session: BattleSession = bundle.session
	var events: Array[BattleEvent] = []
	bundle.resolver.apply_enemy_status(session, 0, 2, events)
	bundle.resolver.apply_enemy_status(session, 0, 1, events)
	check.call(session.enemy.exposed == 3, "Exposed stacks")
	bundle.resolver.play_card(session, to_hand(session, &"bolt").instance_id)
	check.call(session.enemy.current_health == 33 and session.enemy.exposed == 0, "Exposed adds to the next damage instance and is used up")
	bundle.resolver.play_card(session, to_hand(session, &"bolt").instance_id)
	check.call(session.enemy.current_health == 29, "Later damage is not boosted")


static func _test_status_presentation_text(check: Callable) -> void:
	var ui_script: GDScript = load("res://battle/battle_ui.gd")
	var barrier := EnemyInstance.new(enemy())
	check.call(ui_script.enemy_status_text(barrier).is_empty(), "Status badge is empty without Calm or Exposed")
	barrier.calm = 2
	barrier.exposed = 3
	check.call(ui_script.enemy_status_text(barrier) == "CALM 2  •  EXPOSED 3", "Status badge lists Calm and Exposed")
	var ally := CardInstance.new(card(&"badge_ally"), 1)
	check.call(ui_script.ally_footer_text(ally, true) == "READY TO HELP", "Ready ally footer is unchanged without Shield")
	ally.shield = 2
	check.call(ui_script.ally_footer_text(ally, false) == "SHIELD 2", "Shielded ally shows its Shield")
