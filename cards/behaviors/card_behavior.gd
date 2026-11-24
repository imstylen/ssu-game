class_name CardBehavior
extends Resource
## Base class for card abilities. Override the hooks a card needs; each receives
## the shared EffectContext and the card's own battle instance.


## Runs when the card is played, before an ally joins the Ally Circle.
func on_played(_context: EffectContext, _card: CardInstance) -> void:
	pass


## Runs for each ally in the Ally Circle at the start of the player round, before automatic help.
func on_round_start(_context: EffectContext, _card: CardInstance) -> void:
	pass


## Runs for each ally in the Ally Circle when the player ends the round, before the enemy acts.
func on_round_end(_context: EffectContext, _card: CardInstance) -> void:
	pass


## Runs after this ally has been knocked out and has left the Ally Circle.
func on_knocked_out(_context: EffectContext, _card: CardInstance) -> void:
	pass


## Runs for each ally in the Ally Circle after another card has finished being played.
func on_card_played(_context: EffectContext, _card: CardInstance, _played_card: CardInstance) -> void:
	pass
