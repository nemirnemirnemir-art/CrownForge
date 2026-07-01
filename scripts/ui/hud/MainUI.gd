extends Control

const MainUITooltipsScript := preload("res://scripts/ui/hud/MainUITooltips.gd")
const MainUIButtonFlowScript := preload("res://scripts/ui/hud/MainUIButtonFlow.gd")
const MainUISignalFlowScript := preload("res://scripts/ui/hud/MainUISignalFlow.gd")
const MainUIResourceBarResolverScript := preload("res://scripts/ui/hud/MainUIResourceBarResolver.gd")
const MainUIResourceBindingFlowScript := preload("res://scripts/ui/hud/MainUIResourceBindingFlow.gd")
const MainUIResourceDisplayFlowScript := preload("res://scripts/ui/hud/MainUIResourceDisplayFlow.gd")
const MainUIOverlayFlowScript := preload("res://scripts/ui/hud/MainUIOverlayFlow.gd")
const MainUIPopupLayerBridgeScript := preload("res://scripts/ui/hud/MainUIPopupLayerBridge.gd")
const MainUIOverlayTargetBridgeScript := preload("res://scripts/ui/hud/MainUIOverlayTargetBridge.gd")
const MainUIHirePanelBootstrapFlowScript := preload("res://scripts/ui/hud/MainUIHirePanelBootstrapFlow.gd")
const MainUIStartupDisplayFlowScript := preload("res://scripts/ui/hud/MainUIStartupDisplayFlow.gd")
const MainUITooltipProcessFlowScript := preload("res://scripts/ui/hud/MainUITooltipProcessFlow.gd")
const MainUITooltipFacadeBridgeScript := preload("res://scripts/ui/hud/MainUITooltipFacadeBridge.gd")
const MainUIPerksPanelFlowScript := preload("res://scripts/ui/hud/MainUIPerksPanelFlow.gd")
const MainUIDisplayEventFlowScript := preload("res://scripts/ui/hud/MainUIDisplayEventFlow.gd")
const MainUIGameOverFlowScript := preload("res://scripts/ui/hud/MainUIGameOverFlow.gd")
const MainUIActionFlowScript := preload("res://scripts/ui/hud/MainUIActionFlow.gd")
const MainUITroopBonusScript := preload("res://scripts/main_ui/MainUITroopBonus.gd")
const MainUITownOverlaysScript := preload("res://scripts/main_ui/MainUITownOverlays.gd")
const MainUIHeroHireScript := preload("res://scripts/main_ui/MainUIHeroHire.gd")

const GameOverPanelScene = preload("res://scenes/ui/overlays/GameOverPanel.tscn")

const RESOURCE_DISPLAY_ORDER := [
    "water", "wheat", "wood", "clay", "iron_ore", "crystal",
    "grapes", "wine", "gold", "steel", "flour", "meat", "oil",
]

const _DEBUG_INGREDIENTS := [
    {"id": "ingredient_hollow_bottle", "icon": "res://assets/items/ingredients/hollow_bottle.png"},
    {"id": "ingredient_bat_wing", "icon": "res://assets/items/ingredients/bat_wing.png"},
    {"id": "ingredient_slime_goo", "icon": "res://assets/items/ingredients/slime_goo.png"},
    {"id": "ingredient_mushroom_cap", "icon": "res://assets/items/ingredients/mushroom_cap.png"},
    {"id": "ingredient_wood_scrap", "icon": "res://assets/items/ingredients/wood_scrap.png"},
    {"id": "ingredient_sword", "icon": "res://assets/items/ingredients/crypt/sword_ing.png"},
    {"id": "ingredient_axe", "icon": "res://assets/items/ingredients/crypt/axe_ing.png"},
    {"id": "ingredient_bone", "icon": "res://assets/items/ingredients/crypt/bone_ing.png"},
    {"id": "ingredient_bug", "icon": "res://assets/items/ingredients/crypt/backpack_ing.png"},
    {"id": "ingredient_crown", "icon": "res://assets/items/ingredients/crypt/crown_ing.png"},
    {"id": "ingredient_purple_fire", "icon": "res://assets/items/ingredients/crypt/purple_ing.png"},
    {"id": "ingredient_drake_scale", "icon": "res://assets/items/ingredients/drake_scale.png"},
    {"id": "ingredient_lizard_tail", "icon": "res://assets/items/ingredients/lizard_tail.png"},
]
const _DEBUG_INGREDIENT_QTY: int = 50

@onready var test_gold_button: Button = $VBoxContainer/ButtonsGrid/TestGoldButton
@onready var reset_dialog: AcceptDialog = $ResetDialog
@onready var prestige_button: Button = $VBoxContainer/PrestigeButton
@onready var inventory_bar: InventoryBar = $InventoryBar
@onready var perks_test_panel: PerksTestPanel = $PerksTestPanel
@onready var popup_layer: Control = get_node_or_null("PopupLayer") as Control
@onready var resource_bar_unified: PanelContainer = get_node_or_null("ResourceBarUnified") as PanelContainer
@onready var resource_bar_hbox: HBoxContainer = null

@onready var hire_prev_button: TextureButton = $HirePanel/UpgradePanel/ScrollContainer/HireMenu/HireNav/HirePrevButton
@onready var hire_next_button: TextureButton = $HirePanel/UpgradePanel/ScrollContainer/HireMenu/HireNav/HireNextButton

var resource_labels: Dictionary = {}

var _tooltips: MainUITooltips
var _troop_bonus: MainUITroopBonus = null
var _town_overlays: MainUITownOverlays = null
var _hero_hire: MainUIHeroHire = null
var _game_over_instance: GameOverPanel = null
var _button_flow = null
var _signal_flow = null
var _resource_bar_resolver = null
var _resource_binding_flow = null
var _resource_display_flow = null
var _overlay_flow = null
var _popup_layer_bridge = null
var _overlay_target_bridge = null
var _hire_panel_bootstrap_flow = null
var _startup_display_flow = null
var _tooltip_process_flow = null
var _tooltip_facade_bridge = null
var _perks_panel_flow = null
var _display_event_flow = null
var _game_over_flow = null
var _action_flow = null

func _ready() -> void:
    add_to_group("main_ui")
    
    _initialize_modules()
    _connect_signals()
    _connect_buttons()
    _initialize_resource_labels()
    
    if _hire_panel_bootstrap_flow and has_node("HirePanel"):
        _hire_panel_bootstrap_flow.apply_initial_state($HirePanel)
    _update_all_display()

func _initialize_modules() -> void:
    _resource_bar_resolver = MainUIResourceBarResolverScript.new()
    if _resource_bar_resolver:
        var resolved_resource_bar: Dictionary = _resource_bar_resolver.resolve_resource_bar(resource_bar_unified, self)
        resource_bar_unified = resolved_resource_bar.get("resource_bar_unified", resource_bar_unified)
        resource_bar_hbox = resolved_resource_bar.get("resource_bar_hbox", null)
    _tooltips = MainUITooltipsScript.new()
    _button_flow = MainUIButtonFlowScript.new()
    _signal_flow = MainUISignalFlowScript.new()
    _resource_binding_flow = MainUIResourceBindingFlowScript.new()
    _resource_display_flow = MainUIResourceDisplayFlowScript.new()
    _overlay_flow = MainUIOverlayFlowScript.new()
    _popup_layer_bridge = MainUIPopupLayerBridgeScript.new()
    _overlay_target_bridge = MainUIOverlayTargetBridgeScript.new()
    _hire_panel_bootstrap_flow = MainUIHirePanelBootstrapFlowScript.new()
    _startup_display_flow = MainUIStartupDisplayFlowScript.new()
    _tooltip_process_flow = MainUITooltipProcessFlowScript.new()
    _tooltip_facade_bridge = MainUITooltipFacadeBridgeScript.new()
    _perks_panel_flow = MainUIPerksPanelFlowScript.new()
    _display_event_flow = MainUIDisplayEventFlowScript.new()
    _game_over_flow = MainUIGameOverFlowScript.new()
    _action_flow = MainUIActionFlowScript.new()
    _tooltips.initialize(self, get_popup_layer())
    
    _troop_bonus = MainUITroopBonusScript.new()
    _troop_bonus.initialize(self, get_popup_layer(), resource_bar_hbox)
    
    _town_overlays = MainUITownOverlaysScript.new()
    _town_overlays.initialize(self, _on_overlay_visibility_changed)
    
    _hero_hire = MainUIHeroHireScript.new()
    _hero_hire.initialize(self, hire_prev_button, hire_next_button)
    _hero_hire.fix_next_button_visual()
    _hero_hire.setup_hero_list()

func get_popup_layer() -> Control:
    if _popup_layer_bridge:
        return _popup_layer_bridge.get_popup_host(popup_layer, self)
    return popup_layer if popup_layer else self

func add_popup(node: Node) -> void:
    if _popup_layer_bridge:
        _popup_layer_bridge.add_popup(popup_layer, self, node)
        return
    if node == null:
        return
    get_popup_layer().add_child(node)

func _process(_delta: float) -> void:
    if _tooltip_process_flow:
        _tooltip_process_flow.process_tooltips(_tooltips)
        return
    if _tooltips:
        _tooltips.process()

func _unhandled_input(_event: InputEvent) -> void:
    pass

func _connect_signals() -> void:
    if _signal_flow:
        _signal_flow.connect_signals(
            EventBus,
            ResourceCore,
            CastleCore,
            reset_dialog,
            {
                "gold_changed": Callable(self, "_on_gold_changed"),
                "stars_changed": Callable(self, "_on_stars_changed"),
                "stage_changed": Callable(self, "_on_stage_changed"),
                "game_loaded": Callable(self, "_update_all_display"),
                "forge_cores_changed": Callable(self, "_on_forge_cores_changed"),
                "resource_changed": Callable(self, "_on_resource_changed"),
                "game_over": Callable(self, "_on_game_over"),
                "reset_confirmed": Callable(self, "_on_reset_dialog_confirmed"),
            }
        )

func _connect_buttons() -> void:
    var mine_btn = $VBoxContainer/ButtonsGrid/MineButton
    var grid = $VBoxContainer/ButtonsGrid
    var forge_city_btn = $CityButtons/ForgeCityButton
    var inventory_city_btn = $CityButtons/InventoryCityButton
    var alchemy_city_btn = $CityButtons/AlchemyCityButton
    if _button_flow:
        _button_flow.connect_buttons(
            test_gold_button,
            mine_btn,
            grid,
            forge_city_btn,
            inventory_city_btn,
            alchemy_city_btn,
            {
                "test_gold": Callable(_action_flow, "run_debug_grant").bind(EconomyCore, TownCore, _DEBUG_INGREDIENTS, _DEBUG_INGREDIENT_QTY),
                "mine": Callable(),
                "perks": Callable(_perks_panel_flow, "open_perks_panel").bind(perks_test_panel),
                "forge": Callable(self, "_on_city_forge_button_pressed"),
                "inventory": Callable(self, "_on_city_inventory_button_pressed"),
                "alchemy": Callable(self, "_on_city_alchemy_button_pressed"),
            }
        )

func _initialize_resource_labels() -> void:
    resource_labels.clear()
    if _resource_binding_flow:
        resource_labels = _resource_binding_flow.collect_resource_labels(resource_bar_hbox, RESOURCE_DISPLAY_ORDER)

func _set_resource_label(resource_id: String, value: Variant) -> void:
    if _resource_display_flow:
        _resource_display_flow.set_resource_label(resource_labels, resource_id, value)

func _update_all_display() -> void:
    if _startup_display_flow:
        _startup_display_flow.update_all_display(Callable(self, "_refresh_all_resources"), _hero_hire)
        return
    _refresh_all_resources()
    if _hero_hire:
        _hero_hire.update_hero_costs()

func _refresh_all_resources() -> void:
    if not resource_labels:
        _initialize_resource_labels()
    if _resource_display_flow:
        _resource_display_flow.refresh_all_resources(resource_labels, RESOURCE_DISPLAY_ORDER, EconomyCore, ResourceCore)

func _on_gold_changed(new_amount: float, _delta: float) -> void:
    if _display_event_flow:
        _display_event_flow.on_gold_changed(new_amount, Callable(self, "_set_resource_label"), _hero_hire)
        return
    _set_resource_label("gold", int(new_amount))
    if _hero_hire:
        _hero_hire.update_hero_costs()

func _on_stars_changed(_new_amount: int) -> void:
    pass

func _on_stage_changed(_new_stage: int) -> void:
    if _display_event_flow:
        _display_event_flow.on_stage_changed(Callable(self, "_refresh_all_resources"), _hero_hire)
        return
    _refresh_all_resources()
    if _hero_hire:
        _hero_hire.update_hero_costs()

func _on_resource_changed(resource_id: String, amount: int) -> void:
    if _display_event_flow:
        _display_event_flow.on_resource_changed(resource_id, amount, Callable(self, "_set_resource_label"))
        return
    _set_resource_label(resource_id, amount)

func _on_reset_dialog_confirmed() -> void:
    pass

func _on_forge_cores_changed(_new_amount: int, _delta: int) -> void:
    pass

func _on_city_forge_button_pressed() -> void:
    if _action_flow:
        _action_flow.open_smith(_town_overlays)

func _on_city_inventory_button_pressed() -> void:
    if _action_flow:
        _action_flow.open_inventory(_town_overlays)

func _on_city_alchemy_button_pressed() -> void:
    if _action_flow:
        _action_flow.open_alchemy(_town_overlays)

func _on_overlay_visibility_changed() -> void:
    if _overlay_target_bridge:
        _overlay_target_bridge.apply_overlay_visibility(get_tree(), _overlay_flow, _town_overlays)

func _on_game_over() -> void:
    if _game_over_flow:
        _game_over_instance = _game_over_flow.open_game_over_panel(
            _game_over_instance,
            Callable(GameOverPanelScene, "instantiate"),
            self,
            Callable(self, "_on_restart_pressed")
        )

func _on_restart_pressed() -> void:
    if _action_flow:
        _action_flow.restart_game(CastleCore)

func show_hero_hp_tooltip(hero: Node) -> void:
    if _tooltip_facade_bridge:
        _tooltip_facade_bridge.show_hero_hp_tooltip(_tooltips, hero)
        return
    if _tooltips:
        _tooltips.show_hero_hp_tooltip(hero)

func hide_hero_hp_tooltip(hero: Node) -> void:
    if _tooltip_facade_bridge:
        _tooltip_facade_bridge.hide_hero_hp_tooltip(_tooltips, hero)
        return
    if _tooltips:
        _tooltips.hide_hero_hp_tooltip(hero)

func show_enemy_hp_tooltip(mob: Node) -> void:
    if _tooltip_facade_bridge:
        _tooltip_facade_bridge.show_enemy_hp_tooltip(_tooltips, mob)
        return
    if _tooltips:
        _tooltips.show_enemy_hp_tooltip(mob)

func hide_enemy_hp_tooltip(mob: Node) -> void:
    if _tooltip_facade_bridge:
        _tooltip_facade_bridge.hide_enemy_hp_tooltip(_tooltips, mob)
        return
    if _tooltips:
        _tooltips.hide_enemy_hp_tooltip(mob)
