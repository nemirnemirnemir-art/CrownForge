extends RefCounted
class_name GameSceneProcessLoop

var _host: Node = null
var _update_spell_targeting: Callable = Callable()


func initialize(host: Node, update_spell_targeting: Callable) -> void:
	_host = host
	_update_spell_targeting = update_spell_targeting


func tick(delta: float) -> void:
	if _host == null:
		return

	if _host._spell_targeting_active and _update_spell_targeting.is_valid():
		_update_spell_targeting.call()

	var is_paused_now: bool = false
	var pause_state_manager = _host._pause_state_manager
	if pause_state_manager:
		is_paused_now = bool(pause_state_manager.is_effectively_paused())

	var building_drag_manager = _host._building_drag_manager
	var slot_hover_manager = _host._slot_hover_manager
	if is_paused_now:
		if building_drag_manager and building_drag_manager.has_ghost():
			building_drag_manager.update_ghost_position()
		if slot_hover_manager:
			slot_hover_manager.update_paused(_host, _host.map_layout_node)
		return

	var heroes_manager = _host._heroes_manager
	if heroes_manager:
		heroes_manager.check_dead_heroes_cleanup()

	if building_drag_manager and building_drag_manager.has_ghost():
		building_drag_manager.update_ghost_position()
	elif slot_hover_manager:
		slot_hover_manager.update(_host, _host.map_layout_node, delta)
