class_name DrawCardsBehavior
extends CardBehavior

@export_group("Community Effect Fields")
@export_range(0, 20) var draw_amount: int = 2
@export_group("")


func on_played(context: EffectContext, _card: CardInstance) -> void:
	context.draw_cards(draw_amount)
