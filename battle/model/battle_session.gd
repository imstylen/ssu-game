class_name BattleSession
extends RefCounted

enum Phase {
	SETUP,
	PLAYER_TURN,
	RESOLVING_ACTION,
	ENEMY_TURN,
	VICTORY,
	DEFEAT,
}

var rules: BattleRules
var turn_number: int = 0
var phase: Phase = Phase.SETUP
var player_health: int = 0
var current_energy: int = 0
var draw_pile: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var battlefield: Array[CardInstance] = []
var discard_pile: Array[CardInstance] = []
var enemy: EnemyInstance
var random_number_generator := RandomNumberGenerator.new()
var known_definitions: Dictionary = {}
var next_instance_id: int = 1


func initialize(
	deck_definitions: Array,
	enemy_definition: EnemyDefinition,
	battle_rules: BattleRules,
	random_seed: int = 0
) -> void:
	rules = battle_rules
	turn_number = 0
	phase = Phase.SETUP
	player_health = rules.player_starting_health
	current_energy = 0
	draw_pile.clear()
	hand.clear()
	battlefield.clear()
	discard_pile.clear()
	known_definitions.clear()
	next_instance_id = 1
	if random_seed == 0:
		random_number_generator.seed = Time.get_ticks_usec()
	else:
		random_number_generator.seed = random_seed
	for definition in deck_definitions:
		if definition is CardDefinition:
			known_definitions[definition.id] = definition
			draw_pile.append(create_instance(definition))
	shuffle_cards(draw_pile)
	enemy = EnemyInstance.new(enemy_definition)


func create_instance(definition: CardDefinition) -> CardInstance:
	var instance := CardInstance.new(definition, next_instance_id)
	next_instance_id += 1
	return instance


func shuffle_cards(cards: Array[CardInstance]) -> void:
	for index in range(cards.size() - 1, 0, -1):
		var swap_index := random_number_generator.randi_range(0, index)
		var temporary := cards[index]
		cards[index] = cards[swap_index]
		cards[swap_index] = temporary


func find_hand_card(instance_id: int) -> CardInstance:
	for card in hand:
		if card.instance_id == instance_id:
			return card
	return null


func find_battlefield_card(instance_id: int) -> CardInstance:
	for card in battlefield:
		if card.instance_id == instance_id:
			return card
	return null


func is_finished() -> bool:
	return phase == Phase.VICTORY or phase == Phase.DEFEAT


func phase_name() -> String:
	return Phase.keys()[phase].capitalize()
