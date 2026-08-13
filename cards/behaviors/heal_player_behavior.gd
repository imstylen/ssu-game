class_name HealPlayerBehavior
extends CardBehavior

@export_range(0, 100) var heal_amount: int = 5


func on_played(context: EffectContext, _card: CardInstance) -> void:
	context.heal_player(heal_amount)
