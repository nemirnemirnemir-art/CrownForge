extends SceneTree

const TroopBonusCoreScript := preload("res://core/troop_bonus_core.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var core := TroopBonusCoreScript.new()
	if core == null:
		push_error("[test_troop_bonus_core_resolves_unit_aliases] failed to create troop_bonus_core")
		quit(1)
		return

	var classes: Variant = core.call("get_unit_classes", "small")
	if not (classes is Array):
		push_error("[test_troop_bonus_core_resolves_unit_aliases] get_unit_classes must return Array")
		quit(1)
		return

	var unit_classes := classes as Array
	if unit_classes.is_empty():
		push_error("[test_troop_bonus_core_resolves_unit_aliases] expected alias 'small' to resolve unit classes")
		quit(1)
		return

	if not unit_classes.has(int(UnitConfig.UnitClass.UNDEAD)):
		push_error("[test_troop_bonus_core_resolves_unit_aliases] expected undead class for small_bones alias")
		quit(1)
		return

	print("[test_troop_bonus_core_resolves_unit_aliases] PASS")
	quit(0)
