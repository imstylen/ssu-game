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


func damage_player(amount: int) -> void:
	_resolver.apply_player_damage(_session, amount, _events)


func heal_player(amount: int) -> void:
	_resolver.apply_player_healing(_session, amount, _events)


func draw_cards(amount: int) -> void:
	_resolver.draw_cards(_session, amount, _events)


func modify_unit_attack(instance_id: int, amount: int) -> void:
	_resolver.modify_unit_attack(_session, instance_id, amount, _events)


func create_card_in_hand(card_id: StringName) -> void:
	_resolver.create_card_in_hand(_session, card_id, _events)
