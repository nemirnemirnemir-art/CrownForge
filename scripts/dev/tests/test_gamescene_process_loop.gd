extends SceneTree

const GameSceneProcessLoopScript := preload("res://scripts/game_scene/GameSceneProcessLoop.gd")


class FakePauseState:
	extends RefCounted

	var paused: bool = false
	var calls: int = 0

	func is_effectively_paused() -> bool:
		calls += 1
		return paused


class FakeBuildingDrag:
	extends RefCounted

	var has_ghost_value: bool = false
	var has_ghost_calls: int = 0
	var update_calls: int = 0

	func has_ghost() -> bool:
		has_ghost_calls += 1
		return has_ghost_value

	func update_ghost_position() -> void:
		update_calls += 1


class FakeSlotHover:
	extends RefCounted

	var paused_calls: int = 0
	var active_calls: int = 0
	var last_host = null
	var last_map_layout = null
	var last_delta: float = -1.0

	func update_paused(host, map_layout) -> void:
		paused_calls += 1
		last_host = host
		last_map_layout = map_layout

	func update(host, map_layout, delta: float) -> void:
		active_calls += 1
		last_host = host
		last_map_layout = map_layout
		last_delta = delta


class FakeHeroesManager:
	extends RefCounted

	var cleanup_calls: int = 0

	func check_dead_heroes_cleanup() -> void:
		cleanup_calls += 1


class FakeHost:
	extends Node

	var _spell_targeting_active: bool = false
	var _pause_state_manager = null
	var _building_drag_manager = null
	var _slot_hover_manager = null
	var _heroes_manager = null
	var map_layout_node = null
	var spell_update_calls: int = 0

	func _update_spell_targeting_process_loop() -> void:
		spell_update_calls += 1


func _init() -> void:
	call_deferred("_run_test")


func _assert_true(value: bool, message: String) -> bool:
	if value:
		return true
	push_error("[test_gamescene_process_loop] %s" % message)
	quit(1)
	return false


func _run_test() -> void:
	var helper = GameSceneProcessLoopScript.new()
	if not _assert_true(helper != null, "helper must instantiate"):
		return

	var host := FakeHost.new()
	host.map_layout_node = Node.new()
	host._pause_state_manager = FakePauseState.new()
	host._building_drag_manager = FakeBuildingDrag.new()
	host._slot_hover_manager = FakeSlotHover.new()
	host._heroes_manager = FakeHeroesManager.new()

	helper.initialize(host, Callable(host, "_update_spell_targeting_process_loop"))

	host._spell_targeting_active = true
	host._pause_state_manager.paused = true
	host._building_drag_manager.has_ghost_value = true
	helper.tick(0.25)
	if not _assert_true(host.spell_update_calls == 1, "spell targeting must update while paused"):
		return
	if not _assert_true(host._building_drag_manager.update_calls == 1, "paused drag ghost must update exactly once"):
		return
	if not _assert_true(host._slot_hover_manager.paused_calls == 1, "paused slot hover must update exactly once"):
		return
	if not _assert_true(host._slot_hover_manager.active_calls == 0, "paused loop must not run active slot hover"):
		return
	if not _assert_true(host._heroes_manager.cleanup_calls == 0, "paused loop must skip hero cleanup"):
		return

	host._spell_targeting_active = false
	host._pause_state_manager.paused = false
	host._building_drag_manager.has_ghost_value = true
	helper.tick(0.5)
	if not _assert_true(host._heroes_manager.cleanup_calls == 1, "unpaused loop must run hero cleanup once"):
		return
	if not _assert_true(host._building_drag_manager.update_calls == 2, "active drag ghost must still update exactly once"):
		return
	if not _assert_true(host._slot_hover_manager.active_calls == 0, "dragging must suppress active slot hover"):
		return
	if not _assert_true(host._slot_hover_manager.paused_calls == 1, "unpaused loop must not re-run paused slot hover"):
		return

	host._building_drag_manager.has_ghost_value = false
	helper.tick(0.75)
	if not _assert_true(host._heroes_manager.cleanup_calls == 2, "each unpaused tick must run hero cleanup once"):
		return
	if not _assert_true(host._building_drag_manager.update_calls == 2, "no ghost means no drag update"):
		return
	if not _assert_true(host._slot_hover_manager.active_calls == 1, "active slot hover must update exactly once when idle"):
		return
	if not _assert_true(absf(host._slot_hover_manager.last_delta - 0.75) < 0.001, "active slot hover must receive current delta"):
		return
	if not _assert_true(host._slot_hover_manager.last_host == host, "slot hover must receive the host instance"):
		return
	if not _assert_true(host._slot_hover_manager.last_map_layout == host.map_layout_node, "slot hover must receive the host map layout"):
		return

	print("[test_gamescene_process_loop] PASS")
	quit(0)
