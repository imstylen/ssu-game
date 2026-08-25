class_name DamageEnemyBehavior
extends CardBehavior

@export_group("Community Effect Fields")
@export_range(0, 100) var damage_amount: int = 4
@export_group("")


func on_played(context: EffectContext, _card: CardInstance) -> void:
	context.damage_enemy(damage_amount)
