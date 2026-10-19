class_name CampaignDefinition
extends RefCounted

const VERSION := 1
const BOSS := "t5_boss"
const DAMAGE_BONUS_BY_TIER := [0, 1, 2, 2, 0]
const BOSS_HEART := 42
const BOSS_PATTERN := [5, 7, 8]

# Encounter IDs are save identifiers; enemy IDs remain catalog identities.
var nodes: Dictionary = {
	"t1_a": {"tier": 1, "column": 0, "enemy_id": &"barrier_blob", "next": ["t2_a", "t2_b"]},
	"t1_b": {"tier": 1, "column": 1, "enemy_id": &"assumption_golem", "next": ["t2_b", "t2_c"]},
	"t2_a": {"tier": 2, "column": 0, "enemy_id": &"assumption_golem", "next": ["t3_a", "t3_b"]},
	"t2_b": {"tier": 2, "column": 1, "enemy_id": &"siege_core", "next": ["t3_a", "t3_b", "t3_c"]},
	"t2_c": {"tier": 2, "column": 2, "enemy_id": &"barrier_blob", "next": ["t3_b", "t3_c"]},
	"t3_a": {"tier": 3, "column": 0, "enemy_id": &"siege_core", "next": ["t4_a"]},
	"t3_b": {"tier": 3, "column": 1, "enemy_id": &"barrier_blob", "next": ["t4_a", "t4_b"]},
	"t3_c": {"tier": 3, "column": 2, "enemy_id": &"assumption_golem", "next": ["t4_b"]},
	"t4_a": {"tier": 4, "column": 0, "enemy_id": &"assumption_golem", "next": ["t5_boss"]},
	"t4_b": {"tier": 4, "column": 1, "enemy_id": &"barrier_blob", "next": ["t5_boss"]},
	"t5_boss": {"tier": 5, "column": 0, "enemy_id": &"siege_core", "next": []},
}


func enemy_variant(node_id: String, catalog: Node) -> EnemyDefinition:
	if not nodes.has(node_id):
		return null
	var node: Dictionary = nodes[node_id]
	var base: EnemyDefinition = catalog.get_enemy(node.enemy_id)
	if base == null or not base.behavior is PatternEnemyBehavior:
		return null
	var variant := base.duplicate() as EnemyDefinition
	var behavior := base.behavior.duplicate() as PatternEnemyBehavior
	behavior.attack_pattern = behavior.attack_pattern.duplicate()
	variant.behavior = behavior
	if node_id == BOSS:
		variant.maximum_health = BOSS_HEART
		behavior.attack_pattern = PackedInt32Array(BOSS_PATTERN)
	else:
		variant.maximum_health += 2 * (node.tier - 1)
		for index in behavior.attack_pattern.size():
			behavior.attack_pattern[index] += DAMAGE_BONUS_BY_TIER[node.tier - 1]
	return variant
