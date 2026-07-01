extends SceneTree

const DamagePopupPoolScript := preload("res://scripts/systems/DamagePopupPool.gd")


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	push_error("[test_damage_popup_pool_settings_gate] %s" % message)
	quit(1)


func _run_test() -> void:
	var pool := DamagePopupPoolScript.new()
	var enabled: bool = bool(pool.call("_is_damage_numbers_enabled"))
	if enabled:
		_fail("damage popup pool fallback must default to disabled when GameSettings is unavailable")
		return

	print("[test_damage_popup_pool_settings_gate] PASS")
	quit(0)
