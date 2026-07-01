extends SceneTree

const TownMageTowerFlowScript := preload("res://core/town/TownMageTowerFlow.gd")


class FakeMageTower:
	extends RefCounted

	var unlock_level: int = 15
	var unlocked: bool = true
	var purchased: bool = false
	var price: int = 1200
	var purchase_result: bool = true
	var debug_unlock_calls: int = 0

	func debug_unlock_all_skills() -> void:
		debug_unlock_calls += 1

	func get_skill_unlock_level(_skill_index: int) -> int:
		return unlock_level

	func is_skill_unlocked(_skill_index: int) -> bool:
		return unlocked

	func is_skill_purchased(_skill_index: int) -> bool:
		return purchased

	func get_skill_price(_skill_index: int) -> int:
		return price

	func try_purchase_skill(_skill_index: int) -> bool:
		return purchase_result


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = TownMageTowerFlowScript.new()
	if flow == null:
		push_error("[test_towncore_mage_tower_flow] failed to instantiate helper")
		quit(1)
		return

	var mage := FakeMageTower.new()
	flow.debug_unlock_all_mage_tower_skills(mage)
	if mage.debug_unlock_calls != 1:
		push_error("[test_towncore_mage_tower_flow] debug unlock must be forwarded")
		quit(1)
		return
	if flow.get_mage_tower_skill_unlock_level(mage, 3) != 15:
		push_error("[test_towncore_mage_tower_flow] unlock level mismatch")
		quit(1)
		return
	if not flow.is_mage_tower_skill_unlocked(mage, 3):
		push_error("[test_towncore_mage_tower_flow] unlocked state mismatch")
		quit(1)
		return
	if flow.is_mage_tower_skill_purchased(mage, 3):
		push_error("[test_towncore_mage_tower_flow] purchased state mismatch")
		quit(1)
		return
	if flow.get_mage_tower_skill_price(mage, 3) != 1200:
		push_error("[test_towncore_mage_tower_flow] skill price mismatch")
		quit(1)
		return
	if not flow.try_purchase_mage_tower_skill(mage, 3):
		push_error("[test_towncore_mage_tower_flow] purchase should succeed")
		quit(1)
		return

	print("[test_towncore_mage_tower_flow] PASS")
	quit(0)
