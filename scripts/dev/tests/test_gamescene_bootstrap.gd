extends SceneTree

const GameSceneBootstrapScript := preload("res://scripts/game_scene/GameSceneBootstrap.gd")


class FakeMapLayout:
	extends Node

	signal slot_connected
	var initialize_calls: int = 0
	var slots: Array = []

	func initialize_layout() -> void:
		initialize_calls += 1


class FakeSlot:
	extends Node

	signal slot_clicked(slot_index: int)
	signal move_started(slot_index: int, building_id: String)


class FakeBuildingMenu:
	extends Node

	signal building_selected(building_id: String)
	signal building_drag_started(building_id: String)


class FakeWavesManager:
	extends RefCounted

	signal wave_spawned(wave_number: int)
	signal wave_completed(wave_number: int)
	var connected_timer = null

	func connect_wave_timer(timer) -> void:
		connected_timer = timer


class FakeWaveTimerBar:
	extends Node

	var provider: Callable = Callable()

	func set_wave_interval_provider(next_provider: Callable) -> void:
		provider = next_provider


class FakeBuildingDrag:
	extends RefCounted

	var initialized_with_host = null
	var initialized_with_layout = null

	func initialize(host, map_layout) -> void:
		initialized_with_host = host
		initialized_with_layout = map_layout


class FakeSlotHover:
	extends RefCounted

	var initialized_with_scene = null

	func initialize(scene) -> void:
		initialized_with_scene = scene


class FakeWaveEnemyHUD:
	extends Control


class FakeHost:
	extends Node2D

	var map_layout_node = null
	var building_menu = null
	var _building_drag_manager = null
	var _slot_hover_manager = null
	var _wave_enemy_hud = null
	var _wave_timer_bar = null
	var map_container: Node2D = null
	var BuildingsTooltipScene = "tooltip"
	var ui_layer: CanvasLayer = null
	var spell_panel_setup_calls: int = 0
	var slot_click_calls: int = 0
	var move_start_calls: int = 0
	var building_selected_calls: int = 0
	var drag_started_calls: int = 0
	var wave_spawned_calls: int = 0
	var wave_completed_calls: int = 0
	var release_wave_interval_calls: int = 0
	var apply_runtime_map_bounds_calls: int = 0

	func _on_slot_clicked(_slot_index: int) -> void:
		slot_click_calls += 1

	func _on_building_move_started(_slot_index: int, _building_id: String) -> void:
		move_start_calls += 1

	func _on_building_selected(_building_id: String) -> void:
		building_selected_calls += 1

	func _on_building_drag_started(_building_id: String) -> void:
		drag_started_calls += 1

	func _on_wave_spawned(_wave_number: int) -> void:
		wave_spawned_calls += 1

	func _on_wave_completed(_wave_number: int) -> void:
		wave_completed_calls += 1

	func _get_release_wave_interval(_wave_number: int) -> float:
		release_wave_interval_calls += 1
		return 60.0

	func _apply_runtime_map_bounds() -> void:
		apply_runtime_map_bounds_calls += 1

	func _setup_spell_panel() -> void:
		spell_panel_setup_calls += 1

	func _get_ui_layer() -> CanvasLayer:
		return ui_layer

	func _get_map_layout_node() -> Node:
		return map_layout_node

	func _get_building_menu() -> Node:
		return building_menu


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var host := FakeHost.new()
	get_root().add_child(host)

	var ui_layer := CanvasLayer.new()
	host.add_child(ui_layer)
	host.ui_layer = ui_layer

	var timer := FakeWaveTimerBar.new()
	timer.name = "WaveTimerBar"
	ui_layer.add_child(timer)

	var map_container := Node2D.new()
	host.add_child(map_container)
	host.map_container = map_container

	var map_layout := FakeMapLayout.new()
	map_container.add_child(map_layout)
	host.map_layout_node = map_layout

	var slot := FakeSlot.new()
	map_layout.slots.append(slot)

	var building_menu := FakeBuildingMenu.new()
	ui_layer.add_child(building_menu)
	host.building_menu = building_menu

	var waves := FakeWavesManager.new()
	var bootstrap = GameSceneBootstrapScript.new()
	bootstrap.initialize(
		host,
		waves,
		func() -> void: host._setup_spell_panel(),
		func() -> Variant: return FakeBuildingDrag.new(),
		func() -> Variant: return FakeSlotHover.new(),
		func() -> Variant: return FakeWaveEnemyHUD.new()
	)

	bootstrap.run()

	if map_layout.initialize_calls != 1:
		push_error("[test_gamescene_bootstrap] map layout was not initialized")
		quit(1)
		return
	if host._building_drag_manager == null or host._slot_hover_manager == null:
		push_error("[test_gamescene_bootstrap] expected drag and hover managers to be created")
		quit(1)
		return
	if host._wave_enemy_hud == null:
		push_error("[test_gamescene_bootstrap] wave enemy hud was not attached")
		quit(1)
		return
	if host._wave_timer_bar != timer:
		push_error("[test_gamescene_bootstrap] bootstrap must own existing wave timer lookup and host assignment")
		quit(1)
		return
	if host.apply_runtime_map_bounds_calls != 1:
		push_error("[test_gamescene_bootstrap] bootstrap must apply runtime map bounds while setting up wave timer")
		quit(1)
		return
	if waves.connected_timer != timer:
		push_error("[test_gamescene_bootstrap] waves manager did not receive wave timer")
		quit(1)
		return
	if not timer.provider.is_valid():
		push_error("[test_gamescene_bootstrap] wave interval provider was not set")
		quit(1)
		return
	if host.spell_panel_setup_calls != 1:
		push_error("[test_gamescene_bootstrap] spell panel setup was not delegated")
		quit(1)
		return

	slot.slot_clicked.emit(1)
	slot.move_started.emit(1, "well")
	building_menu.building_selected.emit("well")
	building_menu.building_drag_started.emit("well")
	waves.wave_spawned.emit(1)
	waves.wave_completed.emit(1)

	if host.slot_click_calls != 1 or host.move_start_calls != 1:
		push_error("[test_gamescene_bootstrap] slot signals were not wired")
		quit(1)
		return
	if host.building_selected_calls != 1 or host.drag_started_calls != 1:
		push_error("[test_gamescene_bootstrap] building menu signals were not wired")
		quit(1)
		return
	if host.wave_spawned_calls != 1 or host.wave_completed_calls != 1:
		push_error("[test_gamescene_bootstrap] wave signals were not wired")
		quit(1)
		return

	print("[test_gamescene_bootstrap] PASS")
	quit(0)
