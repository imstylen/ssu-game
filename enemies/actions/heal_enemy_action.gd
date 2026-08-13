class_name HealEnemyAction
extends EnemyAction

var amount: int


func _init(heal_amount: int = 0) -> void:
	amount = heal_amount


func resolve(context: EffectContext) -> void:
	context.heal_enemy(amount)


func describe() -> String:
	return "Patch up %d monster Heart" % amount
