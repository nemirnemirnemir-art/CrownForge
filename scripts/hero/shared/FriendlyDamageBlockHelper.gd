extends RefCounted
class_name FriendlyDamageBlockHelper

const INDESTRUCTIBLE_SHIELD_ID := "indestructible_shield"
const BLOCK_CHANCE := 0.10


static func should_block_damage(host: Node = null, roll_provider: Callable = Callable()) -> bool:
	var artifact_core := _get_artifact_core(host)
	if artifact_core == null:
		return false
	var chance := 0.0
	if artifact_core.has_method("get_friendly_full_damage_block_chance"):
		chance = float(artifact_core.call("get_friendly_full_damage_block_chance"))
	elif artifact_core.has_method("is_active") and bool(artifact_core.call("is_active", INDESTRUCTIBLE_SHIELD_ID)):
		chance = BLOCK_CHANCE
	if chance <= 0.0:
		return false

	var roll := randf()
	if roll_provider.is_valid():
		roll = clampf(float(roll_provider.call()), 0.0, 1.0)
	return roll < clampf(chance, 0.0, 1.0)


static func _get_artifact_core(host: Node = null) -> Node:
	if host != null:
		var tree := host.get_tree()
		if tree != null and tree.root != null:
			return tree.root.get_node_or_null("ArtifactCore")

	var main_loop := Engine.get_main_loop() as SceneTree
	if main_loop == null or main_loop.root == null:
		return null
	return main_loop.root.get_node_or_null("ArtifactCore")
