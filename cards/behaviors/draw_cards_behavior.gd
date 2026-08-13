class_name DrawCardsBehavior
extends CardBehavior

@export_range(0, 20) var draw_amount: int = 2


func on_played(context: EffectContext, _card: CardInstance) -> void:
	context.draw_cards(draw_amount)
