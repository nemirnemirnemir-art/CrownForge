extends Node2D
class_name MapSlot

const MapSlotProductionScript = preload("res://scripts/map_slot/MapSlotProduction.gd")
const MapSlotMarketScript = preload("res://scripts/map_slot/MapSlotMarket.gd")
const MapSlotUIScript = preload("res://scripts/map_slot/MapSlotUI.gd")
const MapSlotSealLogicScript = preload("res://scripts/map_slot/MapSlotSealLogic.gd")
const MapSlotMilitaryTrackerScript = preload("res://scripts/map_slot/MapSlotMilitaryTracker.gd")
const MapSlotAnimationsScript = preload("res://scripts/map_slot/MapSlotAnimations.gd")
const MapSlotPopupControllerScript = preload("res://scripts/map_slot/MapSlotPopupController.gd")
const MapSlotSpecialRuntimeScript = preload("res://scripts/map_slot/MapSlotSpecialRuntime.gd")
const MapSlotBuildingLifecycleScript = preload("res://scripts/map_slot/MapSlotBuildingLifecycle.gd")
const MapSlotInteractionControllerScript = preload("res://scripts/map_slot/MapSlotInteractionController.gd")
const MapSlotProductionFlowScript = preload("res://scripts/map_slot/MapSlotProductionFlow.gd")
const MapSlotSpecialFlowScript = preload("res://scripts/map_slot/MapSlotSpecialFlow.gd")
const MapSlotFeedbackFlowScript = preload("res://scripts/map_slot/MapSlotFeedbackFlow.gd")
const MapSlotActionUIFlowScript = preload("res://scripts/map_slot/MapSlotActionUIFlow.gd")
const MapSlotVzorVisualFlowScript = preload("res://scripts/map_slot/MapSlotVzorVisualFlow.gd")
const MapSlotTickRoutingScript = preload("res://scripts/map_slot/MapSlotTickRouting.gd")
const MapSlotBuildingConfigFlowScript = preload("res://scripts/map_slot/MapSlotBuildingConfigFlow.gd")
const MapSlotBootstrapScript = preload("res://scripts/map_slot/MapSlotBootstrap.gd")
const MapSlotStatusFlowScript = preload("res://scripts/map_slot/MapSlotStatusFlow.gd")
const MapSlotMiscFlowScript = preload("res://scripts/map_slot/MapSlotMiscFlow.gd")
const MapSlotSignalBridgeScript = preload("res://scripts/map_slot/MapSlotSignalBridge.gd")
const MapSlotVzorStateFlowScript = preload("res://scripts/map_slot/MapSlotVzorStateFlow.gd")
const MapSlotRecoveryFlowScript = preload("res://scripts/map_slot/MapSlotRecoveryFlow.gd")
const BasicConstructionUIScene: PackedScene = preload("res://scenes/ui/town/BasicConstructionUI.tscn")
const ResearchTableUIScene: PackedScene = preload("res://scenes/ui/town/ResearchTableUI.tscn")
const ResearchTableScript := preload("res://core/buildings/special/ResearchTable.gd")
const RewardPresentationRegistryScript := preload("res://scripts/ui/rewards/RewardPresentationRegistry.gd")
const BuildingUpgradeVisualsScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeVisuals.gd")
const UnderTexture: Texture2D = preload("res://assets/ui/buildings/under.png")

const MINE_VISUALS := {
    "iron_mine": {
        "inactive": "res://assets/environment/buildings/iron_mine.png",
        "active": "res://assets/environment/buildings/iron_mine_active.png"
    },
    "gold_mine": {
        "inactive": "res://assets/environment/buildings/gold_mine.png",
        "active": "res://assets/environment/buildings/gold_mine_active.png"
    },
    "clay_mine": {
        "inactive": "res://assets/environment/buildings/clay_mine.png",
        "active": "res://assets/environment/buildings/clay_mine_active.png"
    },
    "crystal_mine": {
        "inactive": "res://assets/environment/buildings/crystal_mine.png",
        "active": "res://assets/environment/buildings/crystal_mine_active.png"
    }
}
const MINE_ACTIVE_ROTATION_DEGREES := 10.0
const MINE_ACTIVE_SCALE_PULSE := 0.10
const MINE_ACTIVE_SHAKE_PIXELS := 3.0
const MINE_ACTIVE_ANIM_SPEED := 6.0
const DEBUG_EXTERNAL_GAZE := false
const DEBUG_DIRECT_VZOR_SPECIAL := false
const PASSIVE_SPECIAL_BUILDING_IDS := {
    "fairy_fountain": true,
}

signal slot_clicked(slot_index: int)
signal move_started(slot_index: int, building_id: String)

@export var slot_index: int = -1
@export var is_building_slot: bool = false
@export var current_seal_id: String = ""

var current_building_id: String = ""
const PRODUCTION_POPUP_SPACING := 60.0
const PRODUCTION_POPUP_VERTICAL_STEP := 8.0

var _production: MapSlotProductionScript = null
var _market: MapSlotMarketScript = null
var _ui: MapSlotUIScript = null
var _seal_logic: MapSlotSealLogic = null
var _military_tracker: MapSlotMilitaryTracker = null
var _animations: MapSlotAnimations = null
var _special_handler: RefCounted = null
var _popup_controller: RefCounted = null
var _special_runtime: RefCounted = null
var _building_lifecycle: RefCounted = null
var _interaction_controller: RefCounted = null
var _production_flow: RefCounted = null
var _special_flow: RefCounted = null
var _feedback_flow: RefCounted = null
var _action_ui_flow: RefCounted = null
var _vzor_visual_flow: RefCounted = null
var _tick_routing: RefCounted = null
var _building_config_flow: RefCounted = null
var _bootstrap: RefCounted = null
var _status_flow: RefCounted = null
var _misc_flow: RefCounted = null
var _signal_bridge: RefCounted = null
var _vzor_state_flow: RefCounted = null
var _recovery_flow: RefCounted = null

var _unit_count_label: Label = null
var _durability_label: Label = null
var _market_action_btn: Button = null
var _market_ui: Control = null
var _basic_construction_ui: Control = null
var _basic_action_btn: Button = null
var _research_table_ui: Control = null
var _research_mode_badge: Control = null

@onready var sprite = $Sprite2D
@onready var anim_vzor: AnimatedSprite2D = get_node_or_null("AnimVzor")
@onready var highlight = $Highlight
@onready var click_area: Area2D = $ClickArea
@onready var collision_shape: CollisionShape2D = get_node_or_null("ClickArea/CollisionShape2D")
@onready var progress_bar: TextureProgressBar = get_node_or_null("ProductionProgress")
@onready var radial_progress: Sprite2D = get_node_or_null("RadialProgress")
@onready var upgrade_stripe: TextureRect = get_node_or_null("UpgradeStripe")

var _default_sprite_position: Vector2 = Vector2.ZERO
var _default_sprite_scale: Vector2 = Vector2.ONE
var _default_sprite_rotation: float = 0.0
var _last_production_tick_frame: int = -1

func _hero_core() -> Node:
    return get_node_or_null("/root/HeroCore")

func _building_registry() -> Node:
    return get_node_or_null("/root/BuildingRegistry")

func _town_core() -> Node:
    return get_node_or_null("/root/TownCore")

func _building_upgrade_core() -> Node:
    return get_node_or_null("/root/BuildingUpgradeCore")

func _tick_manager() -> Node:
    return get_node_or_null("/root/TickManager")

func _save_core() -> Node:
    return get_node_or_null("/root/SaveCore")

func _ready() -> void:
    _initialize_modules()
    if _bootstrap:
        _bootstrap.setup_ui_nodes(self)
        _bootstrap.setup_market_features(self)
        _bootstrap.setup_basic_construction_features(self)
        _bootstrap.setup_research_table_features(self)
        _bootstrap.configure_click_area(self)
    _connect_hero_signals()
    _connect_upgrade_signals()
    
    if highlight:
        highlight.visible = false
        if highlight is Control:
            highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    if current_seal_id != "":
        set_seal(current_seal_id)

    if sprite:
        _default_sprite_position = sprite.position
        _default_sprite_scale = sprite.scale
        _default_sprite_rotation = sprite.rotation

    set_process(true)

func _connect_upgrade_signals() -> void:
    if _signal_bridge:
        _signal_bridge.connect_upgrade_signals(_building_upgrade_core(), Callable(self, "_on_building_upgrades_changed"))

func _on_building_upgrades_changed(changed_building_id: String, _level: int) -> void:
    if _status_flow:
        _status_flow.on_building_upgrades_changed(changed_building_id, current_building_id, Callable(self, "_update_upgrade_stripe"))

func _process(delta: float) -> void:
    _update_active_mine_animation(delta)
    _tick_effective_vzor(delta)
    _tick_external_gaze(delta)
    _tick_passive_special_building(delta)

func _initialize_modules() -> void:
    _bootstrap = MapSlotBootstrapScript.new()
    _status_flow = MapSlotStatusFlowScript.new()
    _misc_flow = MapSlotMiscFlowScript.new()
    _signal_bridge = MapSlotSignalBridgeScript.new()
    _recovery_flow = MapSlotRecoveryFlowScript.new()
    _bootstrap.initialize_modules(
        self,
        func() -> Variant: return MapSlotProductionScript.new(),
        func() -> Variant: return MapSlotMarketScript.new(),
        func() -> Variant: return MapSlotSealLogicScript.new(),
        func() -> Variant: return MapSlotMilitaryTrackerScript.new(),
        func() -> Variant: return MapSlotAnimationsScript.new(),
        [
            func() -> Variant: return MapSlotPopupControllerScript.new(),
            func() -> Variant: return MapSlotSpecialRuntimeScript.new(),
            func() -> Variant: return MapSlotBuildingLifecycleScript.new(),
            func() -> Variant: return MapSlotInteractionControllerScript.new(),
            func() -> Variant: return MapSlotProductionFlowScript.new(),
            func() -> Variant: return MapSlotSpecialFlowScript.new(),
            func() -> Variant: return MapSlotFeedbackFlowScript.new(),
            func() -> Variant: return MapSlotActionUIFlowScript.new(),
            func() -> Variant: return MapSlotVzorVisualFlowScript.new(),
            func() -> Variant: return MapSlotTickRoutingScript.new(),
            func() -> Variant: return MapSlotBuildingConfigFlowScript.new(),
        ]
    )
    _vzor_state_flow = MapSlotVzorStateFlowScript.new()
    _vzor_state_flow.initialize(_vzor_visual_flow, sprite, anim_vzor, MINE_VISUALS)

func _instantiate_market_ui() -> Node:
    var ui_scene = load("res://scenes/ui/town/MarketUI.tscn")
    if ui_scene:
        return ui_scene.instantiate()
    return null

func _setup_ui_nodes() -> void:
    if _bootstrap:
        _bootstrap.setup_ui_nodes(self)

func _setup_market_features() -> void:
    if _bootstrap:
        _bootstrap.setup_market_features(self)

func _setup_basic_construction_features() -> void:
    if _bootstrap:
        _bootstrap.setup_basic_construction_features(self)

func _setup_research_table_features() -> void:
    if _bootstrap:
        _bootstrap.setup_research_table_features(self)

func _configure_click_area() -> void:
    if _bootstrap:
        _bootstrap.configure_click_area(self)

func _connect_hero_signals() -> void:
    if _signal_bridge:
        _signal_bridge.connect_hero_signals(_hero_core(), Callable(self, "_on_hero_died"), Callable(self, "_on_hero_removed"))

func set_seal(seal_id: String) -> void:
    current_seal_id = seal_id
    _seal_logic.set_seal(seal_id)

func tick_production(delta: float) -> void:
    var current_frame := Engine.get_process_frames()
    if _last_production_tick_frame == current_frame:
        return
    _last_production_tick_frame = current_frame
    if _tick_routing == null:
        return
    var result = _tick_routing.dispatch_production_tick(
        current_building_id, _ui, _production, _market,
        _production_flow, _special_flow, _special_handler,
        _basic_construction_ui, _building_registry(), delta,
        Callable(self, "_update_durability_display"),
        Callable(self, "_handle_resource_depletion"),
        Callable(self, "_persist_special_runtime_state"),
        Callable(self, "_update_basic_construction_visuals"),
        Callable(self, "_is_research_selector_building"),
        DEBUG_DIRECT_VZOR_SPECIAL, slot_index
    )
    _debug_external_gaze_tick(delta, result)

func _tick_external_gaze(delta: float) -> void:
    if _vzor_state_flow:
        _vzor_state_flow.tick_external_gaze(delta, Callable(self, "_tick_active_building"))

func _tick_effective_vzor(delta: float) -> void:
    if _vzor_state_flow:
        _vzor_state_flow.tick_effective_vzor(
            delta, current_building_id, slot_index,
            DEBUG_DIRECT_VZOR_SPECIAL, Callable(self, "_tick_active_building")
        )

func _tick_active_building(delta: float) -> void:
    var tree := get_tree()
    if _tick_routing:
        _tick_routing.tick_active_building(
            current_building_id,
            tree != null and tree.paused,
            _tick_manager(),
            delta,
            Callable(self, "tick_production")
        )

func _tick_passive_special_building(delta: float) -> void:
    var tree := get_tree()
    if _tick_routing:
        _tick_routing.tick_passive_special_building(
            current_building_id,
            _vzor_state_flow.is_king_vzor_active() if _vzor_state_flow else false,
            _vzor_state_flow.get_external_vzor_sources() if _vzor_state_flow else {},
            PASSIVE_SPECIAL_BUILDING_IDS,
            tree != null and tree.paused,
            _tick_manager(),
            delta,
            Callable(self, "tick_production")
        )

func recover_after_encounter_pause() -> bool:
    if _recovery_flow:
        return _recovery_flow.recover_after_encounter_pause(
            current_building_id,
            _building_registry(),
            _ui,
            _production,
            _production_flow,
            anim_vzor,
            _vzor_state_flow,
            Callable(self, "_apply_mine_visual_state")
        )
    return false

func _update_durability_display() -> void:
    if _status_flow:
        _status_flow.update_durability_display(_ui, _production)

func _on_hero_died(hero_id: String) -> void:
    if _feedback_flow:
        _feedback_flow.on_hero_departed(self, _production, _military_tracker, hero_id, Callable(self, "_update_unit_label"))

func _on_hero_removed(hero_id: String) -> void:
    if _feedback_flow:
        _feedback_flow.on_hero_departed(self, _production, _military_tracker, hero_id, Callable(self, "_update_unit_label"))

func _on_production_completed(outputs: Array) -> void:
    if _feedback_flow:
        _feedback_flow.on_production_completed(_animations, outputs, PRODUCTION_POPUP_SPACING, PRODUCTION_POPUP_VERTICAL_STEP)

func _on_hero_produced(_hero_id: String) -> void:
    if _status_flow and _military_tracker:
        _status_flow.on_hero_produced(func() -> void: _military_tracker.refresh_military_unit_labels_across_map(self, _update_unit_label))

func _on_trade_completed(resource_id: String, amount: int) -> void:
    if _feedback_flow:
        _feedback_flow.on_trade_completed(_animations, resource_id, amount)

func show_resource_popup(resource_id: String, amount: int = 1, position_offset: Vector2 = Vector2.ZERO) -> void:
    if _feedback_flow:
        _feedback_flow.show_resource_popup(_animations, resource_id, amount, position_offset)

func _on_market_action_pressed() -> void:
    if _action_ui_flow:
        _action_ui_flow.on_market_action_pressed(_market_ui, _basic_construction_ui, _research_table_ui, Callable(self, "_position_popup_near_slot"), Callable(self, "_close_other_special_popups"), Callable(self, "_cancel_all_vzor_drag"), Callable(self, "_refresh_special_ui_visibility"))

func _on_trade_requested(resource_id: String) -> void:
    if _action_ui_flow:
        _action_ui_flow.on_trade_requested(resource_id, _market, _market_ui, Callable(self, "_update_market_visuals"))
    _refresh_special_ui_visibility()

func _on_basic_construction_target_requested(building_id: String) -> void:
    if _action_ui_flow:
        _action_ui_flow.on_basic_construction_target_requested(building_id, _special_handler, _basic_construction_ui, _research_table_ui, _save_core())
    _refresh_special_ui_visibility()

func _on_basic_construction_close_requested() -> void:
    _close_special_popup(_basic_construction_ui)

func _on_basic_action_pressed() -> void:
    if _action_ui_flow:
        _action_ui_flow.on_basic_action_pressed(Callable(self, "_toggle_basic_construction_ui"))

func _update_basic_construction_visuals() -> void:
    if _action_ui_flow:
        _action_ui_flow.update_basic_construction_visuals(current_building_id, _basic_action_btn, _special_handler, _basic_construction_ui)

func _update_market_visuals() -> void:
    if _action_ui_flow:
        _action_ui_flow.update_market_visuals(_market_action_btn, _market, _animations)

func _update_research_table_visuals() -> void:
    if _action_ui_flow:
        _action_ui_flow.update_research_table_visuals(current_building_id, _research_mode_badge, _special_handler, _research_table_ui)

func _refresh_special_ui_visibility() -> void:
    if _action_ui_flow == null:
        return
    _action_ui_flow.update_market_action_visibility(current_building_id, _market_action_btn, _market_ui)
    _update_basic_construction_visuals()
    _update_research_table_visuals()

func _close_other_special_popups(current_popup: Control = null) -> void:
    if _popup_controller:
        _popup_controller.close_other_special_popups(current_popup)

func _cancel_all_vzor_drag() -> void:
    if _popup_controller:
        _popup_controller.cancel_all_vzor_drag(_market_ui)

func _close_special_popup(popup: Control) -> void:
    if _popup_controller:
        _popup_controller.close_popup(popup)
    elif popup:
        popup.visible = false
    _refresh_special_ui_visibility()

func _on_research_mode_requested(mode: int) -> void:
    if _misc_flow:
        _misc_flow.on_research_mode_requested(mode, _special_handler, func() -> void: _persist_special_runtime_state(true), Callable(self, "_update_research_table_visuals"), _research_table_ui)
    _refresh_special_ui_visibility()

func replace_current_building(building_id: String) -> void:
    if _misc_flow:
        _misc_flow.replace_current_building(building_id, Callable(self, "set_building"), _save_core())

func set_vzor_active(active: bool) -> void:
    if _vzor_state_flow:
        _vzor_state_flow.set_vzor_active(active, current_building_id, _special_handler)

func set_external_vzor_active(source_id: String, active: bool) -> void:
    if _vzor_state_flow:
        _vzor_state_flow.set_external_vzor_active(source_id, active, current_building_id, _special_handler)

func is_effectively_vzor_active() -> bool:
    if _vzor_state_flow:
        return _vzor_state_flow.is_effectively_vzor_active()
    return false

func is_king_vzor_active() -> bool:
    if _vzor_state_flow:
        return _vzor_state_flow.is_king_vzor_active()
    return false

func is_external_vzor_active() -> bool:
    if _vzor_state_flow:
        return _vzor_state_flow.is_external_vzor_active()
    return false

func get_external_vzor_sources() -> Dictionary:
    if _vzor_state_flow:
        return _vzor_state_flow.get_external_vzor_sources().duplicate(true)
    return {}

func get_special_handler() -> RefCounted:
    return _special_handler

func _debug_external_gaze_tick(delta: float, result: Dictionary) -> void:
    if _vzor_state_flow:
        _vzor_state_flow.debug_external_gaze_tick(delta, result, current_building_id, slot_index, DEBUG_EXTERNAL_GAZE)

func set_building(building_id: String) -> void:
    if _building_lifecycle == null:
        return
    _building_lifecycle.set_building(self, building_id, _building_registry())

func move_building_to_slot(target_slot: Node) -> bool:
    if target_slot == null or not is_instance_valid(target_slot):
        return false
    if current_building_id == "":
        return false
    var building_id: String = current_building_id
    var production_state: Dictionary = _production.export_runtime_state() if _production and _production.has_method("export_runtime_state") else {}
    var special_state: Dictionary = _special_handler.call("get_runtime_state") if _special_handler and _special_handler.has_method("get_runtime_state") else {}
    target_slot.set_building(building_id)
    if "_production" in target_slot and target_slot._production and target_slot._production.has_method("import_runtime_state"):
        target_slot._production.import_runtime_state(production_state, int(target_slot.slot_index), building_id)
    if not special_state.is_empty() and "_special_handler" in target_slot and target_slot._special_handler and target_slot._special_handler.has_method("load_runtime_state"):
        target_slot._special_handler.load_runtime_state(special_state)
    var town_core := _town_core()
    if town_core and town_core.has_method("set_building_slot_state"):
        if not special_state.is_empty():
            town_core.set_building_slot_state(building_id, int(target_slot.slot_index), special_state, true)
        if town_core.has_method("clear_building_slot_state"):
            town_core.clear_building_slot_state(building_id, slot_index, true)
    if _building_lifecycle:
        _building_lifecycle.set_building(self, "", _building_registry(), {
            "preserve_military_units": true,
            "preserve_slot_state": true,
        })
    return true

func _clear_building(prev_building_id: String, prev_cfg: BuildingConfig, options: Dictionary = {}) -> void:
    if _building_config_flow:
        _building_config_flow.clear_building(self, prev_building_id, prev_cfg, _town_core(), options)

func _setup_building(building_id: String, prev_building_id: String, prev_cfg: BuildingConfig) -> BuildingConfig:
    var building_registry := _building_registry()
    if _building_config_flow:
        return _building_config_flow.setup_building(building_registry, building_id, prev_building_id, prev_cfg, _military_tracker, slot_index)
    return null

func _apply_building_config(config: BuildingConfig) -> void:
    if _building_config_flow:
        _building_config_flow.apply_building_config(self, config, _building_registry())

func _update_upgrade_stripe() -> void:
    if _building_config_flow:
        _building_config_flow.update_upgrade_stripe(current_building_id, upgrade_stripe, _building_upgrade_core())

func _handle_resource_depletion(config: BuildingConfig) -> void:
    if _building_config_flow:
        _building_config_flow.handle_resource_depletion(self, config, func() -> void: set_building(""))

func _apply_mine_visual_state() -> void:
    if _vzor_state_flow:
        _vzor_state_flow.apply_mine_visual_state(current_building_id)

func _is_active_mine_visual() -> bool:
    if _vzor_state_flow:
        return _vzor_state_flow.is_active_mine_visual(current_building_id)
    return false

func _reset_active_mine_transform() -> void:
    if _vzor_state_flow:
        _vzor_state_flow.reset_active_mine_transform(current_building_id)

func _update_active_mine_animation(delta: float) -> void:
    if _vzor_state_flow:
        _vzor_state_flow.update_active_mine_animation(
            delta,
            current_building_id,
            MINE_ACTIVE_ANIM_SPEED,
            MINE_ACTIVE_ROTATION_DEGREES,
            MINE_ACTIVE_SCALE_PULSE,
            MINE_ACTIVE_SHAKE_PIXELS
        )

func _update_unit_label() -> void:
    if _status_flow:
        _status_flow.update_unit_label(_ui, _military_tracker, current_building_id)

func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if Input.is_key_pressed(KEY_SHIFT) and current_building_id != "":
            move_started.emit(slot_index, current_building_id)
        else:
            _handle_click_tool()

func _handle_click_tool() -> void:
    if _interaction_controller == null:
        return
    var menu: Node = null
    var tree := get_tree()
    if tree and tree.current_scene:
        menu = tree.current_scene.get_node_or_null("UILayer/BuildingMenu")
    if menu == null and tree:
        menu = tree.get_first_node_in_group("building_menu")
    _interaction_controller.handle_click_tool(self, menu, _building_registry(), _town_core())

func _toggle_basic_construction_ui() -> void:
    if _popup_controller == null:
        return
    var viewport_rect := get_viewport().get_visible_rect() if get_viewport() else Rect2()
    _popup_controller.toggle_basic_construction_ui(
        _basic_construction_ui,
        _market_ui,
        _research_table_ui,
        _special_handler,
        global_position,
        viewport_rect,
        true
    )
    _refresh_special_ui_visibility()
    get_viewport().set_input_as_handled()

func _toggle_research_table_ui() -> void:
    if _popup_controller == null:
        return
    var viewport_rect := get_viewport().get_visible_rect() if get_viewport() else Rect2()
    _popup_controller.toggle_research_table_ui(
        _research_table_ui,
        _market_ui,
        _basic_construction_ui,
        _special_handler,
        current_building_id,
        global_position,
        viewport_rect,
        true
    )
    _refresh_special_ui_visibility()
    get_viewport().set_input_as_handled()

func _position_popup_near_slot(popup: Control, prefer_right: bool) -> void:
    if _popup_controller == null:
        return
    var viewport_rect := get_viewport().get_visible_rect() if get_viewport() else Rect2()
    _popup_controller.position_popup_near_slot(popup, global_position, viewport_rect, prefer_right)

func _is_research_selector_building() -> bool:
    return current_building_id == "research_table" or current_building_id == "research_laboratory"

func _persist_special_runtime_state(request_save: bool = false) -> void:
    if _special_runtime == null:
        return
    _special_runtime.persist_special_runtime_state(current_building_id, slot_index, _town_core(), _special_handler, request_save)

func _restore_special_runtime_state(building_id: String) -> void:
    if _special_runtime == null:
        return
    _special_runtime.restore_special_runtime_state(building_id, slot_index, _town_core(), _special_handler)

func _execute_destroy(menu: Node) -> void:
    if _interaction_controller == null:
        return
    _interaction_controller.execute_destroy(self, menu, _building_registry(), _town_core())
