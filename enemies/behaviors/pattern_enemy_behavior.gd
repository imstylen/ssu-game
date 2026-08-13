class_name PatternEnemyBehavior
extends EnemyBehavior

@export var attack_pattern: PackedInt32Array = PackedInt32Array([4, 5, 7])


func get_turn_actions(context: EnemyDecisionContext) -> Array:
	if attack_pattern.is_empty():
		return []
	var index := maxi(context.turn_number - 1, 0) % attack_pattern.size()
	return [DamageBoardAction.new(attack_pattern[index])]


func describe_next_action(context: EnemyDecisionContext) -> String:
	if attack_pattern.is_empty():
		return "Waiting"
	var index := maxi(context.turn_number - 1, 0) % attack_pattern.size()
	return "Incoming: %d spread damage" % attack_pattern[index]
