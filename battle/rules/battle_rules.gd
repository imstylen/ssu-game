class_name BattleRules
extends Resource

@export_range(1, 100) var player_starting_health: int = 30
@export_range(0, 20) var energy_per_turn: int = 5
@export_range(0, 20) var starting_hand_size: int = 3
@export_range(0, 20) var cards_drawn_per_turn: int = 1
@export_range(1, 30) var maximum_hand_size: int = 8
@export_range(1, 20) var maximum_battlefield_size: int = 5
@export var units_can_attack_when_played: bool = false
@export_range(1, 100) var maximum_deck_size: int = 20
@export_range(1, 20) var duplicate_card_limit: int = 2
@export var excess_board_damage_spills_to_player: bool = true
