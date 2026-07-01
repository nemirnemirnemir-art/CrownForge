extends SceneTree

const MapSlotFeedbackFlowScript := preload("res://scripts/map_slot/MapSlotFeedbackFlow.gd")


class FakeProduction:
	extends RefCounted

	var removed_heroes: Array[String] = []

	func on_hero_died(hero_id: String) -> void:
		removed_heroes.append(hero_id)


class FakeMilitaryTracker:
	extends RefCounted

	var refresh_calls: int = 0

	func refresh_military_unit_labels_across_map(_slot, _callback: Callable) -> void:
		refresh_calls += 1


class FakeAnimations:
	extends RefCounted

	var popups: Array[Dictionary] = []

	func show_production_animation(resource_id: String, amount: int, position_offset: Vector2 = Vector2.ZERO) -> void:
		popups.append({"resource_id": resource_id, "amount": amount, "offset": position_offset})


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MapSlotFeedbackFlowScript.new()
	if flow == null:
		push_error("[test_mapslot_feedback_flow] failed to instantiate helper")
		quit(1)
		return

	var production := FakeProduction.new()
	var tracker := FakeMilitaryTracker.new()
	var animations := FakeAnimations.new()
	var slot := Node.new()
	var label_updated := 0

	flow.on_hero_departed(slot, production, tracker, "hero_1", func() -> void: label_updated += 1)
	if production.removed_heroes != ["hero_1"]:
		push_error("[test_mapslot_feedback_flow] hero departure must propagate to production")
		quit(1)
		return
	if tracker.refresh_calls != 1:
		push_error("[test_mapslot_feedback_flow] hero departure must refresh military labels")
		quit(1)
		return

	flow.on_trade_completed(animations, "gold", 3)
	if animations.popups.is_empty() or animations.popups[-1].get("resource_id", "") != "gold":
		push_error("[test_mapslot_feedback_flow] trade completion must show popup")
		quit(1)
		return

	animations.popups.clear()
	flow.on_production_completed(animations, [
		{"resource_id": "wood", "amount": 1},
		{"resource_id": "clay", "amount": 2},
	], 60.0, 8.0)
	if animations.popups.size() != 2:
		push_error("[test_mapslot_feedback_flow] production completion must show popup for each output")
		quit(1)
		return
	if Vector2(animations.popups[0].get("offset", Vector2.ZERO)).x == Vector2(animations.popups[1].get("offset", Vector2.ZERO)).x:
		push_error("[test_mapslot_feedback_flow] multi-output popups must be spaced apart")
		quit(1)
		return

	print("[test_mapslot_feedback_flow] PASS")
	quit(0)
