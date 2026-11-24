extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var store := root.get_node("ProfileStore")
	var navigator := root.get_node("SceneNavigator")
	store.profile_path = "res://.godot/campaign_resume_test.json"
	store.load_profile()
	var stage := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ""
	if stage == "interrupt":
		if not store.reset_campaign() or not store.commit_campaign("petting_meadow"):
			quit(1)
			return
	elif stage == "win":
		if store.campaign == null or store.campaign.committed != "petting_meadow" or not store.campaign.completed.is_empty():
			quit(1)
			return
	elif stage == "resume":
		if store.campaign == null or store.campaign.completed != ["petting_meadow"] or store.campaign.available_nodes() != ["bird_aviary", "goat_paddock"]:
			quit(1)
			return
		DirAccess.remove_absolute(ProjectSettings.globalize_path(store.profile_path))
		print("CAMPAIGN_PROCESS_RESUME_OK")
		quit()
		return
	else:
		quit(1)
		return
	navigator.campaign_encounter = "petting_meadow"
	var battle = load("res://battle/battle_scene.tscn").instantiate()
	battle.get_node("BattleController").presentation_delay = 0.0
	root.add_child(battle)
	await process_frame
	await process_frame
	if battle.controller.session.player_health != 30 or battle.controller.session.turn_number != 1:
		quit(1)
		return
	if stage == "interrupt":
		battle.controller.session.player_health = 1
		battle.controller.session.turn_number = 9
	else:
		battle.controller.session.phase = BattleSession.Phase.VICTORY
		battle._refresh()
		if store.campaign.completed != ["petting_meadow"]:
			quit(1)
			return
	print("CAMPAIGN_PROCESS_%s_OK" % stage.to_upper())
	quit()
