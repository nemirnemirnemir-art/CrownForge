extends SceneTree

const VzorZoneModelScript := preload("res://scripts/ui/gaze/VzorZoneModel.gd")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var model = VzorZoneModelScript.new()
	if model == null:
		push_error("[test_vzorzone_model] failed to instantiate")
		quit(1)
		return
	# Test that _SHAPES_3 has 4 entries
	if model._SHAPES_3.size() != 4:
		push_error("[test_vzorzone_model] expected 4 shapes, got %d" % model._SHAPES_3.size())
		quit(1)
		return
	print("[test_vzorzone_model] PASS")
	quit(0)
