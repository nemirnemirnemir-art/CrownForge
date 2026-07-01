extends SceneTree

const HeroHurtboxUIScript := preload("res://scripts/hero/shared/HeroHurtboxUI.gd")


class FakeEventBus:
	extends Node
	signal hero_selected_for_ui(hero_id: String)


class FakeMainUI:
	extends Node

	var shown_for = null
	var hidden_for = null

	func _ready() -> void:
		add_to_group("main_ui")

	func show_hero_hp_tooltip(hero) -> void:
		shown_for = hero

	func hide_hero_hp_tooltip(hero) -> void:
		hidden_for = hero


class FakeHero:
	extends Node2D
	var hero_id: String = ""


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var event_bus := FakeEventBus.new()
	get_root().add_child(event_bus)

	var current_scene := Node.new()
	current_scene.name = "CurrentScene"
	get_root().add_child(current_scene)
	current_scene.get_tree().current_scene = current_scene

	var ui_layer := Node.new()
	ui_layer.name = "UILayer"
	current_scene.add_child(ui_layer)
	var main_ui := FakeMainUI.new()
	main_ui.name = "MainUI"
	ui_layer.add_child(main_ui)
	await process_frame

	var hero := FakeHero.new()
	hero.hero_id = "militia"
	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hero.add_child(hurtbox)
	current_scene.add_child(hero)

	var helper = HeroHurtboxUIScript.new()
	if helper == null:
		push_error("[test_hero_hurtbox_ui] failed to instantiate helper")
		quit(1)
		return

	var selected_ids: Array[String] = []
	event_bus.hero_selected_for_ui.connect(func(hero_id: String) -> void:
		selected_ids.append(hero_id)
	)

	helper.setup(hero, hurtbox, event_bus)
	helper.setup_hurtbox_ui_events(
		Callable(helper, "on_hurtbox_mouse_enter"),
		Callable(helper, "on_hurtbox_mouse_exit"),
		Callable(helper, "on_hurtbox_input_event")
	)

	if not hurtbox.input_pickable:
		push_error("[test_hero_hurtbox_ui] hurtbox must become input_pickable")
		quit(1)
		return

	helper.on_hurtbox_mouse_enter()
	if main_ui.shown_for != hero:
		push_error("[test_hero_hurtbox_ui] mouse enter must show hero HP tooltip")
		quit(1)
		return

	helper.on_hurtbox_mouse_exit()
	if main_ui.hidden_for != hero:
		push_error("[test_hero_hurtbox_ui] mouse exit must hide hero HP tooltip")
		quit(1)
		return

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	helper.on_hurtbox_input_event(click)
	if selected_ids != ["militia"]:
		push_error("[test_hero_hurtbox_ui] left click must emit hero selection")
		quit(1)
		return

	print("[test_hero_hurtbox_ui] PASS")
	quit(0)
