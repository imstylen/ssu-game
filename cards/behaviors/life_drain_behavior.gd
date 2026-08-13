class_name LifeDrainBehavior
extends CardBehavior

@export_range(0, 100) var drain_amount: int = 3


func on_played(context: EffectContext, _card: CardInstance) -> void:
	context.damage_enemy(drain_amount)
	context.heal_player(drain_amount)
