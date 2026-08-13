class_name EnemyDecisionContext
extends RefCounted

var turn_number: int
var enemy_health: int
var enemy_maximum_health: int
var player_health: int
var battlefield_size: int


func _init(session: BattleSession = null) -> void:
	if session == null:
		return
	turn_number = session.turn_number
	enemy_health = session.enemy.current_health
	enemy_maximum_health = session.enemy.definition.maximum_health
	player_health = session.player_health
	battlefield_size = session.battlefield.size()
