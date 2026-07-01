extends SceneTree

const SoldierVisualScript = preload("res://scripts/dev/ten_kings/TenKingsSoldierVisual.gd")

var _failed: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[test_ten_kings_soldier_visual_scale_extraction] %s" % message)
	_failed = true


func _run_test() -> void:
	_test_paladin_visual_scale_is_smaller_than_soldier_scale()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_soldier_visual_scale_extraction] PASS")
	quit(0)


func _test_paladin_visual_scale_is_smaller_than_soldier_scale() -> void:
	var visual := SoldierVisualScript.new()
	_assert_true(visual.has_method("_extract_crowd_scale_from_actor_scene"), "soldier visual must expose scale extraction helper")
	var soldier_scale: Vector2 = visual.call("_extract_crowd_scale_from_actor_scene", &"soldier")
	var paladin_scale: Vector2 = visual.call("_extract_crowd_scale_from_actor_scene", &"paladin")
	_assert_true(soldier_scale.x > 0.0, "soldier scale must be extracted")
	_assert_true(paladin_scale.x > 0.0, "paladin scale must be extracted")
	_assert_true(absf(paladin_scale.x) < absf(soldier_scale.x), "paladin scale must stay smaller than soldier scale")
