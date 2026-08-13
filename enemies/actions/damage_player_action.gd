class_name DamagePlayerAction
extends EnemyAction

var amount: int


func _init(damage_amount: int = 0) -> void:
	amount = damage_amount


func resolve(context: EffectContext) -> void:
	context.damage_player(amount)


func describe() -> String:
	return "Strike the commander for %d" % amount
