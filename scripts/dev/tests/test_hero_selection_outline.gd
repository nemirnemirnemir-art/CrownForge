extends SceneTree

const HeroSelectionOutlineScript := preload("res://scripts/hero/shared/HeroSelectionOutline.gd")


class FakeEventBus:
	extends Node
	signal hero_selected_for_ui(hero_id: String)


class FakeHero:
	extends Node2D
	var hero_id: String = ""


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var event_bus := FakeEventBus.new()
	get_root().add_child(event_bus)

	var hero := FakeHero.new()
	hero.hero_id = "peasant"
	var outline_back := Node2D.new()
	outline_back.name = "SelectionOutlineBack"
	outline_back.visible = true
	hero.add_child(outline_back)
	var outline_front := Node2D.new()
	outline_front.name = "SelectionOutlineFront"
	outline_front.visible = true
	hero.add_child(outline_front)
	get_root().add_child(hero)

	var helper = HeroSelectionOutlineScript.new()
	if helper == null:
		push_error("[test_hero_selection_outline] failed to instantiate helper")
		quit(1)
		return

	helper.setup(hero, event_bus)
	helper.setup_selection_outline()
	helper.connect_selection_signals(Callable(helper, "on_hero_selected_for_ui"))

	if outline_back.visible or outline_front.visible:
		push_error("[test_hero_selection_outline] scene-authored outlines must be hidden during setup")
		quit(1)
		return

	event_bus.hero_selected_for_ui.emit("peasant")
	if not outline_back.visible or not outline_front.visible:
		push_error("[test_hero_selection_outline] outlines did not become visible for selected hero")
		quit(1)
		return

	event_bus.hero_selected_for_ui.emit("other")
	if outline_back.visible or outline_front.visible:
		push_error("[test_hero_selection_outline] outlines stayed visible for different hero")
		quit(1)
		return

	print("[test_hero_selection_outline] PASS")
	quit(0)
