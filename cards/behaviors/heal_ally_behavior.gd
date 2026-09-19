class_name HealAllyBehavior
extends CardBehavior

@export_range(0, 100) var heal_amount: int = 2


func on_played(context: EffectContext, _card: CardInstance) -> void:
	context.heal_allies(heal_amount)
