extends RefCounted
class_name HeroSelectionOutline

const UnitSelectionOutlineScene: PackedScene = preload("res://scenes/ui/widgets/UnitSelectionOutline.tscn")

var _hero: Node2D = null
var _event_bus: Node = null
var _selection_outline: Node2D = null
var _selection_outline_back: CanvasItem = null
var _selection_outline_front: CanvasItem = null


func setup(hero_ref: Node2D, event_bus_ref: Node = null) -> void:
	_hero = hero_ref
	_event_bus = event_bus_ref


func setup_selection_outline() -> void:
	if _hero == null:
		return
	_selection_outline_back = _hero.get_node_or_null("SelectionOutlineBack")
	_selection_outline_front = _hero.get_node_or_null("SelectionOutlineFront")
	if _selection_outline_back != null or _selection_outline_front != null:
		if _selection_outline_back != null:
			_selection_outline_back.visible = false
		if _selection_outline_front != null:
			_selection_outline_front.visible = false
		return
	if _selection_outline != null and is_instance_valid(_selection_outline):
		return
	if UnitSelectionOutlineScene == null:
		return
	_selection_outline = UnitSelectionOutlineScene.instantiate() as Node2D
	if _selection_outline == null:
		return
	_hero.add_child(_selection_outline)
	_selection_outline.visible = false


func connect_selection_signals(callback: Callable) -> void:
	var event_bus := _resolve_event_bus()
	if event_bus == null or not event_bus.has_signal("hero_selected_for_ui"):
		return
	var target_callback := callback
	if not target_callback.is_valid():
		target_callback = Callable(self, "on_hero_selected_for_ui")
	if not event_bus.hero_selected_for_ui.is_connected(target_callback):
		event_bus.hero_selected_for_ui.connect(target_callback)


func on_hero_selected_for_ui(selected_hero_id: String) -> void:
	var should_show := (_get_current_hero_id() != "" and selected_hero_id == _get_current_hero_id())
	if _selection_outline_back != null or _selection_outline_front != null:
		if _selection_outline_back != null:
			_selection_outline_back.visible = should_show
		if _selection_outline_front != null:
			_selection_outline_front.visible = should_show
		return
	if _selection_outline == null or not is_instance_valid(_selection_outline):
		return
	_selection_outline.visible = should_show


func set_outline_flip(flip_h: bool) -> void:
	if _selection_outline_back != null and is_instance_valid(_selection_outline_back):
		_selection_outline_back.flip_h = flip_h
	if _selection_outline_front != null and is_instance_valid(_selection_outline_front):
		_selection_outline_front.flip_h = flip_h


func _get_current_hero_id() -> String:
	if _hero == null:
		return ""
	return String(_hero.get("hero_id"))


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
