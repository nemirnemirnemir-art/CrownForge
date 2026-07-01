extends Control
class_name RewardMenuTrader

const TraderOfferGeneratorScript := preload("res://scripts/ui/rewards/modules/TraderOfferGenerator.gd")
const TraderUIBuilderScript := preload("res://scripts/ui/rewards/modules/TraderUIBuilder.gd")
const TraderTransactionLogicScript := preload("res://scripts/ui/rewards/modules/TraderTransactionLogic.gd")
const TraderOfferRollerScript := preload("res://scripts/ui/rewards/modules/TraderOfferRoller.gd")

@onready var dim: CanvasItem = get_node_or_null("Dim")
@onready var continue_button: Button = get_node_or_null("Root/ContinueButton")

@onready var buildings_grid: GridContainer = get_node_or_null("Root/Content/Buildings")
@onready var artifacts_grid: GridContainer = get_node_or_null("Root/Content/Row1/Artifacts")
@onready var building_upgrades_grid: GridContainer = get_node_or_null("Root/Content/Row1/BuildingUpgrades")
@onready var resources_grid: GridContainer = get_node_or_null("Root/Content/Row2/Resources")
@onready var spells_grid: GridContainer = get_node_or_null("Root/Content/Row2/Spells")
@onready var troop_row_grid: GridContainer = get_node_or_null("Root/Content/Row3/TroopRow")

var _prev_tree_paused: bool = false

@export var building_price: int = 40
@export var artifact_price: int = 70
@export var building_upgrade_price: int = 60
@export var resource_price: int = 20
@export var spell_price: int = 30

@export var resource_amount: int = 50

var _tiles: Array = []
var _tooltip_panel: PanelContainer = null
var _tooltip_label: Label = null
var _hover_active: bool = false

var _offer_generator: TraderOfferGenerator
var _ui_builder: TraderUIBuilder
var _transaction_logic: TraderTransactionLogic
var _offer_roller: TraderOfferRoller

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    _tiles.clear()
    _tiles.append_array(_collect_tiles(buildings_grid))
    _tiles.append_array(_collect_tiles(artifacts_grid))
    _tiles.append_array(_collect_tiles(building_upgrades_grid))
    _tiles.append_array(_collect_tiles(resources_grid))
    _tiles.append_array(_collect_tiles(spells_grid))
    _tiles.append_array(_collect_tiles(troop_row_grid))

    for t in _tiles:
        if t and t.has_signal("buy_pressed"):
            t.buy_pressed.connect(_on_tile_buy_pressed)
        if t and t.has_signal("hovered"):
            t.hovered.connect(_on_tile_hovered)
        if t and t.has_signal("unhovered"):
            t.unhovered.connect(_on_tile_unhovered)

    _offer_generator = TraderOfferGeneratorScript.new()
    _ui_builder = TraderUIBuilderScript.new()
    _transaction_logic = TraderTransactionLogicScript.new()
    _offer_roller = TraderOfferRollerScript.new()
    
    _create_tooltip_panel()

    if continue_button:
        continue_button.pressed.connect(close_menu)

    if EventBus and EventBus.has_signal("gold_changed"):
        EventBus.gold_changed.connect(_on_gold_changed)

    visible = false

func _create_tooltip_panel() -> void:
    _tooltip_panel = PanelContainer.new()
    _tooltip_panel.z_index = 500
    _tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _tooltip_panel.visible = false
    add_child(_tooltip_panel)
    _tooltip_label = Label.new()
    _tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _tooltip_label.custom_minimum_size = Vector2(220, 0)
    _tooltip_label.add_theme_font_size_override("font_size", 14)
    _tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _tooltip_panel.add_child(_tooltip_label)

func _on_tile_hovered(tile: Control) -> void:
    var k := String(tile.get("kind"))
    if k == "resource" or k == "":
        _hide_tooltip()
        return
    var text := _ui_builder.build_tooltip_text(tile, ArtifactCatalog if ArtifactCatalog else null, BuildingRegistry if BuildingRegistry else null)
    if text == "":
        _hide_tooltip()
        return
    _show_tooltip(text, tile)

func _on_tile_unhovered() -> void:
    _hover_active = false
    _hide_tooltip()

func _show_tooltip(text: String, tile: Control) -> void:
    _hover_active = true
    _ui_builder.show_tooltip(_tooltip_panel, _tooltip_label, text, tile, get_viewport_rect())
    await get_tree().process_frame
    if not _hover_active:
        _hide_tooltip()
        return

func _hide_tooltip() -> void:
    if _tooltip_panel:
        _tooltip_panel.visible = false

func _collect_tiles(grid: GridContainer) -> Array:
    var out: Array = []
    if grid == null:
        return out
    for ch in grid.get_children():
        out.append(ch)
    return out

func open() -> void:
    _roll_offers()
    _update_affordability()
    visible = true
    if dim:
        dim.visible = true
    if get_tree():
        _prev_tree_paused = get_tree().paused
        get_tree().paused = true

func close_menu() -> void:
    _hide_tooltip()
    visible = false
    if get_tree():
        get_tree().paused = _prev_tree_paused

func _on_gold_changed(_new_amount: float, _delta: float) -> void:
    _update_affordability()

func _get_gold() -> int:
    return int(EconomyCore.get_gold()) if EconomyCore else 0

func _can_afford(price: int) -> bool:
    if EconomyCore == null:
        return false
    return EconomyCore.can_afford(float(price))

func _update_affordability() -> void:
    for t in _tiles:
        if t == null:
            continue
        var price := int(t.get("price"))
        var purchased := bool(t.get("purchased"))
        if t.has_method("set_affordable"):
            t.set_affordable((not purchased) and _can_afford(price))

func _roll_offers() -> void:
    if _offer_roller:
        _offer_roller.roll_offers(self, _offer_generator, _ui_builder, get_tree(), BuildingRegistry if BuildingRegistry else null, ArtifactCatalog if ArtifactCatalog else null, ArtifactCore if ArtifactCore else null, BuildingUpgradeCore if BuildingUpgradeCore else null, Callable(self, "_load_spell_config"))

func _load_spell_config(spell_id: String) -> Variant:
    var path_registry = load("res://scripts/systems/PathRegistry.gd")
    return path_registry.load_spell_config(spell_id) as SpellConfig

func _roll_buildings() -> void:
    _roll_offers()

func _roll_artifacts() -> void:
    _roll_offers()

func _roll_building_upgrades() -> void:
    if _offer_roller:
        _offer_roller.roll_building_upgrades_section(self, _offer_generator, _ui_builder, get_tree(), BuildingRegistry if BuildingRegistry else null, BuildingUpgradeCore if BuildingUpgradeCore else null)

func _roll_resources() -> void:
    _roll_offers()

func _get_resource_icon(resource_id: String) -> Texture2D:
    if resource_id == "":
        return null
    var res_map = {"wood": "wood_1", "gold": "gold_4", "clay": "clay_3", "wheat": "wheat_7", "meat": "meat_9", "iron_ore": "iron_ore_5", "ore": "iron_ore_5", "flour": "flour_8", "stone": "stone_2", "water": "water_-1", "mana": "mana_8", "steel": "iron_ingot_6", "metal": "iron_ingot_6", "crystal": "crystal"}
    var path_registry = load("res://scripts/systems/PathRegistry.gd")
    return path_registry.load_resource_icon(resource_id, res_map)

func _roll_spells() -> void:
    _roll_offers()

func _roll_troop_section() -> void:
    if _offer_roller:
        _offer_roller.roll_troop_section(self, _offer_generator, _ui_builder, get_tree(), BuildingRegistry if BuildingRegistry else null, BuildingUpgradeCore if BuildingUpgradeCore else null)

func _on_tile_buy_pressed(tile: Control) -> void:
    _transaction_logic.buy_tile(tile, EconomyCore if EconomyCore else null, get_tree(), Callable(self, "_update_affordability"), Callable(self, "_roll_building_upgrades"), Callable(self, "_roll_troop_section"), resource_amount)
