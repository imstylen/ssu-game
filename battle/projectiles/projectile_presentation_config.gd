class_name ProjectilePresentationConfig
extends Resource
## Default projectile styles for the battle scene, and the rules for choosing one.
## Enemy damage: action > enemy definition > default. Card damage: card definition > default.
## Healing always uses `healing`.

@export var ally_attack: ProjectileStyle
@export var card_effect: ProjectileStyle
@export var healing: ProjectileStyle
@export var enemy_attack: ProjectileStyle
## Seconds between launches when several hits leave in a row (a spread volley).
@export_range(0.0, 1.0, 0.01) var volley_stagger_seconds: float = 0.1
## Seconds each hit holds the presentation when reduce motion replaces flights.
@export_range(0.0, 1.0, 0.01) var reduced_motion_hit_seconds: float = 0.15
## Seconds a self-targeted burst takes before its effect lands.
@export_range(0.0, 1.0, 0.01) var self_burst_seconds: float = 0.15


## Picks the style for a sourced DamageApplied, HealingApplied or ShieldAbsorbed event.
## `definitions` maps card IDs to CardDefinitions (BattleSession.known_definitions).
func style_for(event: BattleEvent, definitions: Dictionary, enemy_definition: EnemyDefinition) -> ProjectileStyle:
	if event.kind == &"HealingApplied":
		return healing
	var source: Dictionary = event.data.get("source", {})
	match str(source.get("kind", "")):
		"enemy":
			var action = source.get("action")
			if action is EnemyAction and action.projectile != null:
				return action.projectile
			if enemy_definition != null and enemy_definition.projectile != null:
				return enemy_definition.projectile
			return enemy_attack
		"unit", "card":
			var definition: CardDefinition = definitions.get(StringName(str(source.get("card_id", ""))))
			if definition != null and definition.projectile != null:
				return definition.projectile
			return ally_attack if str(source.kind) == "unit" else card_effect
	return null
