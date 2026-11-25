class_name BattleController
extends Node

signal event_presented(event: BattleEvent)
signal session_changed
signal input_lock_changed(locked: bool)
signal invalid_action(message: String)

@export_range(0.0, 2.0, 0.01) var presentation_delay: float = 0.08

var session: BattleSession
var action_resolver := ActionResolver.new()
var input_locked: bool = false
## Optional pacing (e.g. projectiles). Without one, events are spaced by presentation_delay
## and session_changed fires before they are presented.
var presenter: BattlePresenter


func start_battle(
	deck_definitions: Array,
	enemy_definition: EnemyDefinition,
	rules: BattleRules,
	random_seed: int = 0
) -> bool:
	if input_locked:
		return false
	session = BattleSession.new()
	session.initialize(deck_definitions, enemy_definition, rules, random_seed)
	var events := action_resolver.start_battle(session)
	if events.is_empty() and not action_resolver.last_error.is_empty():
		invalid_action.emit(action_resolver.last_error)
		return false
	queue_events(events)
	return true


func request_play_card(instance_id: int) -> void:
	if not _accepting_input():
		return
	var events := action_resolver.play_card(session, instance_id)
	_handle_result(events)


func request_attack_enemy(instance_id: int) -> void:
	if not _accepting_input():
		return
	var events := action_resolver.attack_enemy(session, instance_id)
	_handle_result(events)


func request_end_turn() -> void:
	if not _accepting_input():
		return
	var events := action_resolver.end_turn(session)
	_handle_result(events)


func can_play_card(instance_id: int) -> bool:
	return not input_locked and action_resolver.can_play_card(session, instance_id)


func can_attack_enemy(instance_id: int) -> bool:
	return not input_locked and action_resolver.can_attack_enemy(session, instance_id)


func get_enemy_intent() -> String:
	if session == null or session.enemy == null or session.is_finished():
		return ""
	var context := EnemyDecisionContext.new(session)
	return session.enemy.definition.behavior.describe_next_action(context)


func queue_events(events: Array[BattleEvent]) -> void:
	if events.is_empty():
		session_changed.emit()
		return
	input_locked = true
	input_lock_changed.emit(true)
	if presenter == null:
		session_changed.emit()
	_present_events(events)


## With presentation_delay == 0 nothing awaits, so the whole queue resolves synchronously.
func _present_events(events: Array[BattleEvent]) -> void:
	var instant := presentation_delay <= 0.0
	if presenter != null:
		presenter.begin_presentation(instant)
	for event in events:
		if presenter != null:
			await presenter.wait_until_ready(event)
		event_presented.emit(event)
		var hold := presenter.present_event(event, presentation_delay) if presenter != null else presentation_delay
		if not instant and hold > 0.0:
			await get_tree().create_timer(hold).timeout
	if presenter != null:
		await presenter.wait_until_settled()
	input_locked = false
	input_lock_changed.emit(false)
	session_changed.emit()


func _accepting_input() -> bool:
	if session == null:
		invalid_action.emit("No barrier-busting adventure is active yet.")
		return false
	if input_locked:
		return false
	return true


func _handle_result(events: Array[BattleEvent]) -> void:
	if events.is_empty() and not action_resolver.last_error.is_empty():
		invalid_action.emit(action_resolver.last_error)
		return
	queue_events(events)
