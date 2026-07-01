extends RefCounted
class_name MobRuntimeBridge

var mob = null
var _overrides: Dictionary = {}


func setup(mob_ref) -> void:
	mob = mob_ref


func set_overrides(overrides: Dictionary) -> void:
	_overrides = overrides.duplicate()


func get_singleton(name: String) -> Node:
	if _overrides.has(name):
		return _overrides[name]
	if mob == null:
		return null
	var tree: SceneTree = mob.get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(name)


func unregister_from_battle_core() -> void:
	var battle_core := get_singleton("BattleCore")
	if battle_core and battle_core.has_method("unregister_mob"):
		battle_core.unregister_mob(mob)


func register_boss_killed() -> void:
	var king_spell_state := get_singleton("KingSpellState")
	if king_spell_state and king_spell_state.has_method("register_boss_killed"):
		king_spell_state.register_boss_killed(1)
