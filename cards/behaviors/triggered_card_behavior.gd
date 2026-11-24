class_name TriggeredCardBehavior
extends CardBehavior
## Data-driven card ability: lists of CardEffect lines per trigger hook.

enum CardFilter {
	ANY,
	ONE_SHOTS,
	ALLIES,
}

@export var played_effects: Array[CardEffect] = []
@export var round_start_effects: Array[CardEffect] = []
@export var round_end_effects: Array[CardEffect] = []
@export var knocked_out_effects: Array[CardEffect] = []
@export var card_played_effects: Array[CardEffect] = []
## Which other played cards trigger `card_played_effects`.
@export var card_played_filter: CardFilter = CardFilter.ANY


func on_played(context: EffectContext, card: CardInstance) -> void:
	_run(played_effects, context, card)


func on_round_start(context: EffectContext, card: CardInstance) -> void:
	_run(round_start_effects, context, card)


func on_round_end(context: EffectContext, card: CardInstance) -> void:
	_run(round_end_effects, context, card)


func on_knocked_out(context: EffectContext, card: CardInstance) -> void:
	_run(knocked_out_effects, context, card)


func on_card_played(context: EffectContext, card: CardInstance, played_card: CardInstance) -> void:
	if played_card == null or played_card == card:
		return
	var is_ally := played_card.definition.card_type == CardDefinition.CardType.UNIT
	if card_played_filter == CardFilter.ONE_SHOTS and is_ally:
		return
	if card_played_filter == CardFilter.ALLIES and not is_ally:
		return
	_run(card_played_effects, context, card)


static func _run(effects: Array[CardEffect], context: EffectContext, card: CardInstance) -> void:
	var picks: Dictionary = {}
	for effect in effects:
		if context.is_battle_finished():
			return
		if effect != null:
			effect.apply(context, card, picks)
