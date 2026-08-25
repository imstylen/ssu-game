class_name HealPlayerBehavior
extends CardBehavior

@export_group("Community Effect Fields")
@export_range(0, 100) var heal_amount: int = 5
@export_group("")


func on_played(context: EffectContext, _card: CardInstance) -> void:
	context.heal_player(heal_amount)
