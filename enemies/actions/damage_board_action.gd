class_name DamageBoardAction
extends EnemyAction

var amount: int


func _init(damage_amount: int = 0) -> void:
	amount = damage_amount


func resolve(context: EffectContext) -> void:
	context.damage_board(amount)


func describe() -> String:
	return "Pile on %d barrier damage" % amount
