extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var script = load("res://scripts/ui/town/buildings/BuildingsTooltipDataProvider.gd")
	if script == null:
		push_error("[test_buildings_tooltip_data_provider] failed to load")
		quit(1)
		return
	print("[test_buildings_tooltip_data_provider] PASS")
	quit(0)
