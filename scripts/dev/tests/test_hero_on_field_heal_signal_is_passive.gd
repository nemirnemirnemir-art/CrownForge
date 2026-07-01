extends SceneTree

const HeroOnFieldScene := preload("res://scenes/heroes/HeroOnField.tscn")

var _failed := false

func _get_hero_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HeroCore")

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	var hero_core := _get_hero_core()
	if hero_core != null:
		hero_core.call("reset")
	push_error("[test_hero_on_field_heal_signal_is_passive] %s" % message)
	quit(1)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var hero_core := _get_hero_core()
	if hero_core == null:
		_fail("HeroCore autoload must exist")
		return
	hero_core.call("reset")
	hero_core.call("ensure_hero_template", "militia", "Militia")
	var hero_id := String(hero_core.call("hire_hero_copy", "militia"))
	if hero_id == "":
		_fail("Failed to hire test hero")
		return
	hero_core.call("update_hero", hero_id, {
		"hp": 40.0,
		"maxHp": 100.0,
		"is_hired": true,
		"isActive": true,
	})

	var hero_on_field := HeroOnFieldScene.instantiate()
	if hero_on_field == null:
		_fail("HeroOnField scene must instantiate")
		return
	hero_on_field.hero_id = hero_id
	get_root().add_child(hero_on_field)
	await process_frame
	await process_frame

	var heal_handler := Callable(hero_on_field, "_on_hero_healed")
	if hero_core.hero_healed.is_connected(heal_handler):
		hero_core.hero_healed.disconnect(heal_handler)

	var before_hp := float(hero_core.get("query").call("get_hero_hp", hero_id))
	hero_on_field.call("_on_hero_healed", hero_id, 15.0)
	await process_frame
	var after_hp := float(hero_core.get("query").call("get_hero_hp", hero_id))
	if absf(after_hp - before_hp) > 0.001:
		_fail("HeroOnField heal signal handler must not re-apply healing to HeroCore")
		return

	hero_core.call("reset")
	print("[test_hero_on_field_heal_signal_is_passive] PASS")
	quit(0)
