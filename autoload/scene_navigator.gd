extends Node

const MAIN_MENU := "res://main/main.tscn"
const BATTLE := "res://battle/battle_scene.tscn"
const COLLECTION := "res://collection/collection_scene.tscn"
const DECK_BUILDER := "res://decks/deck_builder_scene.tscn"
const CAMPAIGN := "res://campaign/campaign_scene.tscn"

var campaign_encounter: String = ""


func go_to(scene_path: String) -> void:
	campaign_encounter = ""
	get_tree().change_scene_to_file(scene_path)


func start_campaign_battle(node_id: String) -> bool:
	if not ProfileStore.commit_campaign(node_id):
		return false
	campaign_encounter = node_id
	return get_tree().change_scene_to_file(BATTLE) == OK


func go_to_main_menu() -> void:
	go_to(MAIN_MENU)
