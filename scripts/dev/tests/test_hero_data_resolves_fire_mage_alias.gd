extends SceneTree

const HeroDataScript := preload("res://core/hero/HeroData.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var hero_data = HeroDataScript.new()
	if hero_data == null:
		push_error("[test_hero_data_resolves_fire_mage_alias] failed to create HeroData")
		quit(1)
		return

	var hp := hero_data.get_base_hp("fire_mage")
	var dmg := hero_data.get_base_damage("fire_mage")
	if hp <= 10.0:
		push_error("[test_hero_data_resolves_fire_mage_alias] fire_mage HP must resolve from UnitConfig, got %.2f" % hp)
		quit(1)
		return
	if dmg <= 5.0:
		push_error("[test_hero_data_resolves_fire_mage_alias] fire_mage damage must resolve from UnitConfig, got %.2f" % dmg)
		quit(1)
		return

	print("[test_hero_data_resolves_fire_mage_alias] PASS")
	quit(0)
