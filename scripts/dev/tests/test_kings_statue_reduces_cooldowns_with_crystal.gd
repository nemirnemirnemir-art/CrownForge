extends SceneTree

const KingsStatueScript := preload("res://core/buildings/special/KingsStatue.gd")
const KingsStatueConfig := preload("res://data/buildings/kingdom_infrastructure/kings_statue.tres")

var _failed: bool = false

class FakeSlot:
	extends Node

	var slot_index: int = 900
	var current_building_id: String = "kings_statue"

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	var resource_core := _get_autoload("ResourceCore")
	if resource_core != null:
		resource_core.call("reset")
	var king_spell_state := _get_autoload("KingSpellState")
	if king_spell_state != null:
		king_spell_state.call("reset_runtime_state")
	push_error("[test_kings_statue_reduces_cooldowns_with_crystal] %s" % message)
	quit(1)

func _get_autoload(node_name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var king_spell_state := _get_autoload("KingSpellState")
	if king_spell_state == null:
		_fail("KingSpellState autoload must exist")
		return
	var resource_core := _get_autoload("ResourceCore")
	if resource_core == null:
		_fail("ResourceCore autoload must exist")
		return
	if KingsStatueConfig == null:
		_fail("King's Statue config must load")
		return

	king_spell_state.call("reset_runtime_state")
	resource_core.call("reset")
	resource_core.call("add_resource", "crystal", 2)
	king_spell_state.call("set_active_cooldown", "pocket_demons", 12.0)

	var slot := FakeSlot.new()
	get_root().add_child(slot)

	var statue = KingsStatueScript.new()
	if statue == null:
		_fail("King's Statue special must instantiate")
		return
	if not statue.has_method("set_vzor_active"):
		_fail("King's Statue special must expose set_vzor_active")
		return

	statue.initialize(slot, KingsStatueConfig)
	statue.set_vzor_active(true)
	statue.tick(1.0)
	await process_frame

	var cooldown_left := float(king_spell_state.call("get_active_cooldown", "pocket_demons"))
	if absf(cooldown_left - 11.0) > 0.001:
		_fail("King's Statue must reduce cooldown by 1 second, got %.3f" % cooldown_left)
		return

	var crystals_left := int(resource_core.call("get_resource", "crystal"))
	if crystals_left != 0:
		_fail("King's Statue must consume 2 crystal per activation tick, got %d left" % crystals_left)
		return

	resource_core.call("reset")
	king_spell_state.call("reset_runtime_state")
	print("[test_kings_statue_reduces_cooldowns_with_crystal] PASS")
	quit(0)
