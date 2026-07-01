extends SceneTree

const SaveIOFlowScript := preload("res://core/save/SaveIOFlow.gd")


class FakeSaveManager:
	extends RefCounted

	var written: Dictionary = {}
	var read_payload: Dictionary = {}

	func write_json(_path: String, data: Dictionary) -> bool:
		written = data.duplicate(true)
		return true

	func read_json(_path: String) -> Dictionary:
		return read_payload.duplicate(true)


class FakeModule:
	extends RefCounted

	var saved: Dictionary = {"ok": true}
	var loaded: Dictionary = {}

	func get_save_data() -> Dictionary:
		return saved.duplicate(true)

	func load_save_data(data: Dictionary) -> void:
		loaded = data.duplicate(true)


class FakeCounter:
	extends RefCounted

	var calls: int = 0

	func bump() -> void:
		calls += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = SaveIOFlowScript.new()
	if flow == null:
		push_error("[test_savecore_io_flow] failed to instantiate helper")
		quit(1)
		return

	var save_manager := FakeSaveManager.new()
	var modules := {"heroes": FakeModule.new(), "town": FakeModule.new()}
	var saved: bool = flow.save_game(save_manager, "user://save.json", true, false, 2, true, modules)
	if not saved or save_manager.written.size() != 2:
		push_error("[test_savecore_io_flow] save flow mismatch")
		quit(1)
		return

	save_manager.read_payload = {"heroes": {"x": 1}, "town": {"y": 2}}
	var loaded := FakeCounter.new()
	var ok: bool = flow.load_game(save_manager, "user://save.json", modules, Callable(loaded, "bump"))
	if not ok or loaded.calls != 1:
		push_error("[test_savecore_io_flow] load flow mismatch")
		quit(1)
		return
	if modules["heroes"].loaded.get("x", 0) != 1:
		push_error("[test_savecore_io_flow] module load data mismatch")
		quit(1)
		return

	print("[test_savecore_io_flow] PASS")
	quit(0)
