extends SceneTree

var _failed := false

class FakeGameScene:
	extends Node2D

func _get_resource_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ResourceCore")

func _get_event_bus() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("EventBus")

func _get_morale_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("MoraleSystem")

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	var event_bus := _get_event_bus()
	if event_bus != null and event_bus.has_signal("wave_completed"):
		event_bus.wave_completed.emit(-1)
	var resource_core := _get_resource_core()
	if resource_core != null:
		resource_core.call("reset")
	push_error("[test_morale_system_wine_consumption] %s" % message)
	quit(1)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var morale_system := _get_morale_system()
	var resource_core := _get_resource_core()
	var event_bus := _get_event_bus()
	if morale_system == null or resource_core == null or event_bus == null:
		_fail("MoraleSystem, ResourceCore, and EventBus autoloads must exist")
		return

	resource_core.call("reset")
	resource_core.call("add_resource", "wine", 2)

	var scene := FakeGameScene.new()
	scene.name = "FakeGameScene"
	scene.add_to_group("game_scene")
	get_root().add_child(scene)
	current_scene = scene

	var hero := Node2D.new()
	hero.name = "TestHero"
	hero.set("is_dead", false)
	hero.add_to_group("hero")
	scene.add_child(hero)
	await process_frame

	event_bus.wave_started.emit(1)
	morale_system._process(5.0)
	event_bus.wave_completed.emit(1)
	event_bus.wave_started.emit(2)
	morale_system._process(5.0)

	var remaining_wine := int(resource_core.call("get_resource", "wine"))
	if remaining_wine != 1:
		_fail("Wine consumption must accumulate across short waves; expected 1 wine remaining, got %d" % remaining_wine)
		return

	event_bus.wave_completed.emit(2)
	resource_core.call("reset")
	print("[test_morale_system_wine_consumption] PASS")
	quit(0)
