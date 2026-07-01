extends SceneTree

const HeroCardBattleScript := preload("res://scripts/hero/card/HeroCardBattle.gd")


func _init() -> void:
	call_deferred("_run_test")


func _hero_core() -> Node:
	return get_root().get_node_or_null("HeroCore")


func _population_core() -> Node:
	return get_root().get_node_or_null("PopulationCore")


func _fail(message: String) -> void:
	push_error("[test_hero_card_battle_population_cap] %s" % message)
	quit(1)


func _create_hero(hero_id: String, is_hired: bool, is_summon: bool, active: bool) -> void:
	var hero_core := _hero_core()
	if hero_core == null:
		_fail("HeroCore autoload must exist")
		return
	if not hero_core.create_hero(hero_id, hero_id.capitalize(), "peasant", 0.0):
		_fail("failed to create hero %s" % hero_id)
		return
	hero_core.update_hero(hero_id, {
		"is_hired": is_hired,
		"is_summon": is_summon,
	})
	if active:
		hero_core.add_to_squad(hero_id)


func _run_test() -> void:
	var hero_core := _hero_core()
	var population_core := _population_core()
	if hero_core == null or population_core == null:
		_fail("HeroCore and PopulationCore autoloads must exist")
		return
	hero_core.reset()
	hero_core.end_current_battle(false)
	population_core.set("_max_population", 5)

	_create_hero("peasant_a", true, false, true)
	_create_hero("peasant_b", true, false, true)
	_create_hero("peasant_c", true, false, true)
	_create_hero("peasant_d", true, false, true)
	_create_hero("peasant_summon", false, true, true)
	_create_hero("peasant_reserve", true, false, false)

	var battle = HeroCardBattleScript.new()
	battle.initialize(null, null)
	battle.on_fight_pressed()

	var in_battle: Array[String] = hero_core.get_heroes_in_battle()
	if in_battle.has("peasant_reserve"):
		_fail("hero card battle must not pull extra reserve heroes when summon occupancy already fills the field cap")
		return
	if in_battle.size() != 4:
		_fail("hero card battle must keep only already-fielded hired heroes when no normal field capacity remains")
		return

	print("[test_hero_card_battle_population_cap] PASS")
	quit(0)
