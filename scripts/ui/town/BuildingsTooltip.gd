extends PanelContainer
class_name BuildingsTooltip

const ResourceAmountRowScene: PackedScene = preload("res://scenes/ui/town/ResourceAmountRow.tscn")
const UnitInfoPanelScene: PackedScene = preload("res://scenes/ui/town/UnitInfoPanel.tscn")
const UpgradeItemPanelScene: PackedScene = preload("res://scenes/ui/town/UpgradeItemPanel.tscn")
const BuildingUpgradeDataScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeData.gd")
const BuildingsTooltipContentScript := preload("res://scripts/ui/town/buildings/BuildingsTooltipContent.gd")
const BuildingsTooltipExtrasScript := preload("res://scripts/ui/town/buildings/BuildingsTooltipExtras.gd")
const BuildingsTooltipDataProviderScript := preload("res://scripts/ui/town/buildings/BuildingsTooltipDataProvider.gd")
const BuildingsTooltipIconResolverScript := preload("res://scripts/ui/town/buildings/BuildingsTooltipIconResolver.gd")
const BuildingsTooltipRendererScript := preload("res://scripts/ui/town/buildings/BuildingsTooltipRenderer.gd")

const RESOURCE_DISPLAY_ORDER := [
	"water", "gold", "wood", "clay", "iron_ore", "steel", "wheat", "flour", "meat", "grapes", "wine", "oil", "crystal",
]

@export var tooltip_width: float = 360.0
@export var resource_icon_size: float = 42.0
@export var show_extras: bool = true

const TITLE_COLOR := Color(1.0, 0.9, 0.7, 1.0)
const BODY_COLOR := Color(0.8, 0.8, 0.8, 1.0)
const BODY_OUTLINE_COLOR := Color(0.05, 0.05, 0.05, 1.0)

@onready var _name_label: Label = $Margin/VBox/NameLabel
@onready var _timer_label: Label = $Margin/VBox/ProductionInfo/TimerLabel
@onready var _timer_icon: Label = $Margin/VBox/ProductionInfo/TimerIcon

@onready var _input_list: HBoxContainer = $Margin/VBox/ProductionItems/InputList
@onready var _output_list: HBoxContainer = $Margin/VBox/ProductionItems/OutputList
@onready var _arrow_icon: Label = $Margin/VBox/ProductionItems/ArrowIcon

@onready var _description_label: Label = $Margin/VBox/DescriptionText
@onready var _cost_header: Label = $Margin/VBox/CostHeader
@onready var _next_cost_box: VBoxContainer = $Margin/VBox/NextCostList

@onready var _capacity_icon: Control = $Margin/VBox/ProductionInfo/CapacityIcon
@onready var _capacity_label: Label = $Margin/VBox/ProductionInfo/CapacityLabel
@onready var _prod_row: HBoxContainer = $Margin/VBox/ProductionRow
@onready var _prod_row_icon: Control = $Margin/VBox/ProductionRow/Icon
@onready var _prod_row_content: HBoxContainer = $Margin/VBox/ProductionRow/Content
@onready var _cons_row: HBoxContainer = $Margin/VBox/ConsumptionRow
@onready var _cons_row_icon: Control = $Margin/VBox/ConsumptionRow/Icon
@onready var _cons_row_content: HBoxContainer = $Margin/VBox/ConsumptionRow/Content

var _building_id: String = ""

var _extras_parent: CanvasItem = null
var _unit_panel_popup: UnitInfoPanel = null
var _upgrade_popups: Array[UpgradeItemPanel] = []
var _content_helper: BuildingsTooltipContent = BuildingsTooltipContentScript.new()
var _extras_helper: BuildingsTooltipExtras = BuildingsTooltipExtrasScript.new()
var _data_provider: BuildingsTooltipDataProvider
var _icon_resolver: BuildingsTooltipIconResolver
var _renderer: BuildingsTooltipRenderer

func _building_registry() -> Node:
	return get_node_or_null("/root/BuildingRegistry")

func _seal_registry() -> Node:
	return get_node_or_null("/root/SealRegistry")

func _resource_core() -> Node:
	return get_node_or_null("/root/ResourceCore")

func _economy_core() -> Node:
	return get_node_or_null("/root/EconomyCore")

func _event_bus() -> Node:
	return get_node_or_null("/root/EventBus")

func _ready() -> void:
	_data_provider = BuildingsTooltipDataProviderScript.new()
	_icon_resolver = BuildingsTooltipIconResolverScript.new()
	_renderer = BuildingsTooltipRendererScript.new()

	visibility_changed.connect(_on_visibility_changed)

	var resource_core := _resource_core()
	if resource_core and not resource_core.resource_changed.is_connected(_on_resource_changed):
		resource_core.resource_changed.connect(_on_resource_changed)
	var event_bus := _event_bus()
	if event_bus and event_bus.has_signal("gold_changed") and not event_bus.gold_changed.is_connected(_on_gold_changed):
		event_bus.gold_changed.connect(_on_gold_changed)

	tooltip_width = 240.0
	resource_icon_size = 28.0
	_renderer.resource_icon_size = resource_icon_size

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size_flags_horizontal = 0
	size_flags_vertical = 0

	_setup_icon_fallbacks()

func _setup_icon_fallbacks() -> void:
	var cap_path := _icon_resolver.resolve_ui_icon_path("capacity_icon")
	if cap_path != "" and _capacity_icon is TextureRect:
		(_capacity_icon as TextureRect).texture = load(cap_path)
	elif cap_path == "":
		_capacity_icon = _renderer.setup_icon_fallback(_capacity_icon, "⚑", TITLE_COLOR)

	var prod_path := _icon_resolver.resolve_ui_icon_path("green_arrow_up")
	if prod_path != "" and _prod_row_icon is TextureRect:
		(_prod_row_icon as TextureRect).texture = load(prod_path)
	elif prod_path == "":
		_prod_row_icon = _renderer.setup_icon_fallback(_prod_row_icon, "↑", Color.GREEN)

	var cons_path := _icon_resolver.resolve_ui_icon_path("red_arrow_down")
	if cons_path != "" and _cons_row_icon is TextureRect:
		(_cons_row_icon as TextureRect).texture = load(cons_path)
	elif cons_path == "":
		_cons_row_icon = _renderer.setup_icon_fallback(_cons_row_icon, "↓", Color.RED)

func _process(_delta: float) -> void:
	_extras_helper.process(self)

func _on_visibility_changed() -> void:
	_extras_helper.handle_visibility_changed(self)

func setup(building_id: String) -> void:
	_data_provider.initialize(_building_registry(), _seal_registry(), _resource_core())
	_content_helper.setup_building(self, building_id)

func show_building(building_id: String) -> void:
	setup(building_id)

func setup_for_trade(trade: Dictionary) -> void:
	_content_helper.setup_trade(self, trade)

func _setup_for_seal(config: SealConfig) -> void:
	_content_helper.setup_seal(self, config)

func _fit_to_content() -> void:
	custom_minimum_size = Vector2(tooltip_width, 0)
	size = Vector2.ZERO
	reset_size()
	await get_tree().process_frame
	var target_size := get_combined_minimum_size()
	target_size.x = min(target_size.x, tooltip_width)
	target_size.y = min(target_size.y, 500.0)
	size = target_size

func _rebuild_extras(config: BuildingConfig) -> void:
	_extras_helper.rebuild_extras(self, config)

func _clear_extras() -> void:
	_extras_helper.clear_extras(self)

func _resolve_extras_parent() -> CanvasItem:
	return _extras_helper.resolve_extras_parent(self)

func _position_extras() -> void:
	_extras_helper.position_extras(self)

func _update_production_display(config: BuildingConfig) -> void:
	_renderer.update_production_display(_output_list, _arrow_icon, _prod_row, _prod_row_icon, config)

func _update_consumption_display(config: BuildingConfig) -> void:
	_renderer.update_consumption_display(_input_list, _arrow_icon, _cons_row, _cons_row_icon, config)

func _update_costs_display(config: BuildingConfig) -> void:
	var building_registry := _building_registry()
	var next_cost: Dictionary = {}
	if building_registry:
		next_cost = building_registry.get_next_build_cost(config.building_id)
	if next_cost.is_empty():
		for cost in config.build_costs:
			if cost:
				next_cost[cost.resource_id] = cost.amount
	var markup_percent: int = 0
	if building_registry and building_registry.has_method("get_next_build_markup_percent"):
		markup_percent = int(building_registry.get_next_build_markup_percent(config.building_id))
	var sorted_ids := next_cost.keys()
	sorted_ids.sort_custom(_sort_resource_ids)
	_renderer.rebuild_cost_rows(_next_cost_box, sorted_ids, next_cost, self, resource_icon_size)
	_cost_header.visible = sorted_ids.size() > 0
	if markup_percent > 0:
		_cost_header.text = "Price:\nNext build will cost +%d%%" % markup_percent
	else:
		_cost_header.text = "Price:"

func _update_cost_row(row: ResourceAmountRow, res_id: String, required: int) -> void:
	var owned := _get_owned_amount(res_id)
	_renderer.update_cost_row(row, res_id, required, owned, resource_icon_size)

func _add_cost_row(res_id: String, required: int) -> void:
	var owned := _get_owned_amount(res_id)
	_renderer.add_cost_row(_next_cost_box, res_id, required, owned)

func _add_unit_to_list(container: Control, unit_id: String, amount: int) -> void:
	_renderer.add_unit_to_list(container, unit_id, amount)

func _add_resource_to_hbox(container: Control, res_id: String, amount: int) -> void:
	_renderer.add_resource_to_hbox(container, res_id, amount)

func _show_capacity(capacity: int) -> void:
	_capacity_label.text = "/ %d" % capacity
	_capacity_label.show()
	_capacity_icon.show()

func _get_clean_description(desc: String) -> String:
	return _data_provider.get_clean_description(desc)

func _clear_container(container: Control) -> void:
	_renderer.clear_container(container)

func _sort_resource_ids(a: Variant, b: Variant) -> bool:
	var aa := str(a)
	var bb := str(b)
	var ia := RESOURCE_DISPLAY_ORDER.find(aa)
	var ib := RESOURCE_DISPLAY_ORDER.find(bb)
	if ia == -1 and ib == -1: return aa < bb
	if ia == -1: return false
	if ib == -1: return true
	return ia < ib

func _update_seal_costs(config: SealConfig) -> void:
	_renderer.clear_container(_next_cost_box)
	if config.cost.size() > 0:
		var sorted_keys := config.cost.keys()
		sorted_keys.sort()
		var resource_core := _resource_core()
		for res in sorted_keys:
			var owned := _get_owned_amount(str(res))
			_renderer.add_cost_row(_next_cost_box, res, config.cost[res], owned)
		_cost_header.show()
	else:
		_cost_header.hide()

func _on_resource_changed(_res_id: String, _amount: int) -> void:
	_content_helper.refresh_costs_for_current_target(self)


func _on_gold_changed(_new_amount: float, _delta: float) -> void:
	_content_helper.refresh_costs_for_current_target(self)


func _get_owned_amount(res_id: String) -> int:
	if res_id == "gold":
		var economy_core := _economy_core()
		if economy_core != null and economy_core.has_method("get_gold"):
			return int(economy_core.get_gold())
		return 0
	var resource_core := _resource_core()
	if resource_core and resource_core.has_method("get_resource"):
		return int(resource_core.get_resource(res_id))
	return 0
