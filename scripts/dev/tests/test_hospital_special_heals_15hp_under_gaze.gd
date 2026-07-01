extends SceneTree

const HospitalScript := preload("res://core/buildings/special/Hospital.gd")
const HospitalConfig := preload("res://data/buildings/kingdom_infrastructure/hospital.tres")

var _failed: bool = false

class FakeSlot:
	extends Node

	var slot_index: int = 777
	var current_building_id: String = "hospital"

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_hospital_special_heals_15hp_under_gaze] %s" % message)
	var hero_core := _get_hero_core()
	if hero_core != null:
		hero_core.call("reset")
	quit(1)

func _get_hero_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HeroCore")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var hero_core := _get_hero_core()
	if hero_core == null:
		_fail("HeroCore autoload must exist")
		return
	if HospitalConfig == null:
		_fail("Hospital config must load")
		return

	hero_core.call("reset")
	hero_core.call("ensure_hero_template", "militia", "Militia")
	var hero_id: String = String(hero_core.call("hire_hero_copy", "militia"))
	if hero_id == "":
		_fail("Failed to create test hero")
		return
	hero_core.call("update_hero", hero_id, {
		"hp": 40.0,
		"maxHp": 100.0,
		"is_hired": true,
	})
	hero_core.call("add_to_squad", hero_id)

	var slot := FakeSlot.new()
	get_root().add_child(slot)

	var hospital = HospitalScript.new()
	if hospital == null:
		_fail("Hospital special must instantiate")
		return
	if not hospital.has_method("initialize"):
		_fail("Hospital special must implement initialize")
		return
	if not hospital.has_method("set_vzor_active"):
		_fail("Hospital special must be gaze-aware via set_vzor_active")
		return

	hospital.initialize(slot, HospitalConfig)
	var hero_query: Variant = hero_core.get("query")
	if hero_query == null:
		_fail("HeroCore query API must exist")
		return
	var before_hp := float(hero_query.call("get_hero_hp", hero_id))

	hospital.set_vzor_active(false)
	hospital.tick(1.0)
	await process_frame
	var inactive_hp := float(hero_query.call("get_hero_hp", hero_id))
	if absf(inactive_hp - before_hp) > 0.001:
		_fail("Hospital must not heal when not under gaze")
		return

	hospital.set_vzor_active(true)
	hospital.tick(1.0)
	await process_frame
	var active_hp := float(hero_query.call("get_hero_hp", hero_id))
	var healed_amount := int(round(active_hp - before_hp))
	if healed_amount != 15:
		_fail("Hospital must heal exactly 15 HP per tick under gaze, got %d" % healed_amount)
		return

	hero_core.call("reset")
	print("[test_hospital_special_heals_15hp_under_gaze] PASS")
	quit(0)
