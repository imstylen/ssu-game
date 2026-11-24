class_name EffectContext
extends RefCounted

var _session: BattleSession
var _resolver: ActionResolver
var _events: Array[BattleEvent]


func _init(session: BattleSession, resolver: ActionResolver, events: Array[BattleEvent]) -> void:
	_session = session
	_resolver = resolver
	_events = events


func damage_enemy(amount: int) -> void:
	_resolver.apply_enemy_damage(_session, amount, _events)


func heal_enemy(amount: int) -> void:
	_resolver.apply_enemy_healing(_session, amount, _events)


func damage_unit(instance_id: int, amount: int) -> void:
	_resolver.apply_unit_damage(_session, instance_id, amount, _events)


func damage_board(amount: int) -> void:
	_resolver.apply_board_damage(_session, amount, _events)


func heal_allies(amount: int) -> void:
	_resolver.apply_ally_healing(_session, amount, _events)


func damage_player(amount: int) -> void:
	_resolver.apply_player_damage(_session, amount, _events)


func heal_player(amount: int) -> void:
	_resolver.apply_player_healing(_session, amount, _events)


func draw_cards(amount: int) -> void:
	_resolver.draw_cards(_session, amount, _events)


func gain_energy(amount: int) -> void:
	_resolver.gain_energy(_session, amount, _events)


func modify_unit_attack(instance_id: int, amount: int) -> void:
	_resolver.modify_unit_attack(_session, instance_id, amount, _events)


func create_card_in_hand(card_id: StringName) -> void:
	_resolver.create_card_in_hand(_session, card_id, _events)


func heal_unit(instance_id: int, amount: int) -> void:
	_resolver.apply_unit_healing(_session, instance_id, amount, _events)


## Power change on a specific instance (works for a card that is still joining the Ally Circle).
func modify_card_attack(card: CardInstance, amount: int) -> void:
	_resolver.modify_card_attack(_session, card, amount, _events)


func give_shield(card: CardInstance, amount: int) -> void:
	_resolver.give_shield(_session, card, amount, _events)


func bank_energy(amount: int) -> void:
	_resolver.bank_energy(_session, amount, _events)


func apply_calm(amount: int) -> void:
	_resolver.apply_enemy_status(_session, amount, 0, _events)


func apply_exposed(amount: int) -> void:
	_resolver.apply_enemy_status(_session, 0, amount, _events)


## Called by enemy damage actions: returns the damage left after Calm is spent.
func reduce_enemy_damage_by_calm(amount: int) -> int:
	return _resolver.consume_calm(_session, amount, _events)


func is_battle_finished() -> bool:
	return _session.is_finished()


func ally_count() -> int:
	return _session.battlefield.size()


func enemy_exposed() -> int:
	return _session.enemy.exposed if _session.enemy != null else 0


func allies() -> Array[CardInstance]:
	return _session.battlefield.duplicate()


func lowest_heart_ally() -> CardInstance:
	var lowest: CardInstance = null
	for card in _session.battlefield:
		if lowest == null or card.current_health < lowest.current_health:
			lowest = card
	return lowest


func newest_ally() -> CardInstance:
	return _session.battlefield.back() if not _session.battlefield.is_empty() else null
