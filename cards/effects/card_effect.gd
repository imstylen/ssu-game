class_name CardEffect
extends Resource
## One data-driven effect line used by TriggeredCardBehavior. Targets are chosen
## automatically; there is no player targeting.
## Enums are saved as integers in card .tres files: only append new values.

enum Kind {
	DAMAGE_ENEMY,
	HEAL_PLAYER,
	HEAL_ALLY,
	DRAW_CARDS,
	GAIN_SPARK,
	BANK_SPARK,
	MODIFY_POWER,
	GIVE_SHIELD,
	APPLY_CALM,
	APPLY_EXPOSED,
	COPY_TO_HAND,
}

## Which allies an ally-targeted effect (heal ally, Power, Shield, copy) affects.
enum Target {
	THIS_CARD,
	ALL_ALLIES,
	LOWEST_HEART_ALLY,
	NEWEST_ALLY,
}

## Optional multiplier read once when the effect resolves.
enum Scale {
	NONE,
	ALLIES_IN_CIRCLE,
	ENEMY_EXPOSED,
}

@export var kind: Kind = Kind.DAMAGE_ENEMY
@export_range(-20, 100) var amount: int = 1
@export var target: Target = Target.THIS_CARD
@export var scale: Scale = Scale.NONE


func resolved_amount(context: EffectContext) -> int:
	match scale:
		Scale.ALLIES_IN_CIRCLE:
			return amount * context.ally_count()
		Scale.ENEMY_EXPOSED:
			return amount * context.enemy_exposed()
	return amount


## `picks` caches single-ally selections so every line in one hook affects the same ally.
func apply(context: EffectContext, source: CardInstance, picks: Dictionary = {}) -> void:
	var value := resolved_amount(context)
	match kind:
		Kind.DAMAGE_ENEMY:
			context.damage_enemy(value)
		Kind.HEAL_PLAYER:
			context.heal_player(value)
		Kind.DRAW_CARDS:
			context.draw_cards(value)
		Kind.GAIN_SPARK:
			context.gain_energy(value)
		Kind.BANK_SPARK:
			context.bank_energy(value)
		Kind.APPLY_CALM:
			context.apply_calm(value)
		Kind.APPLY_EXPOSED:
			context.apply_exposed(value)
		_:
			for ally in _select_allies(context, source, picks):
				match kind:
					Kind.HEAL_ALLY:
						context.heal_unit(ally.instance_id, value)
					Kind.MODIFY_POWER:
						context.modify_card_attack(ally, value)
					Kind.GIVE_SHIELD:
						context.give_shield(ally, value)
					Kind.COPY_TO_HAND:
						context.create_card_in_hand(ally.definition.id)


func _select_allies(context: EffectContext, source: CardInstance, picks: Dictionary) -> Array[CardInstance]:
	var selected: Array[CardInstance] = []
	match target:
		Target.THIS_CARD:
			if source != null:
				selected.append(source)
		Target.ALL_ALLIES:
			selected.assign(context.allies())
		Target.LOWEST_HEART_ALLY, Target.NEWEST_ALLY:
			if not picks.has(target):
				picks[target] = context.lowest_heart_ally() if target == Target.LOWEST_HEART_ALLY else context.newest_ally()
			if picks[target] != null:
				selected.append(picks[target])
	return selected
