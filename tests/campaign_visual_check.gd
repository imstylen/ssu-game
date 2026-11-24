extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/%s.png" % name)


func _run() -> void:
	var store := root.get_node("ProfileStore")
	store.profile_path = "user://campaign_visual_test.json"
	store.load_profile()
	store.reset_campaign()
	root.mode = Window.MODE_WINDOWED
	for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = resolution
		var scene = load("res://campaign/campaign_scene.tscn").instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame
		# Fresh campaign: opens on the Entrance; starting encounters in color.
		await _capture("campaign_%d" % resolution.x)
		store.commit_campaign("petting_meadow")
		store.complete_campaign_encounter("petting_meadow")
		store.commit_campaign("goat_paddock")
		scene._map.buttons["goat_paddock"].grab_focus()
		await create_timer(0.5).timeout
		# Mid-route: completed, committed, skipped, and locked states with the pin.
		await _capture("campaign_states_%d" % resolution.x)
		scene._map.buttons["gremlin_gate"].grab_focus()
		await create_timer(0.5).timeout
		# Keyboard focus scrolled to the boss at the top of the map.
		await _capture("campaign_boss_%d" % resolution.x)
		scene.free()
		store.reset_campaign()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.profile_path))
	print("CAMPAIGN_VISUAL_CAPTURE_OK")
	quit()
