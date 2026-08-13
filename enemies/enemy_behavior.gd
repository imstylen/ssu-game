class_name EnemyBehavior
extends Resource


func get_turn_actions(_context: EnemyDecisionContext) -> Array:
	return []


func describe_next_action(_context: EnemyDecisionContext) -> String:
	return "Waiting"
