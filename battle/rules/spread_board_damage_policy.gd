class_name SpreadBoardDamagePolicy
extends BoardDamagePolicy
## Spreads board damage 1 point at a time across the Ally Circle in order.
## Guard allies absorb the spread first; other allies are hit only once no Guard
## ally remains. Leftover damage spills to the player when the rules allow it.


func apply_damage(context: EffectContext, amount: int) -> void:
	var remaining := maxi(amount, 0)
	if remaining == 0:
		return
	var session := context._session
	if session.battlefield.is_empty():
		context.damage_player(remaining)
		return
	while remaining > 0 and not session.battlefield.is_empty() and not session.is_finished():
		var pool := _guard_allies(session)
		if pool.is_empty():
			pool = session.battlefield.duplicate()
		for target in pool:
			if remaining <= 0 or session.is_finished():
				break
			if session.find_battlefield_card(target.instance_id) == null:
				continue
			context.damage_unit(target.instance_id, 1)
			remaining -= 1
	if remaining > 0 and session.rules.excess_board_damage_spills_to_player:
		context.damage_player(remaining)


func _guard_allies(session: BattleSession) -> Array[CardInstance]:
	var guards: Array[CardInstance] = []
	for card in session.battlefield:
		if card.definition.guard:
			guards.append(card)
	return guards
