extends RefCounted
## Content tests for the card expansion: every new card's definition, its
## behavior in a standard scenario, and scripted battles that play every card.

const UNIT := CardDefinition.CardType.UNIT
const ACTION := CardDefinition.CardType.ACTION

## id: [display name, type, cost, Power, Heart]
const NEW_CARDS := {
	&"hearing_aid_hedgehog": ["Hearing-Aid Hedgehog", UNIT, 1, 1, 3],
	&"spoon_saving_squirrel": ["Spoon-Saving Squirrel", UNIT, 1, 1, 2],
	&"forearm_crutch_flamingo": ["Forearm-Crutch Flamingo", UNIT, 2, 2, 3],
	&"tablet_talking_tapir": ["Tablet-Talking Tapir", UNIT, 2, 1, 4],
	&"stuttering_starling": ["Stuttering Starling", UNIT, 2, 1, 3],
	&"cane_tapping_kiwi": ["Cane-Tapping Kiwi", UNIT, 2, 1, 4],
	&"magnifier_meerkat": ["Magnifier Meerkat", UNIT, 2, 2, 3],
	&"sun_seeking_lemur": ["Sun-Seeking Lemur", UNIT, 2, 1, 4],
	&"safety_plan_seal": ["Safety-Plan Seal", UNIT, 2, 2, 3],
	&"brace_wearing_badger": ["Brace-Wearing Badger", UNIT, 2, 2, 3],
	&"dyspraxic_dolphin": ["Dyspraxic Dolphin", UNIT, 2, 2, 2],
	&"calculator_crow": ["Calculator Crow", UNIT, 3, 1, 4],
	&"walker_wombat": ["Walker Wombat", UNIT, 3, 2, 5],
	&"worry_wise_pangolin": ["Worry-Wise Pangolin", UNIT, 3, 2, 4],
	&"noise_cancelling_narwhal": ["Noise-Cancelling Narwhal", UNIT, 3, 2, 5],
	&"team_captain_otter": ["Team-Captain Otter", UNIT, 3, 2, 3],
	&"tourettes_toucan": ["Tourette's Toucan", UNIT, 3, 2, 4],
	&"insulin_pump_iguana": ["Insulin-Pump Iguana", UNIT, 2, 2, 3],
	&"oxygen_owl": ["Oxygen Owl", UNIT, 3, 2, 4],
	&"buddy_bird_capybara": ["Buddy-Bird Capybara", UNIT, 4, 2, 6],
	&"tripod_tiger": ["Tripod Tiger", UNIT, 4, 3, 6],
	&"racing_chair_cheetah": ["Racing-Chair Cheetah", UNIT, 5, 5, 3],
	&"deaf_elephant": ["Deaf Elephant", UNIT, 5, 4, 8],
	&"stim_toy": ["Stim Toy", ACTION, 0, 0, 1],
	&"captions_on": ["Captions On", ACTION, 1, 0, 1],
	&"call_it_out": ["Call It Out", ACTION, 1, 0, 1],
	&"signal_boost": ["Signal Boost", ACTION, 1, 0, 1],
	&"accessibility_audit": ["Accessibility Audit", ACTION, 3, 0, 1],
	&"pride_march": ["Pride March", ACTION, 3, 0, 1],
	&"celebrate_wins": ["Celebrate Wins", ACTION, 3, 0, 1],
	&"pass_the_mic": ["Pass the Mic", ACTION, 2, 0, 1],
	&"invite_a_friend": ["Invite a Friend", ACTION, 2, 0, 1],
	&"build_a_ramp": ["Build a Ramp", ACTION, 2, 0, 1],
	&"service_dog_help": ["Service Dog Help", ACTION, 1, 0, 1],
	&"quiet_room": ["Quiet Room", ACTION, 2, 0, 1],
	&"flexible_deadline": ["Flexible Deadline", ACTION, 2, 0, 1],
	&"weighted_blanket": ["Weighted Blanket", ACTION, 1, 0, 1],
	&"spoon_theory": ["Spoon Theory", ACTION, 1, 0, 1],
}

const GUARD_CARDS: Array[StringName] = [
	&"hearing_aid_hedgehog", &"walker_wombat", &"tripod_tiger", &"deaf_elephant",
	&"shield_bot", &"prosthetic_paw_puppy",
]
const QUICK_CARDS: Array[StringName] = [&"racing_chair_cheetah", &"adhd_red_panda"]

## Scenario per card: [mode, {measure: expected value}]. Unlisted measures must be 0.
## Modes: played, round_start, round_end, knocked_out, card_played.
## The Ally Circle starts with dummy A (Heart 2 of 6) then dummy B (6 of 6), both 0 Power.
const SCENARIOS := {
	&"hearing_aid_hedgehog": ["knocked_out", {"exposed": 2}],
	&"spoon_saving_squirrel": ["round_start", {"spark": 1, "enemy": 1}],
	&"forearm_crutch_flamingo": ["played", {"a_shield": 1, "b_shield": 1}],
	&"tablet_talking_tapir": ["card_played", {"enemy": 1}],
	&"stuttering_starling": ["card_played", {"self_power": 2}],
	&"cane_tapping_kiwi": ["card_played", {"exposed": 1}],
	&"magnifier_meerkat": ["round_start", {"enemy": 3}],
	&"sun_seeking_lemur": ["round_start", {"a_hp": 2, "enemy": 1}],
	&"safety_plan_seal": ["played", {"calm": 3}],
	&"brace_wearing_badger": ["knocked_out", {"hand": 2}],
	&"dyspraxic_dolphin": ["knocked_out", {"hand": 1, "copied_self": 1}],
	&"calculator_crow": ["played", {"hand": 2}],
	&"walker_wombat": ["played", {"self_shield": 3}],
	&"worry_wise_pangolin": ["round_end", {"a_shield": 2, "enemy": 2}],
	&"noise_cancelling_narwhal": ["card_played", {"calm": 1}],
	&"team_captain_otter": ["played", {"enemy": 4}],
	&"tourettes_toucan": ["card_played", {"newest_power": 1}],
	&"insulin_pump_iguana": ["round_start", {"player": 2, "enemy": 2}],
	&"oxygen_owl": ["played", {"a_power": 1, "b_power": 1}],
	&"buddy_bird_capybara": ["round_end", {"calm": 2, "enemy": 2}],
	&"tripod_tiger": ["knocked_out", {"a_shield": 2, "b_shield": 2}],
	&"racing_chair_cheetah": ["played", {"self_ready": 1}],
	&"deaf_elephant": ["played", {"calm": 2}],
	&"stim_toy": ["played", {"hand": 1}],
	&"captions_on": ["played", {"exposed": 2, "hand": 1}],
	&"call_it_out": ["played", {"exposed": 3}],
	&"signal_boost": ["played", {"exposed": 2}],
	&"accessibility_audit": ["played", {"enemy": 7}],
	&"pride_march": ["played", {"enemy": 4}],
	&"celebrate_wins": ["played", {"a_power": 1, "b_power": 1}],
	&"pass_the_mic": ["played", {"b_power": 2}],
	&"invite_a_friend": ["played", {"hand": 1}],
	&"build_a_ramp": ["played", {"a_shield": 2, "b_shield": 2}],
	&"service_dog_help": ["played", {"a_hp": 3, "a_shield": 2}],
	&"quiet_room": ["played", {"calm": 5}],
	&"flexible_deadline": ["played", {"calm": 3, "hand": 1}],
	&"weighted_blanket": ["played", {"calm": 2, "a_shield": 2}],
	&"spoon_theory": ["played", {"banked": 3, "hand": 1}],
	# Reworked existing cards.
	&"deaf_deer": ["played", {"exposed": 2}],
	&"grounding_alpaca": ["round_end", {"calm": 1, "enemy": 1}],
	&"adhd_red_panda": ["played", {"self_ready": 1}],
}

const MEASURES := [
	"enemy", "calm", "exposed", "player", "spark", "banked", "hand",
	"a_power", "b_power", "a_shield", "b_shield", "a_hp",
	"self_power", "self_shield", "self_ready", "newest_power", "copied_self",
]


static func run(check: Callable, catalog: Node) -> void:
	_test_new_definitions(check, catalog)
	_test_card_scenarios(check, catalog)
	_test_every_card_in_battle(check, catalog)
	_test_full_collection_battles(check, catalog)


static func _test_new_definitions(check: Callable, catalog: Node) -> void:
	for card_id in NEW_CARDS:
		var card: CardDefinition = catalog.get_card(card_id)
		var expected: Array = NEW_CARDS[card_id]
		check.call(card != null, "%s resource loads" % card_id)
		if card == null:
			continue
		check.call(card.display_name == expected[0], "%s has its roster name" % card_id)
		check.call(card.card_type == expected[1] and card.cost == expected[2], "%s has its roster type and cost" % card_id)
		check.call(card.attack == expected[3] and card.health == expected[4], "%s has its roster Power and Heart" % card_id)
	for card in catalog.get_all_cards():
		check.call(card.description.length() <= 110, "%s rules text fits in 110 characters" % card.id)
		check.call(card.guard == GUARD_CARDS.has(card.id), "%s Guard keyword matches the roster" % card.id)
		check.call(card.quick == QUICK_CARDS.has(card.id), "%s Quick keyword matches the roster" % card.id)
		check.call(card.guard == card.description.begins_with("Guard."), "%s rules text names Guard when it has it" % card.id)
		check.call(card.quick == card.description.begins_with("Quick."), "%s rules text names Quick when it has it" % card.id)
		check.call(card.artwork != null and card.artwork.get_width() == 1024 and card.artwork.get_height() == 1024, "%s has 1024x1024 artwork" % card.id)
		check.call(card.visual_style != null, "%s has a card color style" % card.id)


# --------------------------------------------------------------- scenarios

static func _dummy(id: StringName, health: int) -> CardDefinition:
	var definition := CardDefinition.new()
	definition.id = id
	definition.display_name = String(id)
	definition.health = health
	return definition


static func _filler_spell() -> CardDefinition:
	var definition := CardDefinition.new()
	definition.id = &"filler_spell"
	definition.display_name = "Filler Spell"
	definition.card_type = ACTION
	return definition


static func _quiet_enemy() -> EnemyDefinition:
	var definition := EnemyDefinition.new()
	definition.id = &"quiet_test_barrier"
	definition.display_name = "Quiet Test Barrier"
	definition.maximum_health = 60
	var behavior := PatternEnemyBehavior.new()
	behavior.attack_pattern = PackedInt32Array([0])
	definition.behavior = behavior
	return definition


static func _take(session: BattleSession, id: StringName) -> CardInstance:
	for instance in session.draw_pile:
		if instance.definition.id == id:
			session.draw_pile.erase(instance)
			return instance
	return null


static func _test_card_scenarios(check: Callable, catalog: Node) -> void:
	for card_id in SCENARIOS:
		var card: CardDefinition = catalog.get_card(card_id)
		if card == null:
			check.call(false, "%s exists for its scenario" % card_id)
			continue
		var measured := _run_scenario(card, SCENARIOS[card_id][0])
		var expected: Dictionary = SCENARIOS[card_id][1]
		for measure in MEASURES:
			var want := int(expected.get(measure, 0))
			check.call(
				int(measured[measure]) == want,
				"%s (%s): %s is %d (got %d)" % [card_id, SCENARIOS[card_id][0], measure, want, int(measured[measure])]
			)


static func _run_scenario(card: CardDefinition, mode: String) -> Dictionary:
	var rules := BattleRules.new()
	rules.starting_hand_size = 0
	rules.cards_drawn_per_turn = 0
	var deck: Array = [card, _dummy(&"dummy_a", 6), _dummy(&"dummy_b", 6), _dummy(&"filler_friend", 3)]
	for _index in 4:
		deck.append(_filler_spell())
	var session := BattleSession.new()
	session.initialize(deck, _quiet_enemy(), rules, 99)
	var resolver := ActionResolver.new()
	resolver.start_battle(session)
	var a := _take(session, &"dummy_a")
	var b := _take(session, &"dummy_b")
	session.battlefield.append(a)
	session.battlefield.append(b)
	a.current_health = 2
	var self_card := _take(session, card.id)
	session.player_health = 20
	session.current_energy = 20
	var before := {
		"enemy": session.enemy.current_health,
		"player": session.player_health,
		"hand": session.hand.size(),
		"a_hp": a.current_health,
	}
	var events: Array[BattleEvent] = []
	var spark_base := 20
	match mode:
		"played":
			session.hand.append(self_card)
			before.hand = session.hand.size() - 1
			spark_base = 20 - card.cost
			resolver.play_card(session, self_card.instance_id)
		"round_start", "round_end":
			session.battlefield.append(self_card)
			resolver.end_turn(session)
			spark_base = rules.energy_per_turn
		"knocked_out":
			session.battlefield.append(self_card)
			resolver.apply_unit_damage(session, self_card.instance_id, 99, events)
		"card_played":
			session.battlefield.append(self_card)
			var spell := _take(session, &"filler_spell")
			var friend := _take(session, &"filler_friend")
			session.hand.append(spell)
			session.hand.append(friend)
			before.hand = session.hand.size() - 2
			resolver.play_card(session, spell.instance_id)
			resolver.play_card(session, friend.instance_id)
	var newest: CardInstance = session.battlefield.back()
	var copied := 0
	for instance in session.hand:
		if instance.definition.id == card.id and instance != self_card:
			copied += 1
	return {
		"enemy": before.enemy - session.enemy.current_health,
		"calm": session.enemy.calm,
		"exposed": session.enemy.exposed,
		"player": session.player_health - before.player,
		"spark": session.current_energy - spark_base,
		"banked": session.banked_energy,
		"hand": session.hand.size() - before.hand,
		"a_power": a.current_attack,
		"b_power": b.current_attack,
		"a_shield": a.shield,
		"b_shield": b.shield,
		"a_hp": a.current_health - before.a_hp,
		"self_power": self_card.current_attack - card.attack,
		"self_shield": self_card.shield,
		"self_ready": 1 if mode == "played" and resolver.can_attack_enemy(session, self_card.instance_id) else 0,
		"newest_power": newest.current_attack - newest.definition.attack if mode == "card_played" else 0,
		"copied_self": copied,
	}


# ------------------------------------------------------- scripted battles

static func _enemies(catalog: Node) -> Array:
	return catalog.get_all_enemies()


static func _invariants_hold(session: BattleSession) -> bool:
	if session.player_health < 0 or session.player_health > session.rules.player_starting_health:
		return false
	if session.enemy.current_health < 0 or session.enemy.current_health > session.enemy.definition.maximum_health:
		return false
	if session.enemy.calm < 0 or session.enemy.exposed < 0 or session.banked_energy < 0 or session.current_energy < 0:
		return false
	if session.hand.size() > session.rules.maximum_hand_size or session.battlefield.size() > session.rules.maximum_battlefield_size:
		return false
	for card in session.battlefield:
		if card.current_health <= 0 or card.current_health > card.definition.health or card.current_attack < 0 or card.shield < 0:
			return false
	return true


## Greedy scripted round: play every affordable card (forcing `focus` first), help with ready allies, end round.
static func _play_round(session: BattleSession, resolver: ActionResolver, focus: StringName, played: Dictionary) -> bool:
	var made_play := true
	while made_play and not session.is_finished():
		made_play = false
		var hand := session.hand.duplicate()
		hand.sort_custom(func(x, y): return x.definition.id == focus and y.definition.id != focus)
		for instance in hand:
			if resolver.can_play_card(session, instance.instance_id):
				resolver.play_card(session, instance.instance_id)
				played[instance.definition.id] = true
				made_play = true
				if not _invariants_hold(session):
					return false
				break
	for ally in session.battlefield.duplicate():
		if resolver.can_attack_enemy(session, ally.instance_id):
			resolver.attack_enemy(session, ally.instance_id)
	if not session.is_finished():
		resolver.end_turn(session)
	return _invariants_hold(session)


static func _test_every_card_in_battle(check: Callable, catalog: Node) -> void:
	var cards: Array[CardDefinition] = catalog.get_all_cards()
	var starter: Array[CardDefinition] = []
	for card_id in ProfileMigrator.ACCESS_ALLIES_STARTER_IDS:
		starter.append(catalog.get_card(card_id))
	for enemy in _enemies(catalog):
		var played: Dictionary = {}
		var valid := true
		var finished := true
		for card in cards:
			var deck: Array = [card, card]
			deck.append_array(starter.slice(0, 18))
			var session := BattleSession.new()
			session.initialize(deck, enemy, catalog.get_rules() if catalog.has_method("get_rules") else load("res://battle/rules/battle_rules.tres"), 4242)
			var resolver := ActionResolver.new()
			resolver.start_battle(session)
			# Guarantee the focus card is in the opening hand.
			for instance in session.draw_pile:
				if instance.definition.id == card.id:
					session.draw_pile.erase(instance)
					session.hand.append(instance)
					break
			var rounds := 0
			while not session.is_finished() and rounds < 40:
				valid = _play_round(session, resolver, card.id, played) and valid
				rounds += 1
			finished = finished and session.is_finished()
		check.call(valid, "Every card plays against %s without invalid battle state" % enemy.display_name)
		check.call(finished, "Every scripted battle against %s reaches a result" % enemy.display_name)
		var missing: Array = []
		for card in cards:
			if not played.has(card.id):
				missing.append(card.id)
		check.call(missing.is_empty(), "All %d cards were played against %s (missing: %s)" % [cards.size(), enemy.display_name, missing])


static func _test_full_collection_battles(check: Callable, catalog: Node) -> void:
	var deck: Array = []
	deck.assign(catalog.get_all_cards())
	for enemy in _enemies(catalog):
		var valid := true
		var finished := true
		for seed_value in range(1, 11):
			var session := BattleSession.new()
			session.initialize(deck, enemy, load("res://battle/rules/battle_rules.tres"), seed_value)
			var resolver := ActionResolver.new()
			resolver.start_battle(session)
			var rounds := 0
			while not session.is_finished() and rounds < 40:
				valid = _play_round(session, resolver, &"", {}) and valid
				rounds += 1
			finished = finished and session.is_finished()
		check.call(valid, "A deck of the whole collection keeps battle state valid against %s" % enemy.display_name)
		check.call(finished, "Whole-collection battles against %s reach a result" % enemy.display_name)
