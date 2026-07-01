extends SceneTree

const TownAlchemyFlowScript := preload("res://core/town/TownAlchemyFlow.gd")


class FakeAlchemy:
	extends RefCounted

	var updated: bool = false
	var update_result: bool = false
	var queue: Array[Dictionary] = [{"potion_id": "minor_heal"}]
	var remaining_sec: int = 77
	var enqueue_result: bool = true
	var cancel_result: bool = true
	var enqueue_calls: Array[String] = []
	var cancel_calls: Array[int] = []

	func update() -> bool:
		updated = true
		return update_result

	func get_potion_defs() -> Dictionary:
		return {"minor_heal": {}}

	func get_queue() -> Array[Dictionary]:
		return queue.duplicate(true)

	func get_active_remaining_sec() -> int:
		return remaining_sec

	func try_enqueue(potion_id: String) -> bool:
		enqueue_calls.append(potion_id)
		return enqueue_result

	func try_cancel(index: int) -> bool:
		cancel_calls.append(index)
		return cancel_result


class FakeSaveCore:
	extends RefCounted

	var requests: int = 0

	func request_save() -> void:
		requests += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = TownAlchemyFlowScript.new()
	if flow == null:
		push_error("[test_towncore_alchemy_flow] failed to instantiate helper")
		quit(1)
		return

	var alchemy := FakeAlchemy.new()
	var save_core := FakeSaveCore.new()
	alchemy.update_result = true

	var queue: Array[Dictionary] = flow.get_alchemy_queue(alchemy, save_core)
	if queue.size() != 1 or save_core.requests != 1:
		push_error("[test_towncore_alchemy_flow] queue fetch must autosave after update")
		quit(1)
		return

	var remaining: int = flow.get_alchemy_active_remaining_sec(alchemy, save_core)
	if remaining != 77 or save_core.requests != 2:
		push_error("[test_towncore_alchemy_flow] remaining time fetch must autosave after update")
		quit(1)
		return

	if not flow.try_enqueue_alchemy(alchemy, save_core, "minor_heal"):
		push_error("[test_towncore_alchemy_flow] enqueue should succeed")
		quit(1)
		return
	if save_core.requests != 4:
		push_error("[test_towncore_alchemy_flow] enqueue success must request save")
		quit(1)
		return

	if not flow.try_cancel_alchemy(alchemy, save_core, 0):
		push_error("[test_towncore_alchemy_flow] cancel should succeed")
		quit(1)
		return
	if save_core.requests != 6:
		push_error("[test_towncore_alchemy_flow] cancel success must request save")
		quit(1)
		return

	print("[test_towncore_alchemy_flow] PASS")
	quit(0)
