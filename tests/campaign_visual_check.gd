extends SceneTree


func _init() -> void:
	call_deferred("_run")


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
		scene._map.buttons["t1_a"].grab_focus()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/campaign_%d.png" % resolution.x)
		store.commit_campaign("t1_a")
		store.complete_campaign_encounter("t1_a")
		store.commit_campaign("t2_b")
		scene._map.buttons["t2_b"].grab_focus()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/campaign_states_%d.png" % resolution.x)
		scene.free()
		store.reset_campaign()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.profile_path))
	print("CAMPAIGN_VISUAL_CAPTURE_OK")
	quit()
