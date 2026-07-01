extends RefCounted
class_name GameSceneBootstrap

const WaveTimerScene: PackedScene = preload("res://scenes/ui/hud/WaveTimerBar.tscn")

var _host: Node = null
var _waves_manager = null
var _setup_spell_panel: Callable = Callable()
var _create_building_drag_manager: Callable = Callable()
var _create_slot_hover_manager: Callable = Callable()
var _create_process_loop_manager: Callable = Callable()
var _create_wave_enemy_hud: Callable = Callable()


func initialize(
	host: Node,
	waves_manager,
	setup_spell_panel: Callable,
	create_building_drag_manager: Callable,
	create_slot_hover_manager: Callable,
	create_wave_enemy_hud: Callable,
	create_process_loop_manager: Callable = Callable()
) -> void:
	_host = host
	_waves_manager = waves_manager
	_setup_spell_panel = setup_spell_panel
	_create_building_drag_manager = create_building_drag_manager
	_create_slot_hover_manager = create_slot_hover_manager
	_create_wave_enemy_hud = create_wave_enemy_hud
	_create_process_loop_manager = create_process_loop_manager


func run() -> void:
	setup_wave_timer_bar()
	_wire_map_layout()
	_wire_building_menu()
	_wire_wave_signals()
	_attach_wave_enemy_hud()
	_wire_process_loop()
	if _setup_spell_panel.is_valid():
		_setup_spell_panel.call()


func _wire_map_layout() -> void:
	if _host == null or not _host.has_method("_get_map_layout_node"):
		return
	var map_layout = _host.call("_get_map_layout_node")
	if map_layout == null:
		push_error("[GameSceneBootstrap] CRITICAL: MapLayout node missing")
		return
	_host.map_layout_node = map_layout
	if map_layout.has_method("initialize_layout"):
		map_layout.initialize_layout()
	if "slots" in map_layout:
		for slot in map_layout.slots:
			if not slot.slot_clicked.is_connected(Callable(_host, "_on_slot_clicked")):
				slot.slot_clicked.connect(Callable(_host, "_on_slot_clicked"))
			if slot.has_signal("move_started") and not slot.move_started.is_connected(Callable(_host, "_on_building_move_started")):
				slot.move_started.connect(Callable(_host, "_on_building_move_started"))
	if _create_building_drag_manager.is_valid():
		_host._building_drag_manager = _create_building_drag_manager.call()
		if _host._building_drag_manager and _host._building_drag_manager.has_method("initialize"):
			_host._building_drag_manager.initialize(_host, map_layout)
	if _create_slot_hover_manager.is_valid():
		_host._slot_hover_manager = _create_slot_hover_manager.call()
		if _host._slot_hover_manager and _host._slot_hover_manager.has_method("initialize"):
			_host._slot_hover_manager.initialize(_host.BuildingsTooltipScene)


func _wire_building_menu() -> void:
	if _host == null or not _host.has_method("_get_building_menu"):
		return
	var building_menu = _host.call("_get_building_menu")
	_host.building_menu = building_menu
	if building_menu == null:
		return
	if not building_menu.building_selected.is_connected(Callable(_host, "_on_building_selected")):
		building_menu.building_selected.connect(Callable(_host, "_on_building_selected"))
	if building_menu.has_signal("building_drag_started") and not building_menu.building_drag_started.is_connected(Callable(_host, "_on_building_drag_started")):
		building_menu.building_drag_started.connect(Callable(_host, "_on_building_drag_started"))


func _wire_wave_signals() -> void:
	if _waves_manager == null:
		return
	if not _waves_manager.wave_spawned.is_connected(Callable(_host, "_on_wave_spawned")):
		_waves_manager.wave_spawned.connect(Callable(_host, "_on_wave_spawned"))
	if not _waves_manager.wave_completed.is_connected(Callable(_host, "_on_wave_completed")):
		_waves_manager.wave_completed.connect(Callable(_host, "_on_wave_completed"))
	var wave_timer = _get_wave_timer_bar()
	if wave_timer and _waves_manager.has_method("connect_wave_timer"):
		_waves_manager.connect_wave_timer(wave_timer)
	if wave_timer and wave_timer.has_method("set_wave_interval_provider"):
		wave_timer.set_wave_interval_provider(Callable(_host, "_get_release_wave_interval"))


func setup_wave_timer_bar() -> void:
	if _host == null or not _host.has_method("_get_ui_layer"):
		return
	if _host.has_method("_apply_runtime_map_bounds"):
		_host.call("_apply_runtime_map_bounds")
	var ui_layer = _host.call("_get_ui_layer")
	if ui_layer == null:
		return
	var wave_timer = ui_layer.get_node_or_null("WaveTimerBar")
	if wave_timer == null and WaveTimerScene:
		wave_timer = WaveTimerScene.instantiate()
		ui_layer.add_child(wave_timer)
		wave_timer.owner = ui_layer
	_host._wave_timer_bar = wave_timer


func _get_wave_timer_bar() -> Node:
	if _host == null:
		return null
	return _host._wave_timer_bar


func _attach_wave_enemy_hud() -> void:
	if _host == null or not _host.has_method("_get_ui_layer") or not _create_wave_enemy_hud.is_valid():
		return
	var ui_layer = _host.call("_get_ui_layer")
	if ui_layer == null:
		return
	_host._wave_enemy_hud = _create_wave_enemy_hud.call()
	if _host._wave_enemy_hud:
		_host._wave_enemy_hud.name = "WaveEnemyHUD"
		ui_layer.add_child(_host._wave_enemy_hud)


func _wire_process_loop() -> void:
	if _host == null or not _create_process_loop_manager.is_valid():
		return
	_host._process_loop_manager = _create_process_loop_manager.call()
	if _host._process_loop_manager and _host._process_loop_manager.has_method("initialize"):
		_host._process_loop_manager.initialize(_host, Callable(_host, "_update_spell_targeting_process_loop"))


## Ensure a HeroPivot Node2D exists under MapContainer (or directly under game_scene
## as a fallback).  Returns the container so the caller can assign hero_container.
static func ensure_hero_container(game_scene: Node) -> Node2D:
	var map_cont: Node2D = game_scene.get_node_or_null("WorldYSort/MapContainer") as Node2D
	if map_cont and is_instance_valid(map_cont):
		var pivot: Node2D = map_cont.get_node_or_null("HeroPivot") as Node2D
		if pivot:
			return pivot
		pivot = Node2D.new()
		pivot.name = "HeroPivot"
		pivot.position = Vector2.ZERO
		map_cont.add_child(pivot)
		return pivot
	var fallback := Node2D.new()
	fallback.name = "HeroPivot"
	game_scene.add_child(fallback)
	return fallback
