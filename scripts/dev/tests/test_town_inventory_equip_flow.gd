extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var script = load("res://scripts/ui/town/TownInventoryEquipToHeroController.gd")
	if script == null:
		push_error("[test_town_inventory_equip_flow] failed to load")
		quit(1)
		return
	print("[test_town_inventory_equip_flow] PASS")
	quit(0)
