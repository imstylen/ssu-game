class_name CampaignProgress
extends RefCounted

var completed: Array[String] = []
var committed: String = ""
var definition := CampaignDefinition.new()


func available_nodes() -> Array:
	if is_complete():
		return []
	if not committed.is_empty():
		return [committed]
	if completed.is_empty():
		return ["t1_a", "t1_b"]
	return definition.nodes[completed.back()].next.duplicate()


func node_status(node_id: String) -> String:
	if not definition.nodes.has(node_id):
		return "locked"
	if node_id in completed:
		return "completed"
	var frontier := available_nodes()
	if node_id in frontier:
		return "available"
	var reachable: Array = frontier.duplicate()
	while not frontier.is_empty():
		var current: String = frontier.pop_front()
		for next in definition.nodes[current].next:
			if next not in reachable:
				reachable.append(next)
				frontier.append(next)
	return "locked" if node_id in reachable else "skipped"


func commit(node_id: String) -> bool:
	if node_id not in available_nodes():
		return false
	committed = node_id
	return true


func complete(node_id: String) -> bool:
	# A repeated notification may acknowledge the latest win, never a later tier.
	if not completed.is_empty() and completed.back() == node_id:
		return true
	if committed.is_empty() or committed != node_id:
		return false
	completed.append(node_id)
	committed = ""
	return true


func is_complete() -> bool:
	return not completed.is_empty() and completed.back() == CampaignDefinition.BOSS


func to_dictionary() -> Dictionary:
	return {"version": CampaignDefinition.VERSION, "completed": completed.duplicate(), "committed": committed}


static func validation_error(data: Variant) -> String:
	if not data is Dictionary or data.get("version") != CampaignDefinition.VERSION:
		return "This campaign uses an unsupported map version. Start New Campaign to reset only campaign progress."
	if not (data.version is int or data.version is float):
		return "This campaign uses an invalid map version. Start New Campaign to reset only campaign progress."
	if not data.get("completed") is Array or not data.get("committed", "") is String:
		return "Campaign route data is invalid. Start New Campaign to reset only campaign progress."
	var progress := CampaignProgress.new()
	for id in data.completed:
		if not id is String or not progress.commit(id) or not progress.complete(id):
			return "The saved campaign route is invalid. Start New Campaign to reset only campaign progress."
	var commitment: String = data.get("committed", "")
	if not commitment.is_empty() and not progress.commit(commitment):
		return "The saved encounter does not connect to this route. Start New Campaign to reset only campaign progress."
	return ""


static func from_dictionary(data: Variant) -> CampaignProgress:
	if not validation_error(data).is_empty():
		return null
	var progress := CampaignProgress.new()
	progress.completed.assign(data.completed)
	progress.committed = data.get("committed", "")
	return progress
