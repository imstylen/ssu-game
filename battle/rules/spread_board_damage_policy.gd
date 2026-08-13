class_name SpreadBoardDamagePolicy
extends BoardDamagePolicy


func apply_damage(context: EffectContext, amount: int) -> void:
	var remaining := maxi(amount, 0)
	if remaining == 0:
		return
	var session := context._session
	if session.battlefield.is_empty():
		context.damage_player(remaining)
		return
	var cursor := 0
	while remaining > 0 and not session.battlefield.is_empty():
		if cursor >= session.battlefield.size():
			cursor = 0
		var target: CardInstance = session.battlefield[cursor]
		context.damage_unit(target.instance_id, 1)
		remaining -= 1
		if session.find_battlefield_card(target.instance_id) != null:
			cursor += 1
	if remaining > 0 and session.rules.excess_board_damage_spills_to_player:
		context.damage_player(remaining)
