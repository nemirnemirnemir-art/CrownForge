extends SceneTree

const VisualsScript := preload("res://scripts/hero/modules/HeroOnFieldVisuals.gd")

class FakeEventBus:
	extends Node
	signal hero_selected_for_ui(hero_id: String)

class FakeHero:
	extends Node2D
	var hero_id: String = ""

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var hero := FakeHero.new()
	hero.hero_id = "peasant"
	var outline := Node2D.new()
	outline.name = "SelectionOutlineBack"
	outline.visible = false
	hero.add_child(outline)
	get_root().add_child(hero)

	var visuals := VisualsScript.new() as HeroOnFieldVisuals
	if visuals == null:
		push_error("[test_hero_on_field_selection_outline_signal] failed to instantiate visuals")
		quit(1)
		return

	visuals.setup(hero, "peasant")
	await process_frame
	visuals._on_hero_selected_for_ui("peasant")

	if not outline.visible:
		push_error("[test_hero_on_field_selection_outline_signal] outline did not become visible for selected hero")
		quit(1)
		return

	visuals._on_hero_selected_for_ui("other")
	if outline.visible:
		push_error("[test_hero_on_field_selection_outline_signal] outline stayed visible for different hero")
		quit(1)
		return

	print("[test_hero_on_field_selection_outline_signal] PASS")
	quit(0)
