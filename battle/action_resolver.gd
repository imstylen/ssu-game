class_name ActionResolver
extends RefCounted

var last_error: String = ""
var board_damage_policy: BoardDamagePolicy = SpreadBoardDamagePolicy.new()


func start_battle(session: BattleSession) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	if session.enemy == null or session.enemy.definition == null:
		last_error = "Choose an ableism monster for this adventure."
		return events
	if session.draw_pile.is_empty():
		last_error = "Add at least one ally card before starting the adventure."
		return events
	session.turn_number = 1
	session.current_energy = session.rules.energy_per_turn
	events.append(BattleEvent.new(&"BattleStarted", {
		"enemy_name": session.enemy.definition.display_name,
		"enemy_health": session.enemy.current_health,
	}))
	draw_cards(session, session.rules.starting_hand_size, events)
	session.phase = BattleSession.Phase.PLAYER_TURN
	events.append(BattleEvent.new(&"TurnStarted", {
		"turn": session.turn_number,
		"energy": session.current_energy,
	}))
	last_error = ""
	return events


func can_play_card(session: BattleSession, instance_id: int) -> bool:
	return get_play_error(session, instance_id).is_empty()


func get_play_error(session: BattleSession, instance_id: int) -> String:
	if session == null or session.phase != BattleSession.Phase.PLAYER_TURN:
		return "You can play an ally card during your round."
	var card := session.find_hand_card(instance_id)
	if card == null:
		return "That card is no longer in your hand."
	if card.definition.cost > session.current_energy:
		return "You need more Spark to play that card."
	if card.definition.card_type == CardDefinition.CardType.UNIT \
	and session.battlefield.size() >= session.rules.maximum_battlefield_size:
		return "Your Ally Circle is full. End the round or choose a one-shot."
	return ""


func play_card(session: BattleSession, instance_id: int) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	last_error = get_play_error(session, instance_id)
	if not last_error.is_empty():
		return events
	var card := session.find_hand_card(instance_id)
	session.phase = BattleSession.Phase.RESOLVING_ACTION
	session.hand.erase(card)
	session.current_energy -= card.definition.cost
	events.append(BattleEvent.new(&"EnergyChanged", {"energy": session.current_energy}))
	events.append(BattleEvent.new(&"CardPlayed", {
		"instance_id": card.instance_id,
		"card_id": String(card.definition.id),
		"name": card.definition.display_name,
		"card_type": card.definition.card_type,
	}))
	var context := EffectContext.new(session, self, events)
	if card.definition.behavior != null:
		card.definition.behavior.on_played(context, card)
	if card.definition.card_type == CardDefinition.CardType.UNIT:
		card.turn_played = session.turn_number
		card.has_attacked_this_turn = not (session.rules.units_can_attack_when_played or card.definition.quick)
		session.battlefield.append(card)
		events.append(BattleEvent.new(&"UnitSummoned", {
			"instance_id": card.instance_id,
			"name": card.definition.display_name,
		}))
	else:
		session.discard_pile.append(card)
		events.append(BattleEvent.new(&"CardDiscarded", {
			"instance_id": card.instance_id,
			"name": card.definition.display_name,
		}))
	_trigger_card_played(session, card, events)
	if not session.is_finished():
		session.phase = BattleSession.Phase.PLAYER_TURN
	return events


func can_attack_enemy(session: BattleSession, instance_id: int) -> bool:
	return get_attack_error(session, instance_id).is_empty()


func get_attack_error(session: BattleSession, instance_id: int) -> String:
	if session == null or session.phase != BattleSession.Phase.PLAYER_TURN:
		return "Allies can help bust a barrier during your round."
	var card := session.find_battlefield_card(instance_id)
	if card == null:
		return "That ally is not in the Ally Circle."
	if card.has_attacked_this_turn:
		return "That ally already helped this round."
	if card.current_attack <= 0:
		return "That ally has no Power right now."
	return ""


func attack_enemy(session: BattleSession, instance_id: int) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	last_error = get_attack_error(session, instance_id)
	if not last_error.is_empty():
		return events
	var card := session.find_battlefield_card(instance_id)
	session.phase = BattleSession.Phase.RESOLVING_ACTION
	card.has_attacked_this_turn = true
	events.append(BattleEvent.new(&"UnitAttacked", {
		"instance_id": card.instance_id,
		"name": card.definition.display_name,
		"amount": card.current_attack,
	}))
	apply_enemy_damage(session, card.current_attack, events)
	if not session.is_finished():
		session.phase = BattleSession.Phase.PLAYER_TURN
	return events


func can_end_turn(session: BattleSession) -> bool:
	return session != null and session.phase == BattleSession.Phase.PLAYER_TURN


func end_turn(session: BattleSession) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	if not can_end_turn(session):
		last_error = "This round cannot end while an action is still resolving."
		return events
	last_error = ""
	events.append(BattleEvent.new(&"TurnEnded", {"turn": session.turn_number}))
	session.phase = BattleSession.Phase.RESOLVING_ACTION
	_trigger_round_hook(session, &"on_round_end", events)
	if session.is_finished():
		return events
	session.phase = BattleSession.Phase.ENEMY_TURN
	var decision_context := EnemyDecisionContext.new(session)
	var actions := session.enemy.definition.behavior.get_turn_actions(decision_context)
	var effect_context := EffectContext.new(session, self, events)
	for action in actions:
		if session.is_finished():
			break
		if action is EnemyAction:
			events.append(BattleEvent.new(&"EnemyActionStarted", {
				"description": action.describe(),
			}))
			action.resolve(effect_context)
	if session.is_finished():
		return events
	session.turn_number += 1
	session.current_energy = session.rules.energy_per_turn + session.banked_energy
	session.banked_energy = 0
	for card in session.battlefield:
		card.has_attacked_this_turn = false
	draw_cards(session, session.rules.cards_drawn_per_turn, events)
	session.phase = BattleSession.Phase.PLAYER_TURN
	events.append(BattleEvent.new(&"TurnStarted", {
		"turn": session.turn_number,
		"energy": session.current_energy,
	}))
	session.phase = BattleSession.Phase.RESOLVING_ACTION
	_trigger_round_hook(session, &"on_round_start", events)
	if session.is_finished():
		return events
	session.phase = BattleSession.Phase.PLAYER_TURN
	_resolve_automatic_ally_help(session, events)
	return events


## Runs a round hook for every ally in Ally Circle order, skipping allies that left mid-way.
func _trigger_round_hook(session: BattleSession, hook: StringName, events: Array[BattleEvent]) -> void:
	var context := EffectContext.new(session, self, events)
	for card in session.battlefield.duplicate():
		if session.is_finished():
			return
		if card.definition.behavior == null or session.find_battlefield_card(card.instance_id) == null:
			continue
		card.definition.behavior.call(hook, context, card)


func _trigger_card_played(session: BattleSession, played_card: CardInstance, events: Array[BattleEvent]) -> void:
	var context := EffectContext.new(session, self, events)
	for card in session.battlefield.duplicate():
		if session.is_finished():
			return
		if card == played_card or card.definition.behavior == null:
			continue
		if session.find_battlefield_card(card.instance_id) == null:
			continue
		card.definition.behavior.on_card_played(context, card, played_card)


func _resolve_automatic_ally_help(session: BattleSession, events: Array[BattleEvent]) -> void:
	for card in session.battlefield.duplicate():
		if session.is_finished():
			return
		if not can_attack_enemy(session, card.instance_id):
			continue
		var attack_events := attack_enemy(session, card.instance_id)
		events.append_array(attack_events)


func draw_cards(session: BattleSession, amount: int, events: Array[BattleEvent]) -> void:
	for _draw_index in range(maxi(amount, 0)):
		if session.draw_pile.is_empty():
			if session.discard_pile.is_empty():
				events.append(BattleEvent.new(&"DrawPileEmpty"))
				return
			session.draw_pile.assign(session.discard_pile)
			session.discard_pile.clear()
			session.shuffle_cards(session.draw_pile)
			events.append(BattleEvent.new(&"DiscardReshuffled", {
				"count": session.draw_pile.size(),
			}))
		var card: CardInstance = session.draw_pile.pop_back()
		card.current_health = card.definition.health
		card.current_attack = card.definition.attack
		card.has_attacked_this_turn = false
		card.turn_played = -1
		card.shield = 0
		if session.hand.size() >= session.rules.maximum_hand_size:
			session.discard_pile.append(card)
			events.append(BattleEvent.new(&"CardBurned", {
				"instance_id": card.instance_id,
				"name": card.definition.display_name,
			}))
		else:
			session.hand.append(card)
			events.append(BattleEvent.new(&"CardDrawn", {
				"instance_id": card.instance_id,
				"name": card.definition.display_name,
			}))


func gain_energy(session: BattleSession, amount: int, events: Array[BattleEvent]) -> void:
	if session.is_finished() or amount <= 0:
		return
	session.current_energy += amount
	events.append(BattleEvent.new(&"EnergyChanged", {
		"amount": amount,
		"energy": session.current_energy,
	}))


func apply_enemy_damage(session: BattleSession, amount: int, events: Array[BattleEvent]) -> void:
	if session.is_finished() or amount <= 0:
		return
	if session.enemy.exposed > 0:
		amount += session.enemy.exposed
		events.append(BattleEvent.new(&"ExposedUsed", {"amount": session.enemy.exposed}))
		session.enemy.exposed = 0
		_emit_enemy_status(session, events)
	var applied := mini(amount, session.enemy.current_health)
	session.enemy.current_health -= applied
	events.append(BattleEvent.new(&"DamageApplied", {
		"target": "enemy",
		"amount": applied,
		"health": session.enemy.current_health,
	}))
	_check_battle_end(session, events)


func apply_enemy_healing(session: BattleSession, amount: int, events: Array[BattleEvent]) -> void:
	if session.is_finished() or amount <= 0:
		return
	var old_health := session.enemy.current_health
	session.enemy.current_health = mini(
		session.enemy.current_health + amount,
		session.enemy.definition.maximum_health
	)
	var applied := session.enemy.current_health - old_health
	if applied > 0:
		events.append(BattleEvent.new(&"HealingApplied", {
			"target": "enemy",
			"amount": applied,
			"health": session.enemy.current_health,
		}))


func apply_unit_damage(
	session: BattleSession,
	instance_id: int,
	amount: int,
	events: Array[BattleEvent]
) -> void:
	if session.is_finished() or amount <= 0:
		return
	var card := session.find_battlefield_card(instance_id)
	if card == null:
		return
	if card.shield > 0:
		var absorbed := mini(card.shield, amount)
		card.shield -= absorbed
		amount -= absorbed
		events.append(BattleEvent.new(&"ShieldAbsorbed", {
			"instance_id": card.instance_id,
			"name": card.definition.display_name,
			"amount": absorbed,
			"shield": card.shield,
		}))
		if amount <= 0:
			return
	var applied := mini(amount, card.current_health)
	card.current_health -= applied
	events.append(BattleEvent.new(&"DamageApplied", {
		"target": "unit",
		"instance_id": card.instance_id,
		"name": card.definition.display_name,
		"amount": applied,
		"health": card.current_health,
	}))
	if card.current_health <= 0:
		session.battlefield.erase(card)
		session.discard_pile.append(card)
		card.shield = 0
		events.append(BattleEvent.new(&"CardDestroyed", {
			"instance_id": card.instance_id,
			"name": card.definition.display_name,
		}))
		if card.definition.behavior != null:
			card.definition.behavior.on_knocked_out(EffectContext.new(session, self, events), card)


func apply_board_damage(session: BattleSession, amount: int, events: Array[BattleEvent]) -> void:
	if amount <= 0 or session.is_finished():
		return
	var context := EffectContext.new(session, self, events)
	board_damage_policy.apply_damage(context, amount)


func apply_ally_healing(session: BattleSession, amount: int, events: Array[BattleEvent]) -> void:
	if amount <= 0 or session.is_finished():
		return
	for card in session.battlefield:
		var old_health := card.current_health
		card.current_health = mini(card.current_health + amount, card.definition.health)
		var applied := card.current_health - old_health
		if applied > 0:
			events.append(BattleEvent.new(&"HealingApplied", {
				"target": "unit",
				"instance_id": card.instance_id,
				"name": card.definition.display_name,
				"amount": applied,
				"health": card.current_health,
			}))


func apply_player_damage(session: BattleSession, amount: int, events: Array[BattleEvent]) -> void:
	if session.is_finished() or amount <= 0:
		return
	var applied := mini(amount, session.player_health)
	session.player_health -= applied
	events.append(BattleEvent.new(&"DamageApplied", {
		"target": "player",
		"amount": applied,
		"health": session.player_health,
	}))
	_check_battle_end(session, events)


func apply_player_healing(session: BattleSession, amount: int, events: Array[BattleEvent]) -> void:
	if session.is_finished() or amount <= 0:
		return
	var old_health := session.player_health
	session.player_health = mini(
		session.player_health + amount,
		session.rules.player_starting_health
	)
	var applied := session.player_health - old_health
	if applied > 0:
		events.append(BattleEvent.new(&"HealingApplied", {
			"target": "player",
			"amount": applied,
			"health": session.player_health,
		}))


func modify_unit_attack(
	session: BattleSession,
	instance_id: int,
	amount: int,
	events: Array[BattleEvent]
) -> void:
	var card := session.find_battlefield_card(instance_id)
	if card == null:
		return
	card.current_attack = maxi(card.current_attack + amount, 0)
	events.append(BattleEvent.new(&"UnitAttackChanged", {
		"instance_id": instance_id,
		"amount": amount,
		"attack": card.current_attack,
	}))


func create_card_in_hand(
	session: BattleSession,
	card_id: StringName,
	events: Array[BattleEvent]
) -> void:
	if not session.known_definitions.has(card_id):
		return
	var instance := session.create_instance(session.known_definitions[card_id])
	if session.hand.size() >= session.rules.maximum_hand_size:
		session.discard_pile.append(instance)
		events.append(BattleEvent.new(&"CardBurned", {
			"instance_id": instance.instance_id,
			"name": instance.definition.display_name,
		}))
		return
	session.hand.append(instance)
	events.append(BattleEvent.new(&"CardCreated", {
		"instance_id": instance.instance_id,
		"name": instance.definition.display_name,
	}))


func apply_unit_healing(
	session: BattleSession,
	instance_id: int,
	amount: int,
	events: Array[BattleEvent]
) -> void:
	if amount <= 0 or session.is_finished():
		return
	var card := session.find_battlefield_card(instance_id)
	if card == null:
		return
	var old_health := card.current_health
	card.current_health = mini(card.current_health + amount, card.definition.health)
	var applied := card.current_health - old_health
	if applied > 0:
		events.append(BattleEvent.new(&"HealingApplied", {
			"target": "unit",
			"instance_id": card.instance_id,
			"name": card.definition.display_name,
			"amount": applied,
			"health": card.current_health,
		}))


func modify_card_attack(
	session: BattleSession,
	card: CardInstance,
	amount: int,
	events: Array[BattleEvent]
) -> void:
	if card == null or amount == 0 or session.is_finished():
		return
	card.current_attack = maxi(card.current_attack + amount, 0)
	events.append(BattleEvent.new(&"UnitAttackChanged", {
		"instance_id": card.instance_id,
		"name": card.definition.display_name,
		"amount": amount,
		"attack": card.current_attack,
	}))


func give_shield(session: BattleSession, card: CardInstance, amount: int, events: Array[BattleEvent]) -> void:
	if card == null or amount <= 0 or session.is_finished():
		return
	card.shield += amount
	events.append(BattleEvent.new(&"ShieldGained", {
		"instance_id": card.instance_id,
		"name": card.definition.display_name,
		"amount": amount,
		"shield": card.shield,
	}))


func bank_energy(session: BattleSession, amount: int, events: Array[BattleEvent]) -> void:
	if amount <= 0 or session.is_finished():
		return
	session.banked_energy += amount
	events.append(BattleEvent.new(&"SparkBanked", {
		"amount": amount,
		"banked": session.banked_energy,
	}))


func apply_enemy_status(session: BattleSession, calm: int, exposed: int, events: Array[BattleEvent]) -> void:
	if session.is_finished() or (calm <= 0 and exposed <= 0):
		return
	session.enemy.calm += maxi(calm, 0)
	session.enemy.exposed += maxi(exposed, 0)
	_emit_enemy_status(session, events)


## Spends the whole Calm stack against one enemy damage amount; returns the damage left.
func consume_calm(session: BattleSession, amount: int, events: Array[BattleEvent]) -> int:
	if session.enemy == null or session.enemy.calm <= 0 or amount <= 0:
		return amount
	var prevented := mini(session.enemy.calm, amount)
	session.enemy.calm = 0
	events.append(BattleEvent.new(&"CalmUsed", {"amount": prevented}))
	_emit_enemy_status(session, events)
	return amount - prevented


func _emit_enemy_status(session: BattleSession, events: Array[BattleEvent]) -> void:
	events.append(BattleEvent.new(&"EnemyStatusChanged", {
		"calm": session.enemy.calm,
		"exposed": session.enemy.exposed,
	}))


func _check_battle_end(session: BattleSession, events: Array[BattleEvent]) -> void:
	if session.enemy.current_health <= 0 and session.phase != BattleSession.Phase.VICTORY:
		session.phase = BattleSession.Phase.VICTORY
		events.append(BattleEvent.new(&"BattleEnded", {"result": "victory"}))
	elif session.player_health <= 0 and session.phase != BattleSession.Phase.DEFEAT:
		session.phase = BattleSession.Phase.DEFEAT
		events.append(BattleEvent.new(&"BattleEnded", {"result": "defeat"}))
