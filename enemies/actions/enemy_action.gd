class_name EnemyAction
extends RefCounted

## Optional projectile override set by the behavior that builds this action.
var projectile: ProjectileStyle


func resolve(_context: EffectContext) -> void:
	pass


func describe() -> String:
	return "Acts"
