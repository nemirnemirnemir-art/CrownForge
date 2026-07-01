extends RefCounted
class_name HeroHurtboxUI

var _hero: Node2D = null
var _hurtbox: Area2D = null
var _event_bus: Node = null


func setup(hero_ref: Node2D, hurtbox_ref: Area2D, event_bus_ref: Node = null) -> void:
	_hero = hero_ref
	_hurtbox = hurtbox_ref
	_event_bus = event_bus_ref


func setup_hurtbox_ui_events(mouse_enter_callback: Callable, mouse_exit_callback: Callable, input_event_callback: Callable) -> void:
	if _hurtbox == null:
		return
	_hurtbox.input_pickable = true
	if mouse_enter_callback.is_valid() and not _hurtbox.mouse_entered.is_connected(mouse_enter_callback):
		_hurtbox.mouse_entered.connect(mouse_enter_callback)
	if mouse_exit_callback.is_valid() and not _hurtbox.mouse_exited.is_connected(mouse_exit_callback):
		_hurtbox.mouse_exited.connect(mouse_exit_callback)
	if input_event_callback.is_valid() and not _hurtbox.input_event.is_connected(input_event_callback):
		_hurtbox.input_event.connect(input_event_callback)


func on_hurtbox_mouse_enter() -> void:
	var ui := _resolve_main_ui()
	if ui != null and ui.has_method("show_hero_hp_tooltip"):
		ui.show_hero_hp_tooltip(_hero)


func on_hurtbox_mouse_exit() -> void:
	var ui := _resolve_main_ui()
	if ui != null and ui.has_method("hide_hero_hp_tooltip"):
		ui.hide_hero_hp_tooltip(_hero)


func on_hurtbox_input_event(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_button := event as InputEventMouseButton
	if mouse_button.button_index != MOUSE_BUTTON_LEFT or not mouse_button.pressed:
		return
	var event_bus := _resolve_event_bus()
	var hero_id := _get_current_hero_id()
	if event_bus != null and hero_id != "" and event_bus.has_signal("hero_selected_for_ui"):
		event_bus.hero_selected_for_ui.emit(hero_id)


func _resolve_main_ui() -> Node:
	if _hero == null:
		return null
	var tree := _hero.get_tree()
	if tree == null:
		return null
	if tree.current_scene != null:
		var current_scene_ui := tree.current_scene.get_node_or_null("UILayer/MainUI")
		if current_scene_ui != null:
			return current_scene_ui
	return tree.get_first_node_in_group("main_ui")


func _resolve_event_bus() -> Node:
	if _event_bus != null:
		return _event_bus
	if _hero == null:
		return null
	var tree := _hero.get_tree()
	if tree == null or tree.root == null:
		return null
	var direct_node := tree.root.get_node_or_null("EventBus")
	if direct_node != null:
		return direct_node
	return tree.root.get_node_or_null("/root/EventBus")


func _get_current_hero_id() -> String:
	if _hero == null:
		return ""
	return String(_hero.get("hero_id"))
