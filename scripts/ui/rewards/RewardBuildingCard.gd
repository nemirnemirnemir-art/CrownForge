extends Panel
class_name RewardBuildingCard

signal selected(building_id: String)
signal excluded(building_id: String)

const ResourceAmountRowScene: PackedScene = preload("res://scenes/ui/town/ResourceAmountRow.tscn")
const UnitInfoPanelScene: PackedScene = preload("res://scenes/ui/town/UnitInfoPanel.tscn")
const BuildingPresentationDataScript := preload("res://scripts/ui/town/buildings/BuildingPresentationData.gd")

const CARD_RESOURCE_ICON_SIZE := 40.0
const CARD_RESOURCE_FONT_SIZE := 27
const RESOURCE_BUILDING_ICON_SCALE := 1.50
const BUDDHIST_TEMPLE_ICON_SCALE := 1.30

@onready var icon_rect: TextureRect = get_node_or_null("Icon")
@onready var name_label: Label = get_node_or_null("NameLabel")
@onready var info_button: Button = get_node_or_null("InfoButton")
@onready var cycle_label: Label = get_node_or_null("CycleLabel")
@onready var capacity_label: Label = get_node_or_null("CapacityLabel")
@onready var prod_box: HBoxContainer = get_node_or_null("UnitAndResourcesRow/UnitResources/ProdBox")
@onready var cons_box: HBoxContainer = get_node_or_null("UnitAndResourcesRow/UnitResources/ConsBox")
@onready var hero_portrait: HeroPortrait = get_node_or_null("UnitAndResourcesRow/HeroPortrait") as HeroPortrait
@onready var description_label: Label = get_node_or_null("DescriptionLabel")
@onready var cost_title_label: Label = get_node_or_null("CostTitle")
@onready var cost_box: Container = get_node_or_null("CostBox")
@onready var choose_button: Button = get_node_or_null("ChooseButton")
@onready var exclude_button: Button = get_node_or_null("ExcludeButton")
@onready var exclude_popup: Control = get_node_or_null("ExcludePopup")
@onready var exclude_popup_remaining: Label = get_node_or_null("ExcludePopup/VBox/RemainingLabel")

var building_id: String = ""
var _portrait_unit_id: String = ""
var _unit_tooltip: UnitInfoPanel = null

func _ready() -> void:
    if choose_button:
        choose_button.pressed.connect(_on_choose_pressed)
    if exclude_button:
        exclude_button.pressed.connect(_on_exclude_pressed)
        exclude_button.mouse_entered.connect(_on_exclude_hover_entered)
        exclude_button.mouse_exited.connect(_on_exclude_hover_exited)
        exclude_button.focus_mode = Control.FOCUS_NONE
    if info_button:
        info_button.disabled = true
        info_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if exclude_popup:
        exclude_popup.visible = false

    if hero_portrait:
        hero_portrait.mouse_entered.connect(_on_portrait_hover_entered)
        hero_portrait.mouse_exited.connect(_on_portrait_hover_exited)

func setup(new_building_id: String) -> void:
    building_id = new_building_id
    var config: BuildingConfig = null
    if BuildingRegistry:
        config = BuildingRegistry.get_building(building_id)
    if not config:
        if icon_rect:
            icon_rect.texture = null
        if name_label:
            name_label.text = building_id
        if cycle_label:
            cycle_label.text = ""
        if capacity_label:
            capacity_label.visible = false
        if hero_portrait:
            hero_portrait.visible = false
        if description_label:
            description_label.text = ""
        if prod_box:
            _clear_container(prod_box)
        if cons_box:
            _clear_container(cons_box)
        if cost_box:
            _clear_container(cost_box)
        if choose_button:
            choose_button.disabled = true
        return

    if choose_button:
        choose_button.disabled = false

    if icon_rect:
        icon_rect.texture = config.get_icon_or_placeholder()
        icon_rect.pivot_offset = icon_rect.size * 0.5
        icon_rect.scale = Vector2.ONE * _get_building_icon_scale(config)
    if name_label:
        name_label.text = config.display_name if config.display_name != "" else config.building_id

    if cycle_label:
        cycle_label.text = "%.2fs" % config.cycle_time

    if capacity_label:
        if config.max_units > 0:
            capacity_label.visible = true
            capacity_label.text = "/ %d" % int(config.max_units)
        else:
            capacity_label.visible = false

    _set_portrait(config)
    _set_description(config)
    _rebuild_prod_cons(config)
    _rebuild_costs(config)

func _get_building_icon_scale(config: BuildingConfig) -> float:
    if config and config.building_type == BuildingConfig.BuildingType.RESOURCE:
        return RESOURCE_BUILDING_ICON_SCALE
    if building_id == "buddhist_temple":
        return BUDDHIST_TEMPLE_ICON_SCALE
    return 1.0

func _set_portrait(config: BuildingConfig) -> void:
    if not hero_portrait:
        return
    if not config:
        hero_portrait.visible = false
        _portrait_unit_id = ""
        return
    var unit_id := String(config.produced_unit_id).strip_edges()
    if unit_id == "":
        hero_portrait.visible = false
        _portrait_unit_id = ""
        return
    hero_portrait.visible = true
    hero_portrait.set_unit_portrait(unit_id)
    _portrait_unit_id = unit_id

func set_exclude_remaining(left: int) -> void:
    if exclude_popup_remaining:
        exclude_popup_remaining.text = "EXCLUDES LEFT: %d" % left

func _set_description(config: BuildingConfig) -> void:
    if not description_label:
        return
    var desc := BuildingPresentationDataScript.get_description(config.building_id, String(config.description).strip_edges())
    if desc == "" or desc.begins_with("TODO"):
        desc = _build_auto_description(config)
    description_label.text = _sanitize_description(desc)

func _title_case_unit(unit_id: String) -> String:
    var words := unit_id.replace("_", " ").split(" ", false)
    for i in range(words.size()):
        var w := String(words[i])
        if w.length() == 0:
            continue
        words[i] = w[0].to_upper() + w.substr(1, w.length() - 1)
    return " ".join(words)

func _sanitize_description(desc: String) -> String:
    var out := desc
    var rx_per := RegEx.new()
    if rx_per.compile("(?i)\\s*per\\s*[0-9]+(?:\\.[0-9]+)?\\s*(?:s|sec|secs|seconds)?\\s*cycle\\.?\\s*") == OK:
        out = rx_per.sub(out, " ", true)
    var rx_cap := RegEx.new()
    if rx_cap.compile("(?i)\\s*capacity\\s*:?\\s*[0-9]+\\.?\\s*" ) == OK:
        out = rx_cap.sub(out, " ", true)
    var rx_cons := RegEx.new()
    if rx_cons.compile("(?i)\\s*consumes\\b[^.]*\\.?\\s*") == OK:
        out = rx_cons.sub(out, " ", true)
    while out.find("  ") != -1:
        out = out.replace("  ", " ")
    out = out.strip_edges()
    if out.ends_with(".") and out.length() > 1:
        out = out.rstrip(".").strip_edges() + "."
    return out

func _build_auto_description(config: BuildingConfig) -> String:
    var produced := ""
    if config and config.produces.size() > 0 and config.produces[0]:
        produced = String(config.produces[0].resource_id)
    var map_en := {
        "water": "Water",
        "wheat": "Wheat",
        "wood": "Wood",
        "grapes": "Grapes",
        "gold": "Gold",
        "ore": "Ore",
        "clay": "Clay",
        "crystal": "Crystals",
    }
    var name_en: String = map_en.get(produced, produced)
    if name_en == "":
        return ""
    return "Produces %s." % name_en

func _rebuild_prod_cons(config: BuildingConfig) -> void:
    if prod_box:
        _clear_container(prod_box)
        if config and config.building_type == BuildingConfig.BuildingType.RESOURCE:
            prod_box.alignment = BoxContainer.ALIGNMENT_CENTER
        else:
            prod_box.alignment = BoxContainer.ALIGNMENT_BEGIN
        for prod in config.produces:
            if prod == null:
                continue
            var row := ResourceAmountRowScene.instantiate() as Control
            prod_box.add_child(row)
            if row.has_method("setup"):
                row.setup(prod.resource_id, prod.amount)
            var icon_size := CARD_RESOURCE_ICON_SIZE
            if config and config.building_type == BuildingConfig.BuildingType.RESOURCE:
                icon_size = CARD_RESOURCE_ICON_SIZE * 1.5
            _tune_card_resource_row(row, icon_size)

    if cons_box:
        _clear_container(cons_box)
        cons_box.alignment = BoxContainer.ALIGNMENT_BEGIN
        for cons in config.consumes:
            if cons == null:
                continue
            var row2 := ResourceAmountRowScene.instantiate() as Control
            cons_box.add_child(row2)
            if row2.has_method("setup"):
                row2.setup(cons.resource_id, cons.amount)
            _tune_card_resource_row(row2)

func _rebuild_costs(config: BuildingConfig) -> void:
    if not cost_box:
        return
    _clear_container(cost_box)
    var next_cost: Dictionary = {}
    if BuildingRegistry:
        next_cost = BuildingRegistry.get_next_build_cost(config.building_id)
    if next_cost.is_empty():
        for cost in config.build_costs:
            if cost == null:
                continue
            next_cost[String(cost.resource_id)] = int(cost.amount)

    var sorted_ids := next_cost.keys()
    sorted_ids.sort()
    for res_id in sorted_ids:
        var res_key: String = str(res_id)
        var required: int = int(next_cost[res_key])
        var owned := ResourceCore.get_resource(res_key) if ResourceCore else -1
        var row := ResourceAmountRowScene.instantiate() as Control
        cost_box.add_child(row)
        if row.has_method("setup"):
            row.setup(res_key, required, owned)
        _tune_card_resource_row(row)

    if cost_title_label:
        var markup_percent: int = 0
        if BuildingRegistry and BuildingRegistry.has_method("get_next_build_markup_percent"):
            markup_percent = int(BuildingRegistry.get_next_build_markup_percent(config.building_id))
        if markup_percent > 0:
            cost_title_label.text = "BUILD COST:\nNext build will cost +%d%%" % markup_percent
        else:
            cost_title_label.text = "BUILD COST:"

func _tune_card_resource_row(row: Control, icon_size: float = CARD_RESOURCE_ICON_SIZE) -> void:
    if not row:
        return

    var icon := row.get_node_or_null("Icon") as TextureRect
    if icon:
        icon.custom_minimum_size = Vector2(icon_size, icon_size)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

    var label := row.get_node_or_null("ValueLabel") as Label
    if label:
        label.add_theme_font_size_override("font_size", CARD_RESOURCE_FONT_SIZE)
        label.modulate = Color(0, 0, 0, 1)

func set_exclude_enabled(enabled: bool) -> void:
    if exclude_button:
        exclude_button.visible = enabled
        exclude_button.disabled = false
        exclude_button.focus_mode = Control.FOCUS_NONE
    if not enabled and exclude_popup:
        exclude_popup.visible = false

func _clear_container(c: Node) -> void:
    if not c:
        return
    for ch in c.get_children():
        ch.queue_free()

func _on_choose_pressed() -> void:
    if building_id != "":
        selected.emit(building_id)

func _on_exclude_pressed() -> void:
    if building_id != "":
        if exclude_button:
            exclude_button.visible = false
        excluded.emit(building_id)

func _on_exclude_hover_entered() -> void:
    if exclude_button and exclude_button.disabled:
        return
    if exclude_popup:
        exclude_popup.visible = true

func _on_exclude_hover_exited() -> void:
    if exclude_popup:
        exclude_popup.visible = false

func _on_portrait_hover_entered() -> void:
    if _portrait_unit_id == "" or not hero_portrait:
        return
    if _unit_tooltip and is_instance_valid(_unit_tooltip):
        _unit_tooltip.queue_free()
        _unit_tooltip = null

    var panel := UnitInfoPanelScene.instantiate() as UnitInfoPanel
    if panel == null:
        return
    var tree := get_tree()
    if tree == null:
        panel.queue_free()
        return

    var parent: Node = _resolve_popup_parent()
    if parent == null and tree.current_scene:
        parent = tree.current_scene
    if parent == null:
        parent = self
    if parent == null:
        panel.queue_free()
        return

    parent.add_child(panel)
    panel.top_level = true
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.z_index = 1200
    panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
    panel.anchor_left = 0.0
    panel.anchor_top = 0.0
    panel.anchor_right = 0.0
    panel.anchor_bottom = 0.0
    panel.setup(_portrait_unit_id)
    panel.reset_size()

    var fitted_size: Vector2 = panel.get_combined_minimum_size()
    if fitted_size != Vector2.ZERO:
        panel.custom_minimum_size = fitted_size
        panel.size = fitted_size
    _unit_tooltip = panel

    var rect := hero_portrait.get_global_rect()
    var panel_size := panel.get_combined_minimum_size()
    if panel_size == Vector2.ZERO:
        panel_size = panel.size

    var target := Vector2(
        rect.position.x + rect.size.x * 0.5 - panel_size.x * 0.5,
        rect.position.y - panel_size.y - 10.0
    )
    var vp_size := get_viewport().get_visible_rect().size
    var max_x: float = max(8.0, float(vp_size.x) - float(panel_size.x) - 8.0)
    var max_y: float = max(8.0, float(vp_size.y) - float(panel_size.y) - 8.0)
    panel.global_position = Vector2(clampf(target.x, 8.0, max_x), clampf(target.y, 8.0, max_y))

func _on_portrait_hover_exited() -> void:
    if _unit_tooltip and is_instance_valid(_unit_tooltip):
        _unit_tooltip.queue_free()
    _unit_tooltip = null

func _resolve_popup_parent() -> CanvasItem:
    var tree := get_tree()
    if tree == null:
        return null

    var main_ui: Node = null
    if tree.current_scene:
        main_ui = tree.current_scene.get_node_or_null("UILayer/MainUI")
    if main_ui == null:
        main_ui = tree.get_first_node_in_group("main_ui")

    if main_ui and main_ui.has_method("get_popup_layer"):
        var popup_layer_value: Variant = main_ui.call("get_popup_layer")
        var popup_layer_canvas: CanvasItem = popup_layer_value as CanvasItem
        if popup_layer_canvas:
            return popup_layer_canvas

    if main_ui is CanvasItem:
        return main_ui as CanvasItem

    return null
