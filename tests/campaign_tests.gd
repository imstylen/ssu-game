extends RefCounted

const START := ["petting_meadow", "duck_pond"]
const FINAL := "gremlin_gate"
const SAMPLE_ROUTE := ["petting_meadow", "goat_paddock", "llama_pen", "eagle_aviary", "gremlin_gate"]
# The placeholder map keeps the previous eleven-encounter shape and tier tuning.
# Values worked out from the old formula: base Heart + 2 per tier, pattern
# + [0, 1, 2, 2] by tier, boss 42 Heart with [5, 7, 8].
const TUNING := {
	"petting_meadow": [&"barrier_blob", 26, [2, 4, 8]],
	"duck_pond": [&"assumption_golem", 34, [3, 6, 5]],
	"bird_aviary": [&"assumption_golem", 36, [4, 7, 6]],
	"goat_paddock": [&"siege_core", 32, [5, 6, 8]],
	"lily_pond": [&"barrier_blob", 28, [3, 5, 9]],
	"rocky_ridge": [&"siege_core", 34, [6, 7, 9]],
	"llama_pen": [&"barrier_blob", 30, [4, 6, 10]],
	"flamingo_lagoon": [&"assumption_golem", 38, [5, 8, 7]],
	"eagle_aviary": [&"assumption_golem", 40, [5, 8, 7]],
	"boulder_cave": [&"barrier_blob", 32, [4, 6, 10]],
	"gremlin_gate": [&"siege_core", 42, [5, 7, 8]],
}
const EDGES := {
	"petting_meadow": ["bird_aviary", "goat_paddock"],
	"duck_pond": ["goat_paddock", "lily_pond"],
	"bird_aviary": ["rocky_ridge", "llama_pen"],
	"goat_paddock": ["rocky_ridge", "llama_pen", "flamingo_lagoon"],
	"lily_pond": ["llama_pen", "flamingo_lagoon"],
	"rocky_ridge": ["eagle_aviary"],
	"llama_pen": ["eagle_aviary", "boulder_cave"],
	"flamingo_lagoon": ["boulder_cave"],
	"eagle_aviary": ["gremlin_gate"],
	"boulder_cave": ["gremlin_gate"],
	"gremlin_gate": [],
}


static func run(check: Callable, catalog: Node) -> void:
	var definition := CampaignDefinition.current()
	var errors := definition.validation_errors()
	check.call(errors.is_empty(), "Authored campaign map is valid: %s" % "; ".join(errors))
	check.call(definition.nodes.size() == 11, "Placeholder map keeps eleven encounters")
	check.call(definition.start == Array(START, TYPE_STRING, &"", null), "Entrance leads to both starting encounters")
	check.call(definition.final_id == FINAL, "Gremlin's Gate is the single final encounter")
	for id in EDGES:
		check.call(definition.nodes.has(id) and definition.nodes[id].next == Array(EDGES[id], TYPE_STRING, &"", null), "Authored connections for %s match the placeholder graph" % id)
		var expected: Array = TUNING[id]
		var base: EnemyDefinition = catalog.get_enemy(expected[0])
		var old_health := base.maximum_health
		var old_pattern: PackedInt32Array = base.behavior.attack_pattern.duplicate()
		var variant := definition.enemy_variant(id)
		check.call(variant != null and variant.maximum_health == expected[1], "Campaign Heart for %s matches carried-over tuning" % id)
		check.call(variant != null and variant.behavior.attack_pattern == PackedInt32Array(expected[2]), "Campaign damage for %s matches carried-over tuning" % id)
		check.call(variant.id == base.id and variant.artwork == base.artwork and variant.description == base.description, "Variants preserve enemy identity and art")
		variant.behavior.attack_pattern[0] = 999
		check.call(base.maximum_health == old_health and base.behavior.attack_pattern == old_pattern, "Variants do not mutate base resources")
	check.call(catalog.get_all_enemies().size() == 3, "Variants do not enter standalone pool")
	_test_graph_validation(check, catalog)
	_test_canvas_extraction(check, catalog)
	var progress := CampaignProgress.new()
	check.call(progress.available_nodes() == START, "Both entrances are available")
	check.call(progress.current_position().is_empty(), "A fresh campaign starts at the Entrance")
	check.call(not progress.commit(FINAL), "Cannot commit locked boss")
	check.call(progress.commit("petting_meadow"), "Can commit entrance")
	check.call(progress.current_position() == "petting_meadow", "Commitment moves the current position")
	check.call(progress.node_status("duck_pond") == "skipped" and progress.node_status("lily_pond") == "skipped", "Commitment excludes alternatives and unreachable descendants")
	check.call(progress.node_status("flamingo_lagoon") == "locked", "Merged future path remains reachable")
	check.call(not progress.commit("duck_pond") and progress.commit("petting_meadow"), "Retry preserves exclusive commitment")
	check.call(progress.complete("petting_meadow") and progress.complete("petting_meadow"), "Victory is idempotent")
	check.call(progress.completed.size() == 1 and progress.available_nodes() == ["bird_aviary", "goat_paddock"], "Victory unlocks only outgoing neighbors")
	check.call(progress.current_position() == "petting_meadow", "After victory the player stands at the defeated encounter")
	check.call(not progress.commit("petting_meadow") and not progress.complete("bird_aviary"), "Completed nodes cannot replay and uncommitted nodes cannot win")
	_walk_routes(check, definition, [], START)
	var version := CampaignProgress.VERSION
	for invalid in [null, {}, {"version": 99, "completed": []}, {"version": 1, "completed": ["t1_a"]}, {"version": version, "completed": ["unknown"]}, {"version": version, "completed": ["petting_meadow", "lily_pond"]}, {"version": version, "completed": ["bird_aviary"]}, {"version": version, "completed": ["petting_meadow"], "committed": "petting_meadow"}, {"version": version, "completed": [1]}, {"version": version, "completed": [], "committed": 1}]:
		check.call(not CampaignProgress.validation_error(invalid).is_empty(), "Invalid campaign save is rejected")
	_test_persistence(check)
	_test_full_campaign_play(check, catalog)


static func _graph(catalog: Node, edges: Dictionary, start: Array, finals: Array) -> CampaignDefinition:
	var definition := CampaignDefinition.new()
	definition.start.assign(start)
	for id in edges:
		definition.add_encounter(id, {"enemy": catalog.get_enemy(&"barrier_blob"), "next": edges[id], "is_final": id in finals})
	return definition


static func _test_graph_validation(check: Callable, catalog: Node) -> void:
	var diamond := {"a": ["b", "c"], "b": ["d"], "c": ["d"], "d": []}
	check.call(_graph(catalog, diamond, ["a"], ["d"]).is_valid(), "A branching and merging graph is valid")
	var cases := {
		"loop": [{"a": ["b"], "b": ["a", "d"], "d": []}, ["a"], ["d"], "a"],
		"unreachable": [{"a": ["d"], "e": ["d"], "d": []}, ["a"], ["d"], "e"],
		"dead end": [{"a": ["b", "d"], "b": [], "d": []}, ["a"], ["d"], "b"],
		"two finals": [{"a": ["b", "d"], "b": [], "d": []}, ["a"], ["b", "d"], ""],
		"unknown link": [{"a": ["ghost", "d"], "d": []}, ["a"], ["d"], "ghost"],
		"no start": [{"a": ["d"], "d": []}, [], ["d"], ""],
		"final leads on": [{"a": ["d"], "d": ["a"]}, ["a"], ["d"], "d"],
	}
	for label in cases:
		var spec: Array = cases[label]
		var errors := _graph(catalog, spec[0], spec[1], spec[2]).validation_errors()
		var names_offender: bool = spec[3].is_empty() or "\n".join(errors).contains("'%s'" % spec[3]) or "\n".join(errors).contains(spec[3])
		check.call(not errors.is_empty() and names_offender, "Validation reports a %s and names the encounter" % label)
	var missing_enemy := _graph(catalog, {"a": ["d"], "d": []}, ["a"], ["d"])
	missing_enemy.nodes["a"].enemy = null
	check.call(not missing_enemy.is_valid() and missing_enemy.enemy_variant("a") == null, "An encounter without an enemy is invalid and cannot start")
	var negative := _graph(catalog, {"a": ["d"], "d": []}, ["a"], ["d"])
	negative.nodes["a"].attack_pattern = PackedInt32Array([3, -1])
	check.call(not negative.is_valid(), "Negative damage overrides are rejected")


static func _test_canvas_extraction(check: Callable, catalog: Node) -> void:
	var canvas := CampaignMapCanvas.new()
	var entrance := CampaignEntrance.new()
	canvas.add_child(entrance)
	var first := _encounter(canvas, "first", catalog)
	var duplicate := _encounter(canvas, "first", catalog)
	var unnamed := _encounter(canvas, "", catalog)
	var outsider := CampaignEncounter.new()
	outsider.encounter_id = "outsider"
	entrance.next_encounters.assign([first])
	first.next_encounters.assign([outsider])
	first.is_final = true
	var definition := canvas.build_definition()
	var text := "\n".join(definition.authoring_errors)
	check.call(definition.start == ["first"] and definition.nodes.size() == 1, "Canvas extraction reads the entrance and unique encounters")
	check.call(text.contains("first") and text.contains(str(unnamed.name)) and text.contains(str(first.name)), "Duplicate IDs, missing IDs, and links outside the map are reported")
	check.call(duplicate.get_parent() == canvas and not definition.is_valid(), "An invalid authored map is never valid")
	canvas.add_child(CampaignEntrance.new())
	check.call("\n".join(canvas.build_definition().authoring_errors).contains("exactly one CampaignEntrance"), "Two entrances are reported")
	outsider.free()
	canvas.free()


static func _encounter(canvas: CampaignMapCanvas, id: String, catalog: Node) -> CampaignEncounter:
	var encounter := CampaignEncounter.new()
	encounter.encounter_id = id
	encounter.enemy = catalog.get_enemy(&"barrier_blob")
	canvas.add_child(encounter, true)
	return encounter


static func _test_full_campaign_play(check: Callable, catalog: Node) -> void:
	var deck: Array[CardDefinition] = []
	for id in ProfileMigrator.ACCESS_ALLIES_STARTER_IDS:
		deck.append(catalog.get_card(id))
	var definition := CampaignDefinition.current()
	var completed_route := CampaignProgress.new()
	for node_id in SAMPLE_ROUTE:
		var wins := 0
		var rounds := 0
		for seed_value in range(1, 51):
			var session := BattleSession.new()
			session.initialize(deck, definition.enemy_variant(node_id), load("res://battle/rules/battle_rules.tres"), seed_value)
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
	check.call(store.commit_campaign("petting_meadow"), "Commit saves before battle")
	store.load_profile()
	check.call(store.campaign.committed == "petting_meadow", "Interrupted battle resumes committed")
	store.profile_writer = func(_data): return ERR_CANT_CREATE
	check.call(not store.complete_campaign_encounter("petting_meadow") and store.campaign.completed.is_empty() and store.campaign.committed == "petting_meadow", "Failed victory does not advance memory")
	store.profile_writer = Callable()
	store.load_profile()
	check.call(store.campaign.committed == "petting_meadow", "Failed victory preserves disk commitment")
	check.call(store.complete_campaign_encounter("petting_meadow") and store.complete_campaign_encounter("petting_meadow") and store.campaign.completed.size() == 1, "Saved victory is idempotent")
	store.load_profile()
	check.call(store.campaign.available_nodes() == ["bird_aviary", "goat_paddock"], "Saved victory resumes connected choices")
	store.profile_writer = func(_data): return ERR_CANT_CREATE
	check.call(not store.commit_campaign("bird_aviary") and store.campaign.committed.is_empty(), "Failed commitment cannot enter battle")
	check.call(not store.reset_campaign() and store.campaign.completed.size() == 1, "Failed reset preserves progress")
	store.profile_writer = Callable()
	for id in SAMPLE_ROUTE.slice(1):
		check.call(store.commit_campaign(id) and store.complete_campaign_encounter(id), "Progress saves through boss")
	store.load_profile()
	check.call(store.campaign.is_complete(), "Completed campaign round trips")
	check.call(store.reset_campaign() and store.campaign.completed.is_empty(), "Explicit reset clears route")
	check.call(store.decks.map(func(deck): return deck.to_dictionary()) == original_decks and store.selected_deck_id == original_selected, "Campaign leaves decks and selection intact")
	var corrupt := {"version": 50, "completed": ["petting_meadow"]}
	_write_profile(store.profile_path, 3, original_decks, original_selected, corrupt)
	store.load_profile()
	check.call(store.campaign == null and not store.campaign_error.is_empty() and not store.initialize_campaign(), "Invalid campaign requires explicit reset")
	store.save_profile()
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store.profile_path))
	check.call(saved.campaign.version == 50 and saved.campaign.completed == ["petting_meadow"], "Deck saves preserve invalid campaign data")
	check.call(store.reset_campaign() and store.campaign_error.is_empty(), "Explicit reset repairs invalid campaign")
	# Version 1 progress referred to the old tiered map and quietly restarts.
	_write_profile(store.profile_path, 3, original_decks, original_selected, {"version": 1, "completed": ["t1_a", "t2_b"], "committed": "t3_b"})
	store.load_profile()
	check.call(store.campaign == null and store.campaign_error.is_empty(), "Old tiered campaign progress is discarded without an error")
	check.call(store.decks.map(func(deck): return deck.to_dictionary()) == original_decks and store.selected_deck_id == original_selected, "Discarding old campaign progress keeps decks")
	saved = JSON.parse_string(FileAccess.get_file_as_string(store.profile_path))
	check.call(saved.schema_version == ProfileMigrator.SCHEMA_VERSION and saved.campaign == null, "Migrated profile is saved without old campaign progress")
	check.call(store.initialize_campaign() and store.campaign.available_nodes() == START, "A fresh campaign starts after migration")
	var old_profile := {"schema_version": 2, "selected_deck_id": "starter", "decks": [{"id": "starter", "name": "My customized deck", "card_ids": Array(ProfileMigrator.LEGACY_STARTER_IDS)}]}
	var migrated := ProfileMigrator.migrate_profile_data(old_profile)
	check.call(migrated.data.decks == old_profile.decks and migrated.data.selected_deck_id == "starter", "Schema 2 migration never reruns starter replacement")
	check.call(migrated.data.schema_version == ProfileMigrator.SCHEMA_VERSION and migrated.data.campaign == null, "Legacy profile gets no campaign progress")
	var current_campaign := {"schema_version": 3, "decks": [], "campaign": {"version": CampaignProgress.VERSION, "completed": ["petting_meadow"], "committed": ""}}
	check.call(ProfileMigrator.migrate_profile_data(current_campaign).data.campaign == current_campaign.campaign, "Migration keeps current-version campaign progress")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.profile_path))
	store.free()


static func _write_profile(path: String, schema: int, decks: Array, selected: String, campaign: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version": schema, "decks": decks, "selected_deck_id": selected, "campaign": campaign}))
	file.close()


static func _walk_routes(check: Callable, definition: CampaignDefinition, route: Array, choices: Array) -> void:
	for id in choices:
		var progress := CampaignProgress.new()
		for previous in route:
			progress.commit(previous)
			progress.complete(previous)
		check.call(progress.commit(id), "Every authored route can commit its next node")
		var restored := CampaignProgress.from_dictionary(JSON.parse_string(JSON.stringify(progress.to_dictionary())))
		check.call(restored != null and restored.available_nodes() == [id], "Committed save round trip preserves retry")
		progress.complete(id)
		var next_route := route + [id]
		check.call(CampaignProgress.validation_error(progress.to_dictionary()).is_empty(), "Every route produces a valid save")
		if id == FINAL:
			check.call(next_route.size() == 5 and progress.is_complete() and progress.available_nodes().is_empty(), "Every route completes in five encounters")
		else:
			_walk_routes(check, definition, next_route, definition.nodes[id].next)


static func _visible(view: Control, point: Control) -> bool:
	return Rect2(view.scroll_offset, view.size).encloses(Rect2(point.position, point.size))


static func _wait(tree: SceneTree, seconds: float) -> void:
	await tree.create_timer(seconds).timeout


static func _test_map_view(check: Callable, tree: SceneTree, store: Node) -> void:
	store.reset_campaign()
	var screen = load("res://campaign/campaign_scene.tscn").instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	await tree.process_frame
	var view = screen._map
	var canvas: CampaignMapCanvas = view.canvas
	var entrance := canvas.get_entrance()
	check.call(view.size.x > 1000 and view.size.x < canvas.canvas_size.x and view.size.y < canvas.canvas_size.y, "Map shows at 1:1 in a window smaller than the canvas")
	check.call(_visible(view, entrance) and canvas.current_point == entrance, "A fresh campaign opens on the Entrance with the pin there")
	check.call(absf(entrance.center().x - (view.scroll_offset.x + view.size.x * 0.5)) < 2.0, "The Entrance is centered horizontally (bottom edge clamps vertically)")
	check.call(not _visible(view, view.buttons[FINAL]), "The boss is off screen until the player scrolls")
	for id in view.buttons:
		var encounter: CampaignEncounter = view.buttons[id]
		var available: bool = id in START
		check.call(encounter.state == ("available" if available else "locked"), "Fresh state for %s" % id)
		check.call(is_equal_approx(encounter._material.get_shader_parameter("saturation"), 1.0 if available else 0.0), "%s is %s" % [id, "in color" if available else "black and white"])
	# Mouse wheel and clamping.
	view._set_offset(Vector2(400, 1000))
	var center: Vector2 = view.get_global_rect().get_center()
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = center
	view._input(wheel)
	check.call(view.scroll_offset.is_equal_approx(Vector2(400, 1000 - view.WHEEL_STEP)), "Mouse wheel scrolls the map")
	wheel.position = Vector2(-50, -50)
	view._input(wheel)
	check.call(view.scroll_offset.is_equal_approx(Vector2(400, 1000 - view.WHEEL_STEP)), "Wheel outside the map does not scroll it")
	view._set_offset(Vector2(-900, -900))
	check.call(view.scroll_offset == Vector2.ZERO, "Scrolling stops at the top-left edge")
	view._set_offset(Vector2(99999, 99999))
	check.call(view.scroll_offset.is_equal_approx(canvas.canvas_size - view.size), "Scrolling stops at the bottom-right edge")
	# Click-and-drag pans and does not select the node under the pointer.
	view._set_offset(Vector2(400, 1000))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = center
	view._input(press)
	var motion := InputEventMouseMotion.new()
	motion.position = center + Vector2(-60, 150)
	view._input(motion)
	check.call(view.scroll_offset.is_equal_approx(Vector2(460, 850)), "Dragging pans the map with the pointer")
	var release := press.duplicate()
	release.pressed = false
	release.position = motion.position
	view._input(release)
	view._on_encounter_pressed("duck_pond")
	check.call(view.selected.is_empty() and screen._selected.is_empty(), "A drag ending on a node does not inspect it")
	await tree.process_frame
	view._on_encounter_pressed("duck_pond")
	check.call(screen._selected == "duck_pond", "A plain click inspects the node")
	var small := press.duplicate()
	view._input(small)
	motion.position = center + Vector2(4, 4)
	view._input(motion)
	check.call(view.scroll_offset.is_equal_approx(Vector2(460, 850)), "Small pointer jitter is not a drag")
	release.position = motion.position
	view._input(release)
	# Keyboard focus scrolls any node into view.
	view._set_offset(Vector2.ZERO)
	view.buttons[FINAL].grab_focus()
	await _wait(tree, view.SCROLL_TIME + 0.15)
	check.call(_visible(view, view.buttons[FINAL]) and screen._selected == FINAL, "Focusing the boss scrolls it into view and inspects it")
	var recenter: Button
	for button in screen.find_children("*", "Button", true, false):
		if button.text == "RECENTER MAP":
			recenter = button
	check.call(recenter != null, "The panel offers a Recenter button")
	if recenter != null:
		recenter.pressed.emit()
		await _wait(tree, view.SCROLL_TIME + 0.15)
		check.call(_visible(view, entrance), "Recenter returns to the current position")
	screen.free()
	# After a victory the map opens on the defeated encounter.
	store.commit_campaign("petting_meadow")
	store.complete_campaign_encounter("petting_meadow")
	screen = load("res://campaign/campaign_scene.tscn").instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	await tree.process_frame
	view = screen._map
	canvas = view.canvas
	var meadow: CampaignEncounter = view.buttons["petting_meadow"]
	check.call(canvas.current_point == meadow and meadow.center().distance_to(view.scroll_offset + view.size * 0.5) < 2.0, "The map opens centered on the last victory")
	var expected := {"petting_meadow": "completed", "duck_pond": "skipped", "bird_aviary": "available", "goat_paddock": "available", "lily_pond": "skipped", "flamingo_lagoon": "locked"}
	for id in expected:
		var encounter: CampaignEncounter = view.buttons[id]
		check.call(encounter.state == expected[id], "%s shows as %s" % [id, expected[id]])
	check.call(view.buttons["petting_meadow"].art_saturation() == 1.0 and view.buttons["duck_pond"].art_saturation() == 0.0, "Completed stays in color; skipped turns black and white")
	check.call(canvas.route == ["petting_meadow"], "The chosen route is highlighted")
	screen.free()
	store.reset_campaign()


static func run_battles(check: Callable, tree: SceneTree) -> void:
	var store := tree.root.get_node("ProfileStore")
	var navigator := tree.root.get_node("SceneNavigator")
	var old_path: String = store.profile_path
	store.profile_path = "user://campaign_battle_test_%d.json" % Time.get_ticks_usec()
	store.load_profile()
	store.initialize_campaign()
	await _test_map_view(check, tree, store)
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
	map._inspect("petting_meadow")
	check.call(map._start.disabled and not store.commit_campaign("petting_meadow") and map._preview.text.contains("26") and map._preview.text.contains("Petting Meadow"), "Invalid deck can inspect but cannot start")
	selected_deck.card_ids.assign(old_cards)
	map.free()
	store.commit_campaign("petting_meadow")
	navigator.campaign_encounter = "petting_meadow"
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
	check.call(store.campaign.completed == ["petting_meadow"] and not battle._home_button.disabled and not battle._retry_button.visible, "Saved victory advances once and removes random retry")
	battle.free()
	var edited: Array[StringName] = []
	edited.assign(ProfileMigrator.ACCESS_ALLIES_STARTER_IDS)
	edited[0] = &"take_a_nap"
	edited[1] = &"rally"
	var deck: DeckRecord = store.create_deck("Campaign adaptation")
	store.update_deck(deck.id, deck.name, edited)
	check.call(store.commit_campaign("goat_paddock"), "Edited selected deck can enter next encounter")
	navigator.campaign_encounter = "goat_paddock"
	battle = load("res://battle/battle_scene.tscn").instantiate()
	battle.get_node("BattleController").presentation_delay = 0.0
	tree.root.add_child(battle)
	await tree.process_frame
	await tree.process_frame
	session = battle.controller.session
	check.call(session.player_health == 30 and session.enemy.definition.maximum_health == 32 and session.known_definitions.has(&"rally") and not session.known_definitions.has(&"shield_bot"), "Next encounter uses edited deck and authored opponent tuning with fresh health")
	session.phase = BattleSession.Phase.DEFEAT
	battle._refresh()
	check.call(battle._retry_button.visible and not battle._home_button.disabled and store.campaign.committed == "goat_paddock", "Defeat offers retry and map without releasing commitment")
	battle.free()
	navigator.campaign_encounter = ""
	battle = load("res://battle/battle_scene.tscn").instantiate()
	battle.get_node("BattleController").presentation_delay = 0.0
	tree.root.add_child(battle)
	await tree.process_frame
	await tree.process_frame
	battle.controller.session.phase = BattleSession.Phase.VICTORY
	battle._refresh()
	check.call(store.campaign.committed == "goat_paddock" and store.campaign.completed == ["petting_meadow"] and battle._retry_button.visible, "Standalone victory leaves campaign unchanged and retains retry")
	battle.free()
	for id in ["goat_paddock", "llama_pen", "eagle_aviary"]:
		store.commit_campaign(id)
		store.complete_campaign_encounter(id)
	store.commit_campaign(FINAL)
	navigator.campaign_encounter = FINAL
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
	map._inspect(FINAL)
	check.call(map._start.disabled and map._notice.text.contains("CAMPAIGN COMPLETE"), "Completed map remains visible with no replay")
	map._reset_dialog.confirmed.emit()
	check.call(store.campaign.completed.is_empty() and store.selected_deck_id == deck.id, "Confirmed reset changes only campaign progress")
	map.free()
	# Play an entire route through the real controller and result screen, allowing
	# fresh retries. This complements the isolated rules/balance simulations.
	store.select_deck("starter")
	for id in SAMPLE_ROUTE:
		check.call(store.commit_campaign(id), "Integrated playthrough saves commitment")
		for attempt in range(1, 51):
			navigator.campaign_encounter = id
			battle = load("res://battle/battle_scene.tscn").instantiate()
			battle.get_node("BattleController").presentation_delay = 0.0
			tree.root.add_child(battle)
			await tree.process_frame
			await tree.process_frame
			battle.controller.start_battle(store.get_selected_deck_definitions(), CampaignDefinition.current().enemy_variant(id), load("res://battle/rules/battle_rules.tres"), attempt)
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
