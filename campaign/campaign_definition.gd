class_name CampaignDefinition
extends RefCounted

# The authored map scene is the single source of truth for encounters,
# their connections, tuning, and map positions. See CampaignMapCanvas.
const MAP_SCENE := "res://campaign/maps/zoo_trail.tscn"

static var _current: CampaignDefinition

# Encounter IDs are save identifiers; enemy IDs remain catalog identities.
# id -> {display_name, enemy, maximum_health, attack_pattern, next, is_final}
var nodes: Dictionary = {}
var start: Array[String] = []
var final_id: String = ""
# Problems found while reading the authored scene (missing IDs, broken links).
var authoring_errors := PackedStringArray()


static func current() -> CampaignDefinition:
	if _current == null:
		_current = from_scene(load(MAP_SCENE))
	return _current


static func from_scene(scene: PackedScene) -> CampaignDefinition:
	if scene == null:
		var missing := CampaignDefinition.new()
		missing.authoring_errors.append("The campaign map scene could not be loaded.")
		return missing
	var canvas := scene.instantiate()
	var definition: CampaignDefinition
	if canvas.has_method("build_definition"):
		definition = canvas.build_definition()
	else:
		definition = CampaignDefinition.new()
		definition.authoring_errors.append("The campaign map scene root must use CampaignMapCanvas.")
	canvas.free()
	return definition


func add_encounter(id: String, data: Dictionary) -> void:
	var next: Array[String] = []
	next.assign(data.get("next", []))
	var pattern: PackedInt32Array = data.get("attack_pattern", PackedInt32Array())
	nodes[id] = {
		"display_name": str(data.get("display_name", "")),
		"enemy": data.get("enemy"),
		"maximum_health": int(data.get("maximum_health", 0)),
		"attack_pattern": pattern.duplicate(),
		"next": next,
		"is_final": bool(data.get("is_final", false)),
	}
	if nodes[id].is_final:
		final_id = id


func display_name(node_id: String) -> String:
	if not nodes.has(node_id):
		return ""
	var label: String = nodes[node_id].display_name
	if label.strip_edges().is_empty() and nodes[node_id].enemy != null:
		return nodes[node_id].enemy.display_name
	return label


func validation_errors() -> PackedStringArray:
	var errors := authoring_errors.duplicate()
	if start.is_empty():
		errors.append("The Entrance must lead to at least one encounter.")
	for id in start:
		if not nodes.has(id):
			errors.append("The Entrance leads to unknown encounter '%s'." % id)
	var finals: Array[String] = []
	for id in nodes:
		var node: Dictionary = nodes[id]
		if node.is_final:
			finals.append(id)
		var enemy: EnemyDefinition = node.enemy
		if enemy == null:
			errors.append("Encounter '%s' needs an enemy." % id)
		elif not node.attack_pattern.is_empty() and not enemy.behavior is PatternEnemyBehavior:
			errors.append("Encounter '%s' overrides an attack pattern, but its enemy has no pattern behavior." % id)
		if node.maximum_health < 0:
			errors.append("Encounter '%s' has a negative Heart override." % id)
		for damage in node.attack_pattern:
			if damage < 0:
				errors.append("Encounter '%s' has negative damage in its attack pattern." % id)
				break
		for next in node.next:
			if not nodes.has(next):
				errors.append("Encounter '%s' leads to unknown encounter '%s'." % [id, next])
		if node.is_final and not node.next.is_empty():
			errors.append("The final encounter '%s' must not lead anywhere." % id)
		if not node.is_final and node.next.is_empty():
			errors.append("Encounter '%s' is a dead end; connect it onward or mark it final." % id)
	if finals.size() != 1:
		errors.append("The map needs exactly one final encounter (found %d)." % finals.size())
	var cycle := _find_cycle()
	if not cycle.is_empty():
		errors.append("Encounters form a loop: %s." % " → ".join(PackedStringArray(cycle)))
	var reachable := _reachable_from(start)
	for id in nodes:
		if id not in reachable:
			errors.append("Encounter '%s' cannot be reached from the Entrance." % id)
	if finals.size() == 1:
		for id in nodes:
			if not _reaches(id, finals[0]):
				errors.append("Encounter '%s' has no route to the final encounter." % id)
	return errors


func is_valid() -> bool:
	return validation_errors().is_empty()


func enemy_variant(node_id: String) -> EnemyDefinition:
	if not nodes.has(node_id):
		return null
	var node: Dictionary = nodes[node_id]
	var base: EnemyDefinition = node.enemy
	if base == null:
		return null
	# Duplicate so campaign tuning never mutates the shared catalog resource.
	var variant := base.duplicate() as EnemyDefinition
	if base.behavior != null:
		variant.behavior = base.behavior.duplicate()
		if variant.behavior is PatternEnemyBehavior:
			variant.behavior.attack_pattern = base.behavior.attack_pattern.duplicate()
	if node.maximum_health > 0:
		variant.maximum_health = node.maximum_health
	if not node.attack_pattern.is_empty():
		if not variant.behavior is PatternEnemyBehavior:
			return null
		variant.behavior.attack_pattern = node.attack_pattern.duplicate()
	return variant


func _reachable_from(roots: Array) -> Array:
	var reachable: Array = []
	var frontier: Array = []
	for id in roots:
		if nodes.has(id) and id not in reachable:
			reachable.append(id)
			frontier.append(id)
	while not frontier.is_empty():
		var current: String = frontier.pop_front()
		for next in nodes[current].next:
			if nodes.has(next) and next not in reachable:
				reachable.append(next)
				frontier.append(next)
	return reachable


func _reaches(from_id: String, target: String) -> bool:
	return target in _reachable_from([from_id])


func _find_cycle() -> Array:
	# 0 = unvisited, 1 = on the current path, 2 = finished.
	var marks: Dictionary = {}
	for id in nodes:
		var path: Array = []
		var found := _visit(id, marks, path)
		if not found.is_empty():
			return found
	return []


func _visit(id: String, marks: Dictionary, path: Array) -> Array:
	var mark: int = marks.get(id, 0)
	if mark == 2:
		return []
	if mark == 1:
		return path.slice(path.find(id)) + [id]
	marks[id] = 1
	path.append(id)
	for next in nodes[id].next:
		if nodes.has(next):
			var found := _visit(next, marks, path)
			if not found.is_empty():
				return found
	path.pop_back()
	marks[id] = 2
	return []
