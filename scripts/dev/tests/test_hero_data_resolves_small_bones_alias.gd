extends SceneTree

const HeroDataScript := preload("res://core/hero/HeroData.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var hero_data := HeroDataScript.new()
	if hero_data == null:
		push_error("[test_hero_data_resolves_small_bones_alias] failed to create HeroData")
		quit(1)
		return

	var cfg: Variant = hero_data.call("_try_load_unit_config", "small")
	if cfg == null:
		push_error("[test_hero_data_resolves_small_bones_alias] expected alias 'small' to resolve to a unit config")
		quit(1)
		return

	var resolved_id := ""
	if "unit_id" in cfg:
		resolved_id = String(cfg.unit_id)

	if resolved_id != "small_bones":
		push_error("[test_hero_data_resolves_small_bones_alias] alias 'small' must resolve to small_bones")
		quit(1)
		return

	print("[test_hero_data_resolves_small_bones_alias] PASS")
	quit(0)
