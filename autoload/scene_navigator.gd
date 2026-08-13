extends Node

const MAIN_MENU := "res://main/main.tscn"
const BATTLE := "res://battle/battle_scene.tscn"
const COLLECTION := "res://collection/collection_scene.tscn"
const DECK_BUILDER := "res://decks/deck_builder_scene.tscn"


func go_to(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


func go_to_main_menu() -> void:
	go_to(MAIN_MENU)
