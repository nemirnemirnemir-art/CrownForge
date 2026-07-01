extends RefCounted
class_name GameSceneEncounterFlow

var _host: Node = null
var _waves_manager = null
var _pause_state_manager = null
var _encounter_menu: Control = null
var _encounter_service = null
var _reward_menus: Array[Control] = []
var _is_pause_after_prophecy_enabled: Callable = Callable()
var _run_ui_action: Callable = Callable()
var _recover_production: Callable = Callable()
var _pending_encounter_ui_actions: Array[String] = []
var _pending_prophecy_encounter: Dictionary = {}
var _waves_paused_before_encounter: bool = false
var _encounter_active: bool = false


func _get_tick_manager() -> Node:
	var tree: SceneTree = null
	if _host != null and _host.get_tree() != null:
		tree = _host.get_tree()
	else:
		var main_loop := Engine.get_main_loop()
		if main_loop is SceneTree:
			tree = main_loop
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TickManager")


func _debug_log(context: String, extra: Dictionary = {}) -> void:
	var waves_paused: Variant = null
	if _waves_manager and _waves_manager.has_method("is_paused"):
		waves_paused = _waves_manager.is_paused()
	print("[EncounterFlow][DEBUG] %s | encounter_active=%s paused_before_encounter=%s waves_paused=%s reward_menu_visible=%s pending_actions=%s extra=%s" % [
		context,
		str(_encounter_active),
		str(_waves_paused_before_encounter),
		str(waves_paused),
		str(is_any_encounter_reward_menu_visible()),
		str(_pending_encounter_ui_actions),
		str(extra),
	])


func _resolve_desired_wave_pause_state() -> bool:
	if _host != null:
		var host_value: Variant = _host.get("waves_paused")
		if host_value != null:
			return bool(host_value)
	if _waves_manager and _waves_manager.has_method("is_paused"):
		return bool(_waves_manager.is_paused())
	return false


func initialize(
	host: Node,
	waves_manager,
	pause_state_manager,
	encounter_menu: Control,
	encounter_service,
	reward_menus: Array[Control],
	is_pause_after_prophecy_enabled: Callable,
	run_ui_action: Callable,
	recover_production: Callable
) -> void:
	_host = host
	_waves_manager = waves_manager
	_pause_state_manager = pause_state_manager
	_encounter_menu = encounter_menu
	_encounter_service = encounter_service
	_reward_menus = reward_menus
	_is_pause_after_prophecy_enabled = is_pause_after_prophecy_enabled
	_run_ui_action = run_ui_action
	_recover_production = recover_production


func on_prophecy_confirmed(selected_waves: Array) -> bool:
	_debug_log("on_prophecy_confirmed:enter", {"selected_count": selected_waves.size()})
	if _waves_manager and _waves_manager.has_method("set_prophecy_queue"):
		_waves_manager.set_prophecy_queue(selected_waves)

	if _has_active_reward_chain():
		_pending_prophecy_encounter = _build_prophecy_encounter_payload()
		if _pause_state_manager and _pause_state_manager.has_method("release_prophecy_pause"):
			_pause_state_manager.release_prophecy_pause()
		_debug_log("on_prophecy_confirmed:deferred_until_rewards", {"pending_encounter": _pending_prophecy_encounter})
		return false

	if try_open_encounter_after_prophecy():
		_debug_log("on_prophecy_confirmed:encounter_opened")
		return true

	if _pause_state_manager and _pause_state_manager.has_method("release_prophecy_pause"):
		_pause_state_manager.release_prophecy_pause()
	if _waves_manager and _waves_manager.has_method("set_paused"):
		_waves_manager.set_paused(false)
	_debug_log("on_prophecy_confirmed:no_encounter_resume")
	return false


func try_open_encounter_after_prophecy() -> bool:
	_debug_log("try_open_encounter_after_prophecy:enter")
	if _encounter_menu == null or _encounter_service == null:
		_debug_log("try_open_encounter_after_prophecy:no_menu_or_service")
		return false
	if _encounter_menu.visible:
		_debug_log("try_open_encounter_after_prophecy:already_visible")
		return false

	var encounter: Dictionary = _build_prophecy_encounter_payload()
	if encounter.is_empty():
		_debug_log("try_open_encounter_after_prophecy:empty_encounter")
		return false

	if _is_pause_after_prophecy_enabled.is_valid() and bool(_is_pause_after_prophecy_enabled.call()):
		if _pause_state_manager and _pause_state_manager.has_method("transfer_prophecy_pause_to_encounter"):
			_pause_state_manager.transfer_prophecy_pause_to_encounter()
	elif _pause_state_manager and _pause_state_manager.has_method("release_prophecy_pause"):
		_pause_state_manager.release_prophecy_pause()

	_waves_paused_before_encounter = _resolve_desired_wave_pause_state()
	if _waves_manager and _waves_manager.has_method("set_paused"):
		_waves_manager.set_paused(true)
	_encounter_active = true
	_debug_log("try_open_encounter_after_prophecy:open", {"encounter": encounter})
	_encounter_menu.open(encounter)
	_pending_prophecy_encounter.clear()
	return true


func on_encounter_option_selected(encounter_id: String, option_id: String) -> bool:
	_debug_log("on_encounter_option_selected:enter", {"encounter_id": encounter_id, "option_id": option_id})
	if _encounter_service == null:
		return false
	var applied: bool = _encounter_service.apply_encounter_option(encounter_id, option_id)
	if not applied:
		_debug_log("on_encounter_option_selected:not_applied")
		return false

	if _encounter_service.has_method("consume_pending_ui_actions"):
		var actions: Array = _encounter_service.consume_pending_ui_actions()
		_debug_log("on_encounter_option_selected:actions_consumed", {"actions": actions})
		execute_encounter_ui_actions(actions)
	return true


func execute_encounter_ui_actions(actions: Array) -> void:
	_debug_log("execute_encounter_ui_actions:enter", {"actions": actions})
	for raw_action in actions:
		var action_id := String(raw_action).strip_edges()
		if action_id == "":
			continue
		_pending_encounter_ui_actions.append(action_id)
	if not _encounter_active and not is_any_encounter_reward_menu_visible():
		_debug_log("execute_encounter_ui_actions:open_next_now")
		open_next_encounter_ui_action()


func bind_reward_menus(reward_menus: Array[Control], visibility_changed_callback: Callable) -> void:
	_reward_menus = reward_menus
	for menu in _reward_menus:
		if menu == null:
			continue
		if visibility_changed_callback.is_valid() and not menu.visibility_changed.is_connected(visibility_changed_callback):
			menu.visibility_changed.connect(visibility_changed_callback)


func on_reward_menu_visibility_changed() -> void:
	_debug_log("on_reward_menu_visibility_changed:enter")
	if not _pending_prophecy_encounter.is_empty() and not _encounter_active and not _has_active_reward_chain() and not is_any_encounter_reward_menu_visible() and _encounter_menu != null and not _encounter_menu.visible:
		_debug_log("on_reward_menu_visibility_changed:open_deferred_prophecy_encounter", {"encounter": _pending_prophecy_encounter})
		_open_encounter_payload(_pending_prophecy_encounter)
		return
	if is_any_encounter_reward_menu_visible():
		_debug_log("on_reward_menu_visibility_changed:still_visible")
		return
	if _encounter_active:
		_debug_log("on_reward_menu_visibility_changed:encounter_still_active")
		return
	if _pending_encounter_ui_actions.is_empty():
		_debug_log("on_reward_menu_visibility_changed:no_pending")
		return
	_debug_log("on_reward_menu_visibility_changed:open_next")
	open_next_encounter_ui_action()


func is_any_encounter_reward_menu_visible() -> bool:
	for menu in _reward_menus:
		if menu != null and menu.visible:
			return true
	return false


func open_next_encounter_ui_action() -> void:
	_debug_log("open_next_encounter_ui_action:enter")
	while not _pending_encounter_ui_actions.is_empty():
		var action_id := String(_pending_encounter_ui_actions.pop_front())
		_debug_log("open_next_encounter_ui_action:run", {"action_id": action_id})
		if run_encounter_ui_action(action_id):
			_debug_log("open_next_encounter_ui_action:opened_modal", {"action_id": action_id})
			return
	_debug_log("open_next_encounter_ui_action:done")


func run_encounter_ui_action(action_id: String) -> bool:
	if _run_ui_action.is_valid():
		return bool(_run_ui_action.call(action_id))
	return false


func on_encounter_closed() -> void:
	_debug_log("on_encounter_closed:enter")
	_encounter_active = false
	if _pause_state_manager and _pause_state_manager.has_method("release_encounter_pause"):
		_pause_state_manager.release_encounter_pause()
	if _pause_state_manager and _pause_state_manager.has_method("release_prophecy_pause"):
		_pause_state_manager.release_prophecy_pause()

	# Safety: if game is still paused after both release calls, force-clear
	# This handles edge cases where _encounter_pause_applied was never set
	if _pause_state_manager and _pause_state_manager.has_method("is_effectively_paused"):
		if bool(_pause_state_manager.is_effectively_paused()):
			var prophecy_still_applied: bool = _pause_state_manager.has_method("is_prophecy_pause_applied") and bool(_pause_state_manager.is_prophecy_pause_applied())
			if not prophecy_still_applied:
				print("[EncounterFlow] SAFETY: game still paused after both releases — force-clearing")
				if _host and _host.get_tree():
					_host.get_tree().paused = false
				var tick_manager := _get_tick_manager()
				if tick_manager != null and tick_manager.has_method("set_speed"):
					tick_manager.set_speed(1.0)

	# Reset vzor hover state to flush stale GUI hover from closed encounter panel
	if _host and _host.get_tree():
		for vzor_zone in _host.get_tree().get_nodes_in_group("vzor_zone"):
			if vzor_zone.has_method("reset_drag_hover_state"):
				vzor_zone.reset_drag_hover_state()

	if _waves_manager and _waves_manager.has_method("set_paused"):
		_waves_manager.set_paused(_waves_paused_before_encounter)

	if _recover_production.is_valid():
		_recover_production.call()
	if not is_any_encounter_reward_menu_visible() and not _pending_encounter_ui_actions.is_empty():
		_debug_log("on_encounter_closed:open_next_after_close")
		open_next_encounter_ui_action()
	_debug_log("on_encounter_closed:done")


func _has_active_reward_chain() -> bool:
	if _host != null and _host.has_method("has_active_reward_chain"):
		return bool(_host.has_active_reward_chain())
	return false


func _build_prophecy_encounter_payload() -> Dictionary:
	if _encounter_service == null:
		return {}
	return _encounter_service.build_random_encounter()


func _open_encounter_payload(encounter: Dictionary) -> bool:
	if encounter.is_empty():
		return false
	if _is_pause_after_prophecy_enabled.is_valid() and bool(_is_pause_after_prophecy_enabled.call()):
		if _pause_state_manager and _pause_state_manager.has_method("apply_encounter_pause"):
			_pause_state_manager.apply_encounter_pause()
	elif _pause_state_manager and _pause_state_manager.has_method("release_prophecy_pause"):
		_pause_state_manager.release_prophecy_pause()
	_waves_paused_before_encounter = _resolve_desired_wave_pause_state()
	if _waves_manager and _waves_manager.has_method("set_paused"):
		_waves_manager.set_paused(true)
	_encounter_active = true
	_debug_log("_open_encounter_payload:open", {"encounter": encounter})
	_encounter_menu.open(encounter)
	_pending_prophecy_encounter.clear()
	return true
