extends PanelContainer
class_name BuildingDetailsPanel

const ResourceAmountRowScene: PackedScene = preload("res://scenes/ui/town/ResourceAmountRow.tscn")
const UnitInfoPanelScene: PackedScene = preload("res://scenes/ui/town/UnitInfoPanel.tscn")
const UpgradeItemPanelScene: PackedScene = preload("res://scenes/ui/town/UpgradeItemPanel.tscn")
const BuildingPresentationDataScript := preload("res://scripts/ui/town/buildings/BuildingPresentationData.gd")
const BuildingUpgradeVisualsScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeVisuals.gd")
const BuildingUpgradeIconResolverScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeIconResolver.gd")
const UnitFaceLibraryScript := preload("res://scripts/utils/UnitFaceLibrary.gd")

const RESOURCE_DISPLAY_ORDER := [
    "water", "gold", "wood", "clay", "iron_ore", "steel", "wheat", "flour", "meat", "grapes", "wine", "oil", "crystal",
]

@onready var _name_label: Label = $Margin/VBox/NameLabel
@onready var _timer_label: Label = $Margin/VBox/BuildingStats/TimerInfo/TimerLabel
@onready var _capacity_label: Label = $Margin/VBox/BuildingStats/CapacityInfo/CapacityLabel
@onready var _capacity_info: HBoxContainer = $Margin/VBox/BuildingStats/CapacityInfo

@onready var _provides_box: VBoxContainer = $Margin/VBox/ProvidesList
@onready var _description_label: Label = $Margin/VBox/DescriptionText
@onready var _next_cost_box: VBoxContainer = $Margin/VBox/NextCostList
@onready var _requirements_box: VBoxContainer = $Margin/VBox/RequirementsList
@onready var _cost_label: Label = $Margin/VBox/CostLabel
@onready var _upgrades_header: Label = $Margin/VBox/UpgradesHeader
@onready var _upgrades_container: VBoxContainer = $Margin/VBox/UpgradesList

## Unit info container (added dynamically)
var _unit_info_panel: UnitInfoPanel = null

var _building_id: String = ""

func _building_registry() -> Node:
    return get_node_or_null("/root/BuildingRegistry")

func _resource_core() -> Node:
    return get_node_or_null("/root/ResourceCore")

func _economy_core() -> Node:
    return get_node_or_null("/root/EconomyCore")

func show_building(building_id: String) -> void:
    _building_id = building_id
    var config: BuildingConfig = null
    var building_registry := _building_registry()
    if building_registry:
        config = building_registry.get_building(building_id)
    
    if not config:
        _name_label.text = building_id
        _description_label.text = "Config not found"
        _capacity_info.hide()
        return

    # 1. Building Name
    _name_label.text = config.display_name

    # 2. Stats (Timer & Capacity)
    _timer_label.text = "%.2fs" % config.cycle_time
    
    if config.building_type == BuildingConfig.BuildingType.MILITARY:
        _capacity_label.text = "/ %d" % config.max_units
        _capacity_info.show()
    else:
        _capacity_info.hide()

    # 3. Description
    _description_label.text = BuildingPresentationDataScript.get_description(config.building_id, config.description)
    _description_label.show()

    # 4. Production/Provides
    _rebuild_provides_list(config)

    # 5. Costs
    var next_cost: Dictionary = {}
    if building_registry:
        next_cost = building_registry.get_next_build_cost(building_id)
    _rebuild_list(_next_cost_box, next_cost, false)
    _rebuild_list(_requirements_box, next_cost, true)

    if _cost_label:
        var markup_percent: int = 0
        if building_registry and building_registry.has_method("get_next_build_markup_percent"):
            markup_percent = int(building_registry.get_next_build_markup_percent(building_id))
        if markup_percent > 0:
            _cost_label.text = "BUILD COST:\nNext build will cost +%d%%" % markup_percent
        else:
            _cost_label.text = "BUILD COST:"
    
    # 6. Unit Info Panel (for military buildings)
    _rebuild_unit_info_panel(config)
    
    # 7. Upgrades Panel
    _rebuild_upgrades_panel(config)

func _rebuild_provides_list(config: BuildingConfig) -> void:
    if not _provides_box: return
    
    for c in _provides_box.get_children():
        c.queue_free()
        
    if config.building_type == BuildingConfig.BuildingType.MILITARY:
        _add_unit_to_provides(config.produced_unit_id, 1)
    else:
        for prod in config.produces:
            if prod:
                _add_resource_row(_provides_box, prod.resource_id, prod.amount, -1)
    
    if _provides_box.get_child_count() == 0:
        var lbl := Label.new()
        lbl.text = "None"
        lbl.add_theme_font_size_override("font_size", 14)
        _provides_box.add_child(lbl)

func _add_unit_to_provides(unit_id: String, amount: int) -> void:
    var row = HBoxContainer.new()
    _provides_box.add_child(row)
    
    var icon = TextureRect.new()
    icon.custom_minimum_size = Vector2(32, 32)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    
    var display_name := unit_id.replace("_", " ")
    icon.texture = UnitFaceLibraryScript.get_face_texture(unit_id, display_name)
    if icon.texture != null:
        icon.modulate = Color(1, 1, 1, 1)
    else:
        icon.modulate = Color(0.5, 0.5, 0.5, 1.0)
    row.add_child(icon)
    
    var label = Label.new()
    label.text = " Produces: %s (%d)" % [unit_id.capitalize(), amount]
    label.add_theme_font_size_override("font_size", 16)
    row.add_child(label)

func _rebuild_list(target: VBoxContainer, resources: Dictionary, show_owned: bool) -> void:
    if not target: return

    for c in target.get_children():
        c.queue_free()

    if resources.is_empty():
        var lbl := Label.new()
        lbl.text = "Free"
        lbl.add_theme_font_size_override("font_size", 14)
        target.add_child(lbl)
        return

    var keys := resources.keys()
    keys.sort_custom(_sort_resource_ids)

    for res_id in keys:
        var amount = resources[res_id]
        _add_resource_row(target, res_id, amount, show_owned)

func _add_resource_row(target: VBoxContainer, res_id: String, amount: int, show_owned: bool) -> void:
    var row = ResourceAmountRowScene.instantiate()
    var owned := -1
    if show_owned:
        owned = _get_owned_amount(res_id)
    
    target.add_child(row)
    if row and row.has_method("setup"):
        row.setup(res_id, amount, owned)

func _get_owned_amount(res_id: String) -> int:
    if res_id == "gold":
        var economy_core := _economy_core()
        if economy_core and economy_core.has_method("get_gold"):
            return int(economy_core.get_gold())
        return 0
    var resource_core := _resource_core()
    if resource_core and resource_core.has_method("get_resource"):
        return int(resource_core.get_resource(res_id))
    return 0

func _sort_resource_ids(a: Variant, b: Variant) -> bool:
    var aa := str(a)
    var bb := str(b)
    var ia := RESOURCE_DISPLAY_ORDER.find(aa)
    var ib := RESOURCE_DISPLAY_ORDER.find(bb)
    if ia == -1 and ib == -1: return aa < bb
    if ia == -1: return false
    if ib == -1: return true
    return ia < ib

func _rebuild_unit_info_panel(config: BuildingConfig) -> void:
    # Remove existing unit info panel
    if _unit_info_panel:
        _unit_info_panel.queue_free()
        _unit_info_panel = null
    
    # Only for military buildings
    if config.building_type != BuildingConfig.BuildingType.MILITARY:
        return
    
    if config.produced_unit_id.is_empty():
        return
    
    # Create new unit info panel
    _unit_info_panel = UnitInfoPanelScene.instantiate() as UnitInfoPanel
    if _unit_info_panel:
        var vbox = $Margin/VBox
        if vbox:
            vbox.add_child(_unit_info_panel)
            _unit_info_panel.setup(config.produced_unit_id)

func _rebuild_upgrades_panel(config: BuildingConfig) -> void:
    if _upgrades_container == null:
        return

    for child in _upgrades_container.get_children():
        child.queue_free()

    var upgrades: Array = BuildingPresentationDataScript.get_upgrades(config.building_id)
    if upgrades.is_empty():
        if _upgrades_header:
            _upgrades_header.hide()
        _upgrades_container.hide()
        return

    if _upgrades_header:
        _upgrades_header.show()
    _upgrades_container.show()

    for upgrade_index in range(upgrades.size()):
        var upgrade_data = upgrades[upgrade_index]
        var upgrade_panel = UpgradeItemPanelScene.instantiate() as UpgradeItemPanel
        if upgrade_panel == null:
            continue

        _upgrades_container.add_child(upgrade_panel)
        upgrade_panel.setup(
            String(upgrade_data.get("name", "")),
            String(upgrade_data.get("desc", "")),
            BuildingUpgradeIconResolverScript.get_icon(config.building_id, upgrade_index),
            BuildingUpgradeVisualsScript.get_upgrade_color(config.building_id, upgrade_index)
        )
