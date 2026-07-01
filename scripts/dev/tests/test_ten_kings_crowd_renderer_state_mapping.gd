extends SceneTree

const CrowdRendererScript = preload("res://scripts/dev/ten_kings/TenKingsCrowdRenderer.gd")

var _failed: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	push_error("[test_ten_kings_crowd_renderer_state_mapping] %s (actual=%s expected=%s)" % [message, str(actual), str(expected)])
	_failed = true


func _run_test() -> void:
	_test_runtime_state_mapping_matches_visual_contract()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_crowd_renderer_state_mapping] PASS")
	quit(0)


func _test_runtime_state_mapping_matches_visual_contract() -> void:
	var renderer := CrowdRendererScript.new()
	_assert_equal(renderer.call("_map_runtime_state_to_visual_state", "idle"), "idle", "idle should stay idle")
	_assert_equal(renderer.call("_map_runtime_state_to_visual_state", "walking"), "walk", "walking should map to walk")
	_assert_equal(renderer.call("_map_runtime_state_to_visual_state", "attacking"), "attack", "attacking should map to attack")
	_assert_equal(renderer.call("_map_runtime_state_to_visual_state", "dying"), "death", "dying should map to death")
	_assert_equal(renderer.call("_map_runtime_state_to_visual_state", "dead"), "death", "dead should map to death")
