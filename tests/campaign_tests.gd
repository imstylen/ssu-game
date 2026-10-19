extends RefCounted


static func run(check: Callable, catalog: Node) -> void:
	var definition_script = load("res://campaign/campaign_definition.gd")
	var progress_script = load("res://campaign/campaign_progress.gd")
	if definition_script == null or progress_script == null:
		check.call(false, "Campaign model scripts load")
		return
	var definition = definition_script.new()
	check.call(definition.nodes.size() == 11, "Campaign has eleven nodes")
	var counts := [0, 0, 0, 0, 0]
	for id in definition.nodes:
		var node: Dictionary = definition.nodes[id]
		counts[node.tier - 1] += 1
		for next in node.next:
			check.call(definition.nodes.has(next) and definition.nodes[next].tier == node.tier + 1, "Edges advance exactly one tier")
		var base: EnemyDefinition = catalog.get_enemy(node.enemy_id)
		var old_health := base.maximum_health
		var old_pattern: PackedInt32Array = base.behavior.attack_pattern.duplicate()
		var variant: EnemyDefinition = definition.enemy_variant(id, catalog)
		var expected_health: int = 42 if id == "t5_boss" else old_health + 2 * (node.tier - 1)
		check.call(variant.maximum_health == expected_health, "Campaign Heart matches tuning")
		var expected_pattern := PackedInt32Array([5, 7, 8]) if id == "t5_boss" else old_pattern.duplicate()
		if id != "t5_boss":
			for i in expected_pattern.size():
				expected_pattern[i] += mini(node.tier - 1, 2)
		check.call(variant.behavior.attack_pattern == expected_pattern, "Campaign damage matches tuning")
		check.call(variant.id == base.id and variant.artwork == base.artwork and variant.description == base.description, "Variants preserve enemy identity and art")
		variant.behavior.attack_pattern[0] = 999
		check.call(base.maximum_health == old_health and base.behavior.attack_pattern == old_pattern, "Variants do not mutate base resources")
	check.call(counts == [2, 3, 3, 2, 1], "Campaign tier counts match spec")
	check.call(catalog.get_all_enemies().size() == 3, "Variants do not enter standalone pool")
	var progress = progress_script.new()
	check.call(progress.available_nodes() == ["t1_a", "t1_b"], "Both entrances are available")
	check.call(not progress.commit("t5_boss"), "Cannot commit locked boss")
	check.call(progress.commit("t1_a"), "Can commit entrance")
	check.call(progress.node_status("t1_b") == "skipped" and progress.node_status("t2_c") == "skipped", "Commitment excludes alternatives and unreachable descendants")
	check.call(progress.node_status("t3_c") == "locked", "Merged future path remains reachable")
	check.call(not progress.commit("t1_b") and progress.commit("t1_a"), "Retry preserves exclusive commitment")
	check.call(progress.complete("t1_a") and progress.complete("t1_a"), "Victory is idempotent")
	check.call(progress.completed.size() == 1 and progress.available_nodes() == ["t2_a", "t2_b"], "Victory unlocks only outgoing neighbors")
	check.call(not progress.commit("t1_a") and not progress.complete("t2_a"), "Completed nodes cannot replay and uncommitted nodes cannot win")
	_walk_routes(check, definition, progress_script, [], ["t1_a", "t1_b"])
	for invalid in [null, {}, {"version": 99, "completed": []}, {"version": 1, "completed": ["unknown"]}, {"version": 1, "completed": ["t1_a", "t2_c"]}, {"version": 1, "completed": ["t2_a"]}, {"version": 1, "completed": ["t1_a"], "committed": "t1_a"}, {"version": 1, "completed": [1]}, {"version": 1, "completed": [], "committed": 1}]:
		check.call(not progress_script.validation_error(invalid).is_empty(), "Invalid campaign save is rejected")
	_test_persistence(check)
	_test_full_campaign_play(check, catalog)


static func _test_full_campaign_play(check: Callable, catalog: Node) -> void:
	var deck: Array[CardDefinition] = []
	for id in ProfileMigrator.ACCESS_ALLIES_STARTER_IDS:
		deck.append(catalog.get_card(id))
	var definition := CampaignDefinition.new()
	var completed_route := CampaignProgress.new()
	for node_id in ["t1_a", "t2_b", "t3_b", "t4_a", "t5_boss"]:
		var wins := 0
		var rounds := 0
		for seed_value in range(1, 51):
			var session := BattleSession.new()
			session.initialize(deck, definition.enemy_variant(node_id, catalog), load("res://battle/rules/battle_rules.tres"), seed_value)
			var resolver := ActionResolver.new()
			resolver.start_battle(session)
			while not session.is_finished() and session.turn_number < 40:
				var played := true
				while played and not session.is_finished():
					played = false
					var choices := session.hand.duplicate()
					choices.sort_custom(func(a, b): return _play_priority(a, session) > _play_priority(b, session))
					for card in choices:
						if resolver.can_play_card(session, card.instance_id) and _play_priority(card, session) > 0:
							resolver.play_card(session, card.instance_id)
							played = true
							break
				if not session.is_finished():
					resolver.end_turn(session)
			check.call(session.is_finished(), "Campaign battle reaches a result within forty rounds")
			if session.phase == BattleSession.Phase.VICTORY:
				wins += 1
				rounds += session.turn_number
		print("CAMPAIGN_PLAY %s: %d/50 starter victories; winning rounds total=%d" % [node_id, wins, rounds])
		check.call(wins > 0, "Starter deck can overcome %s with fresh retries" % node_id)
		if wins > 0:
			completed_route.commit(node_id)
			completed_route.complete(node_id)
	check.call(completed_route.is_complete(), "Starter victories permit a complete campaign route")


static func _play_priority(card: CardInstance, session: BattleSession) -> float:
	var definition := card.definition
	if definition.behavior is HealPlayerBehavior:
		return 15.0 if session.player_health <= 25 else 0.0
	if definition.behavior is DamageEnemyBehavior:
		return 100.0 if session.enemy.current_health <= definition.behavior.damage_amount else 8.0
	if definition.behavior is DrawCardsBehavior:
		return 30.0
	return float(definition.health + definition.attack) / maxf(definition.cost, 1.0) + 10.0


static func _test_persistence(check: Callable) -> void:
	var store = load("res://autoload/profile_store.gd").new()
	store.profile_path = "user://campaign_test_%d.json" % Time.get_ticks_usec()
	store.deck_rules = DeckRules.new(load("res://battle/rules/battle_rules.tres"))
	store.load_profile()
	var original_decks: Array = store.decks.map(func(deck): return deck.to_dictionary())
	var original_selected: String = store.selected_deck_id
	store.profile_writer = func(_data): return ERR_CANT_CREATE
	check.call(not store.initialize_campaign() and store.campaign == null and not store.last_save_error.is_empty(), "Failed initialization stays unsaved and reports error")
	store.profile_writer = Callable()
	check.call(store.initialize_campaign(), "Campaign initialization saves")
	store.load_profile()
	check.call(store.campaign != null and store.campaign.completed.is_empty(), "Fresh campaign round trips")
	check.call(store.commit_campaign("t1_a"), "Commit saves before battle")
	store.load_profile()
	check.call(store.campaign.committed == "t1_a", "Interrupted battle resumes committed")
	store.profile_writer = func(_data): return ERR_CANT_CREATE
	check.call(not store.complete_campaign_encounter("t1_a") and store.campaign.completed.is_empty() and store.campaign.committed == "t1_a", "Failed victory does not advance memory")
	store.profile_writer = Callable()
	store.load_profile()
	check.call(store.campaign.committed == "t1_a", "Failed victory preserves disk commitment")
	check.call(store.complete_campaign_encounter("t1_a") and store.complete_campaign_encounter("t1_a") and store.campaign.completed.size() == 1, "Saved victory is idempotent")
	store.load_profile()
	check.call(store.campaign.available_nodes() == ["t2_a", "t2_b"], "Saved victory resumes connected choices")
	store.profile_writer = func(_data): return ERR_CANT_CREATE
	check.call(not store.commit_campaign("t2_a") and store.campaign.committed.is_empty(), "Failed commitment cannot enter battle")
	check.call(not store.reset_campaign() and store.campaign.completed.size() == 1, "Failed reset preserves progress")
	store.profile_writer = Callable()
	for id in ["t2_b", "t3_b", "t4_a", "t5_boss"]:
		check.call(store.commit_campaign(id) and store.complete_campaign_encounter(id), "Progress saves through boss")
	store.load_profile()
	check.call(store.campaign.is_complete(), "Completed campaign round trips")
	check.call(store.reset_campaign() and store.campaign.completed.is_empty(), "Explicit reset clears route")
	check.call(store.decks.map(func(deck): return deck.to_dictionary()) == original_decks and store.selected_deck_id == original_selected, "Campaign leaves decks and selection intact")
	var corrupt := {"version": 50, "completed": ["t1_a"]}
	var file := FileAccess.open(store.profile_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version": 3, "decks": original_decks, "selected_deck_id": original_selected, "campaign": corrupt}))
	file.close()
	store.load_profile()
	check.call(store.campaign == null and not store.campaign_error.is_empty() and not store.initialize_campaign(), "Invalid campaign requires explicit reset")
	store.save_profile()
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store.profile_path))
	check.call(saved.campaign.version == 50 and saved.campaign.completed == ["t1_a"], "Deck saves preserve invalid campaign data")
	check.call(store.reset_campaign() and store.campaign_error.is_empty(), "Explicit reset repairs invalid campaign")
	var old_profile := {"schema_version": 2, "selected_deck_id": "starter", "decks": [{"id": "starter", "name": "My customized deck", "card_ids": Array(ProfileMigrator.LEGACY_STARTER_IDS)}]}
	var migrated := ProfileMigrator.migrate_profile_data(old_profile)
	check.call(migrated.data.decks == old_profile.decks and migrated.data.selected_deck_id == "starter", "Schema 2 migration never reruns starter replacement")
	check.call(migrated.data.schema_version == 3 and migrated.data.campaign == null, "Legacy profile gets no campaign progress")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.profile_path))
	store.free()


static func _walk_routes(check: Callable, definition, progress_script, route: Array, choices: Array) -> void:
	for id in choices:
		var progress = progress_script.new()
		for previous in route:
			progress.commit(previous)
			progress.complete(previous)
		check.call(progress.commit(id), "Every authored route can commit its next node")
		var restored = progress_script.from_dictionary(JSON.parse_string(JSON.stringify(progress.to_dictionary())))
		check.call(restored != null and restored.available_nodes() == [id], "Committed save round trip preserves retry")
		progress.complete(id)
		var next_route := route + [id]
		check.call(progress_script.validation_error(progress.to_dictionary()).is_empty(), "Every route produces a valid save")
		if id == "t5_boss":
			check.call(next_route.size() == 5 and progress.is_complete() and progress.available_nodes().is_empty(), "Every route completes in five encounters")
		else:
			_walk_routes(check, definition, progress_script, next_route, definition.nodes[id].next)


static func run_battles(check: Callable, tree: SceneTree) -> void:
	var store := tree.root.get_node("ProfileStore")
	var navigator := tree.root.get_node("SceneNavigator")
	var old_path: String = store.profile_path
	store.profile_path = "user://campaign_battle_test_%d.json" % Time.get_ticks_usec()
	store.load_profile()
	store.initialize_campaign()
	var map = load("res://campaign/campaign_scene.tscn").instantiate()
	tree.root.add_child(map)
	await tree.process_frame
	await tree.process_frame
	var before := JSON.stringify(store.campaign.to_dictionary())
	var disk_before := FileAccess.get_file_as_string(store.profile_path)
	for id in map._map.buttons:
		map._map.buttons[id].grab_focus()
		await tree.process_frame
		check.call(map._selected == id and not map._preview.text.is_empty(), "Keyboard focus inspects each encounter")
	check.call(JSON.stringify(store.campaign.to_dictionary()) == before, "Inspecting all encounters does not commit")
	check.call(FileAccess.get_file_as_string(store.profile_path) == disk_before, "Inspection never writes a route")
	map._reset_dialog.popup_centered()
	map._reset_dialog.get_cancel_button().pressed.emit()
	map._reset_dialog.hide()
	check.call(JSON.stringify(store.campaign.to_dictionary()) == before, "Canceling reset preserves campaign")
	var selected_deck: DeckRecord = store.get_selected_deck()
	var old_cards: Array[StringName] = selected_deck.card_ids.duplicate()
	selected_deck.card_ids.clear()
	map._inspect("t1_a")
	check.call(map._start.disabled and not store.commit_campaign("t1_a") and map._preview.text.contains("26"), "Invalid deck can inspect but cannot start")
	selected_deck.card_ids.assign(old_cards)
	map.free()
	store.commit_campaign("t1_a")
	navigator.campaign_encounter = "t1_a"
	var battle = load("res://battle/battle_scene.tscn").instantiate()
	battle.get_node("BattleController").presentation_delay = 0.0
	tree.root.add_child(battle)
	await tree.process_frame
	await tree.process_frame
	var session: BattleSession = battle.controller.session
	check.call(session != null and session.enemy.definition.id == &"barrier_blob" and session.player_health == 30 and session.turn_number == 1, "Campaign enters exact opponent with fresh Team Heart and round")
	check.call(session.hand.size() + session.draw_pile.size() == 20 and session.battlefield.is_empty() and session.discard_pile.is_empty(), "Campaign opens a fresh selected deck")
	store.profile_writer = func(_data): return ERR_CANT_CREATE
	session.phase = BattleSession.Phase.VICTORY
	battle._refresh()
	check.call(store.campaign.completed.is_empty() and battle._home_button.disabled and battle._retreat_button.disabled and battle._retry_button.visible, "Unsaved victory blocks navigation and offers save retry")
	store.profile_writer = Callable()
	battle._retry()
	battle._refresh()
	check.call(store.campaign.completed == ["t1_a"] and not battle._home_button.disabled and not battle._retry_button.visible, "Saved victory advances once and removes random retry")
	battle.free()
	var edited: Array[StringName] = []
	edited.assign(ProfileMigrator.ACCESS_ALLIES_STARTER_IDS)
	edited[0] = &"take_a_nap"
	edited[1] = &"rally"
	var deck: DeckRecord = store.create_deck("Campaign adaptation")
	store.update_deck(deck.id, deck.name, edited)
	check.call(store.commit_campaign("t2_b"), "Edited selected deck can enter next encounter")
	navigator.campaign_encounter = "t2_b"
	battle = load("res://battle/battle_scene.tscn").instantiate()
	battle.get_node("BattleController").presentation_delay = 0.0
	tree.root.add_child(battle)
	await tree.process_frame
	await tree.process_frame
	session = battle.controller.session
	check.call(session.player_health == 30 and session.enemy.definition.maximum_health == 32 and session.known_definitions.has(&"rally") and not session.known_definitions.has(&"shield_bot"), "Next encounter uses edited deck and tier-scaled opponent with fresh health")
	session.phase = BattleSession.Phase.DEFEAT
	battle._refresh()
	check.call(battle._retry_button.visible and not battle._home_button.disabled and store.campaign.committed == "t2_b", "Defeat offers retry and map without releasing commitment")
	battle.free()
	navigator.campaign_encounter = ""
	battle = load("res://battle/battle_scene.tscn").instantiate()
	battle.get_node("BattleController").presentation_delay = 0.0
	tree.root.add_child(battle)
	await tree.process_frame
	await tree.process_frame
	battle.controller.session.phase = BattleSession.Phase.VICTORY
	battle._refresh()
	check.call(store.campaign.committed == "t2_b" and store.campaign.completed == ["t1_a"] and battle._retry_button.visible, "Standalone victory leaves campaign unchanged and retains retry")
	battle.free()
	for id in ["t2_b", "t3_b", "t4_a"]:
		store.commit_campaign(id)
		store.complete_campaign_encounter(id)
	store.commit_campaign("t5_boss")
	navigator.campaign_encounter = "t5_boss"
	battle = load("res://battle/battle_scene.tscn").instantiate()
	battle.get_node("BattleController").presentation_delay = 0.0
	tree.root.add_child(battle)
	await tree.process_frame
	await tree.process_frame
	battle.controller.session.phase = BattleSession.Phase.VICTORY
	battle._refresh()
	check.call(store.campaign.is_complete() and battle._result_title.text.contains("CAMPAIGN COMPLETE") and not battle._retry_button.visible, "Boss victory saves completed campaign and shows final result")
	battle.free()
	navigator.campaign_encounter = ""
	map = load("res://campaign/campaign_scene.tscn").instantiate()
	tree.root.add_child(map)
	await tree.process_frame
	map._inspect("t5_boss")
	check.call(map._start.disabled and map._notice.text.contains("CAMPAIGN COMPLETE"), "Completed map remains visible with no replay")
	map._reset_dialog.confirmed.emit()
	check.call(store.campaign.completed.is_empty() and store.selected_deck_id == deck.id, "Confirmed reset changes only campaign progress")
	map.free()
	# Play an entire route through the real controller and result screen, allowing
	# fresh retries. This complements the isolated rules/balance simulations.
	store.select_deck("starter")
	for id in ["t1_a", "t2_b", "t3_b", "t4_a", "t5_boss"]:
		check.call(store.commit_campaign(id), "Integrated playthrough saves commitment")
		for attempt in range(1, 51):
			navigator.campaign_encounter = id
			battle = load("res://battle/battle_scene.tscn").instantiate()
			battle.get_node("BattleController").presentation_delay = 0.0
			tree.root.add_child(battle)
			await tree.process_frame
			await tree.process_frame
			battle.controller.start_battle(store.get_selected_deck_definitions(), CampaignDefinition.new().enemy_variant(id, tree.root.get_node("CardCatalog")), load("res://battle/rules/battle_rules.tres"), attempt)
			var played_session: BattleSession = battle.controller.session
			while not played_session.is_finished() and played_session.turn_number < 40:
				var choices := played_session.hand.duplicate()
				choices.sort_custom(func(a, b): return _play_priority(a, played_session) > _play_priority(b, played_session))
				var played := false
				for card in choices:
					if battle.controller.can_play_card(card.instance_id) and _play_priority(card, played_session) > 0:
						battle.controller.request_play_card(card.instance_id)
						played = true
						break
				if not played and not played_session.is_finished():
					battle.controller.request_end_turn()
			var won := played_session.phase == BattleSession.Phase.VICTORY
			battle.free()
			if won:
				break
		check.call(id in store.campaign.completed, "Real battle result persists played victory at %s" % id)
	check.call(store.campaign.is_complete(), "Real controller and result UI complete a full starter-deck campaign")
	navigator.campaign_encounter = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.profile_path))
	store.profile_path = old_path
	store.load_profile()
