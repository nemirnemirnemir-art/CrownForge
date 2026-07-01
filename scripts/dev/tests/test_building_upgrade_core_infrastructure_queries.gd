extends SceneTree

var _failed: bool = false

class FakeSpecialHandler:
	extends RefCounted

	var morale_bonus: int = 0

	func get_morale_bonus() -> int:
		return morale_bonus

class FakeSlot:
	extends Node

	var slot_index: int = -1
	var current_building_id: String = ""
	var _vzor_active: bool = false
	var _special_handler: RefCounted = null

	func _init(new_slot_index: int, building_id: String, vzor_active: bool, handler: RefCounted = null) -> void:
		slot_index = new_slot_index
		current_building_id = building_id
		_vzor_active = vzor_active
		_special_handler = handler

	func is_effectively_vzor_active() -> bool:
		return _vzor_active

	func get_special_handler() -> RefCounted:
		return _special_handler

class FakeMapLayout:
	extends Node

	var slots: Array = []

class FakeGameScene:
	extends Node

	var map_layout_node: Node = null

func _upgrade_core() -> Node:
	return get_root().get_node_or_null("BuildingUpgradeCore")

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_building_upgrade_core_infrastructure_queries] %s" % message)
	var upgrade_core := _upgrade_core()
	if upgrade_core:
		upgrade_core.call("load_save_data", {"upgrades_by_slot": {}})
	quit(1)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var upgrade_core := _upgrade_core()
	if upgrade_core == null:
		_fail("BuildingUpgradeCore autoload must exist")
		return

	upgrade_core.call("load_save_data", {"upgrades_by_slot": {}})

	var hospital_handler := FakeSpecialHandler.new()
	hospital_handler.morale_bonus = 4

	var map_layout := FakeMapLayout.new()
	map_layout.slots = [
		FakeSlot.new(1, "concert", true),
		FakeSlot.new(2, "sawmill", true),
		FakeSlot.new(3, "magic_ball", true),
		FakeSlot.new(4, "hospital", true, hospital_handler),
		FakeSlot.new(5, "kings_statue", false),
	]

	var game_scene := FakeGameScene.new()
	game_scene.map_layout_node = map_layout
	game_scene.add_to_group("game_scene")
	get_root().add_child(game_scene)
	await process_frame

	upgrade_core.call("apply_upgrade", 1, "concert:0")
	upgrade_core.call("apply_upgrade", 1, "concert:1")
	upgrade_core.call("apply_upgrade", 3, "magic_ball:0")
	upgrade_core.call("apply_upgrade", 5, "kings_statue:1")

	var concert_speed := float(upgrade_core.call("get_concert_slot_production_speed_multiplier", 2))
	if absf(concert_speed - 1.3) > 0.001:
		_fail("Active Concert must give 1.3x production speed to a watched slot, got %.3f" % concert_speed)
		return

	var active_concert_morale := int(upgrade_core.call("get_active_concert_morale_bonus"))
	if active_concert_morale != 10:
		_fail("Concert active morale upgrade must give 10 morale, got %d" % active_concert_morale)
		return

	var passive_concert_morale := int(upgrade_core.call("get_passive_concert_morale_bonus"))
	if passive_concert_morale != 5:
		_fail("Concert passive morale upgrade must give 5 morale, got %d" % passive_concert_morale)
		return

	var hospital_morale := int(upgrade_core.call("get_active_hospital_morale_bonus"))
	if hospital_morale != 4:
		_fail("Hospital active morale bonus must include handler morale bonus, got %d" % hospital_morale)
		return

	var magic_ball_mult := float(upgrade_core.call("get_magic_ball_spell_damage_multiplier"))
	if absf(magic_ball_mult - 1.8) > 0.001:
		_fail("Magic Ball with second upgrade must give 1.8x spell damage, got %.3f" % magic_ball_mult)
		return

	var champion_hp_mult := float(upgrade_core.call("get_kings_statue_champion_hp_multiplier"))
	if absf(champion_hp_mult - 1.1) > 0.001:
		_fail("King's Statue champion HP bonus must be 1.1x, got %.3f" % champion_hp_mult)
		return

	var champion_damage_mult := float(upgrade_core.call("get_kings_statue_champion_damage_multiplier"))
	if absf(champion_damage_mult - 1.1) > 0.001:
		_fail("King's Statue champion damage bonus must be 1.1x, got %.3f" % champion_damage_mult)
		return

	upgrade_core.call("load_save_data", {"upgrades_by_slot": {}})
	game_scene.queue_free()
	print("[test_building_upgrade_core_infrastructure_queries] PASS")
	quit(0)
