extends Control
class_name BuildingMenu

signal building_selected(building_id: String)
signal building_drag_started(building_id: String)

const BuildingIconTileScene: PackedScene = preload("res://scenes/ui/town/BuildingIconTile.tscn")
const DenariiSellPopupScene: PackedScene = preload("res://core/effects/DenariiSellPopup.tscn")
const BuildingMenuCatalogScript := preload("res://scripts/ui/building/BuildingMenuCatalog.gd")
const BuildingMenuDetailsScript := preload("res://scripts/ui/building/BuildingMenuDetails.gd")
const BuildingMenuToolsScript := preload("res://scripts/ui/building/BuildingMenuTools.gd")
const BuildingMenuAffordabilityScript := preload("res://scripts/ui/building/BuildingMenuAffordability.gd")

@export var single_row_mode: bool = false
@export var details_panel_offset: Vector2 = Vector2(12.0, 0.0)
@export var details_panel_use_custom_position: bool = false
@export var details_panel_custom_global_position: Vector2 = Vector2.ZERO

@export var category_filter_path: NodePath

@onready var container: GridContainer = get_node_or_null("Content/GridContainer")
@onready var details_panel: Control = get_node_or_null("Content/DetailsPanel")
@onready var prev_button: TextureButton = get_node_or_null("PrevButton")
@onready var next_button: TextureButton = get_node_or_null("NextButton")
@onready var category_filter: BuildingCategoryFilter = null
@onready var tools_container: Node = self # Tools are now direct children

var _selected_id: String = ""
var _active_tool: String = "" # "destroy", "sell"
var _building_ids: Array = []
var _current_page: int = 0
var _current_category: int = -1  ## -1 = ALL
var _hovered_id: String = ""
var _search_text: String = ""
var _search_edit: LineEdit = null
var _catalog_helper: BuildingMenuCatalog = BuildingMenuCatalogScript.new()
var _details_helper: BuildingMenuDetails = BuildingMenuDetailsScript.new()
var _tools_helper: BuildingMenuTools = BuildingMenuToolsScript.new()
var _affordability_helper: BuildingMenuAffordability = BuildingMenuAffordabilityScript.new()

var TILES_PER_PAGE: int:
    get:
        return 5 if single_row_mode else 10

func _building_registry() -> Node:
    return get_node_or_null("/root/BuildingRegistry")

func _town_core() -> Node:
    return get_node_or_null("/root/TownCore")

func _seal_registry() -> Node:
    return get_node_or_null("/root/SealRegistry")

func _resource_core() -> Node:
    return get_node_or_null("/root/ResourceCore")

func _economy_core() -> Node:
    return get_node_or_null("/root/EconomyCore")

func _event_bus() -> Node:
    return get_node_or_null("/root/EventBus")

func _ready():
    add_to_group("building_menu")
    _resolve_category_filter()
    _setup_search_field()
    if not container:
        push_warning("[BuildingMenu] GridContainer not found; cannot build buttons.")
        return

    var building_registry := _building_registry()
    if building_registry and building_registry.has_signal("recipe_changed") and not building_registry.recipe_changed.is_connected(_on_recipe_changed):
        building_registry.recipe_changed.connect(_on_recipe_changed)

    if prev_button and not prev_button.pressed.is_connected(_on_prev_pressed):
        prev_button.pressed.connect(_on_prev_pressed)
    if next_button and not next_button.pressed.is_connected(_on_next_pressed):
        next_button.pressed.connect(_on_next_pressed)
    
    if category_filter and not category_filter.category_selected.is_connected(_on_category_selected):
        category_filter.category_selected.connect(_on_category_selected)

    var resource_core := _resource_core()
    if resource_core and not resource_core.resource_changed.is_connected(_on_resource_changed):
        resource_core.resource_changed.connect(_on_resource_changed)
    var event_bus := _event_bus()
    if event_bus and event_bus.has_signal("gold_changed") and not event_bus.gold_changed.is_connected(_on_gold_changed):
        event_bus.gold_changed.connect(_on_gold_changed)

    _refresh_building_list()
    _setup_tool_buttons()

    if details_panel:
        details_panel.hide()

    if _selected_id == "" and _building_ids.size() > 0:
        _selected_id = _building_ids[0]

    _refresh_menu()
    _hide_details_panel()

func _on_recipe_changed(_building_id: String, _new_count: int) -> void:
    var building_registry := _building_registry()
    if building_registry == null:
        return
    if not building_registry.has_method("is_release_mode_enabled"):
        return
    if not building_registry.is_release_mode_enabled():
        return
    # In release mode, recipe counts affect visibility of buildings in the menu.
    _refresh_building_list()
    _refresh_menu()

func _resolve_category_filter() -> void:
    if category_filter:
        return
    if category_filter_path != NodePath(""):
        var node := get_node_or_null(category_filter_path)
        if node:
            category_filter = node
            return
        push_warning("[BuildingMenu] category_filter_path set but node not found: %s" % category_filter_path)
    var fallback := get_node_or_null("CategoryFilter")
    if fallback:
        category_filter = fallback

func _on_category_selected(category: int) -> void:
    _current_category = category
    _current_page = 0
    _hovered_id = ""
    _refresh_building_list()
    _refresh_menu()
    _hide_details_panel()

func _refresh_building_list() -> void:
    _catalog_helper.refresh_building_list(self)
    _apply_search_filter()

func _refresh_menu():
    if not container:
        return
    if _building_ids.is_empty():
        _hovered_id = ""
        _hide_details_panel()
        return

    var max_page := _get_max_page()
    _current_page = clampi(_current_page, 0, max_page)

    _catalog_helper.refresh_tiles_for_page(self)

    _update_affordability()
    _refresh_selection_visuals()
    _refresh_tool_visuals()
    _update_nav_buttons()

func _setup_tool_buttons() -> void:
    _tools_helper.setup_tool_buttons(self)

func _on_tool_pressed(tool_id: String) -> void:
    _tools_helper.handle_tool_pressed(self, tool_id)

func _refresh_tool_visuals() -> void:
    _tools_helper.refresh_tool_visuals(self)

func get_active_tool() -> String:
    return _active_tool

func cancel_tool() -> void:
    _active_tool = ""
    _refresh_tool_visuals()

func clear_selection() -> void:
    if _selected_id == "":
        return
    _selected_id = ""
    _refresh_selection_visuals()
    _hide_details_panel()

func _on_tile_hover_started(id: String) -> void:
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        return
    _hovered_id = id
    _refresh_details_panel()

func _on_tile_hover_ended(id: String) -> void:
    if id != _hovered_id:
        return
    _hovered_id = ""
    _refresh_details_panel()

func _on_tile_drag_started(id: String) -> void:
    if not _can_interact_with_building(id):
        return
    building_drag_started.emit(id)

func _on_tile_pressed(id: String) -> void:
    if not _can_interact_with_building(id):
        return
    if _active_tool == "sell":
        # Sell action is allowed only from this build-selection menu.
        var economy_core := _economy_core()
        if economy_core:
            economy_core.add_gold(5.0)
        _spawn_denarii_sell_popup(get_global_mouse_position(), 5)
        cancel_tool()
    else:
        _select_building(id, true)

func _can_interact_with_building(id: String) -> bool:
    if id == "":
        return false
    var seal_registry := _seal_registry()
    if seal_registry and seal_registry.get_seal(id):
        return bool(seal_registry.can_afford_seal(id))
    var building_registry := _building_registry()
    if building_registry and building_registry.get_building(id):
        return bool(building_registry.can_afford_building(id))
    var town_core := _town_core()
    if town_core and town_core.get_building_config(id):
        return bool(town_core.can_build(id))
    return true

func _spawn_denarii_sell_popup(global_pos: Vector2, amount: int) -> void:
    _tools_helper.spawn_denarii_sell_popup(self, global_pos, amount)

func _select_building(id: String, should_emit: bool) -> void:
    _ensure_building_visible(id)
    _selected_id = id
    _active_tool = "" # Clear tool when building is selected
    _refresh_tool_visuals()
    _refresh_selection_visuals()
    if should_emit:
        building_selected.emit(id)

func _refresh_selection_visuals() -> void:
    if not container:
        return
    for child in container.get_children():
        if child is BuildingIconTile:
            (child as BuildingIconTile).set_selected((child as BuildingIconTile).building_id == _selected_id)

func _update_affordability() -> void:
    _affordability_helper.update_affordability(self)

func _on_resource_changed(_resource_id: String, _amount: int) -> void:
    _update_affordability()
    if _hovered_id != "":
        _refresh_details_panel()


func _on_gold_changed(_new_amount: float, _delta: float) -> void:
    _update_affordability()
    if _hovered_id != "":
        _refresh_details_panel()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        if _active_tool != "":
            cancel_tool()
            get_viewport().set_input_as_handled()

func _on_prev_pressed() -> void:
    if _current_page <= 0:
        return
    _current_page -= 1
    _refresh_menu()

func _on_next_pressed() -> void:
    if _current_page >= _get_max_page():
        return
    _current_page += 1
    _refresh_menu()

func _get_max_page() -> int:
    return _catalog_helper.get_max_page(self)

func _update_nav_buttons() -> void:
    _catalog_helper.update_nav_buttons(self)

func _ensure_building_visible(id: String) -> void:
    _catalog_helper.ensure_building_visible(self, id)

func _show_details_for_building(building_id: String) -> void:
    _details_helper.show_details_for_building(self, building_id)

func _get_displayed_building_id() -> String:
    return _details_helper.get_displayed_building_id(self)

func _refresh_details_panel() -> void:
    _details_helper.refresh_details_panel(self)

func _position_details_panel() -> void:
    _details_helper.position_details_panel(self)

func _hide_details_panel() -> void:
    _details_helper.hide_details_panel(self)

func _setup_search_field() -> void:
    if _search_edit != null:
        return
    _search_edit = LineEdit.new()
    _search_edit.name = "SearchEdit"
    _search_edit.placeholder_text = "..."
    _search_edit.anchor_left = 0.0
    _search_edit.anchor_top = 0.0
    _search_edit.anchor_right = 0.0
    _search_edit.anchor_bottom = 0.0
    _search_edit.offset_left = 12.0
    _search_edit.offset_top = -42.0
    _search_edit.offset_right = 62.0  # Compact: ~50px width
    _search_edit.offset_bottom = -8.0
    _search_edit.custom_minimum_size = Vector2(50.0, 28.0)
    _search_edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _search_edit.text_changed.connect(_on_search_changed)
    _search_edit.focus_entered.connect(_on_search_focus_entered)
    _search_edit.focus_exited.connect(_on_search_focus_exited)
    add_child(_search_edit)
    move_child(_search_edit, 0)

func _on_search_focus_entered() -> void:
    if _search_edit:
        # Expand to full width when focused
        _search_edit.offset_right = 232.0
        _search_edit.custom_minimum_size = Vector2(220.0, 28.0)
        _search_edit.placeholder_text = "Search buildings..."

func _on_search_focus_exited() -> void:
    if _search_edit and _search_edit.text.is_empty():
        # Collapse back to compact when empty and unfocused
        _search_edit.offset_right = 62.0
        _search_edit.custom_minimum_size = Vector2(50.0, 28.0)
        _search_edit.placeholder_text = "..."

func _on_search_changed(text: String) -> void:
    _search_text = text.to_lower().strip_edges()
    _current_page = 0
    _refresh_building_list()
    _refresh_menu()
    _hide_details_panel()

func _apply_search_filter() -> void:
    if _search_text.is_empty():
        return
    var filtered: Array = []
    for id in _building_ids:
        var building_id := String(id)
        if _matches_search(building_id):
            filtered.append(building_id)
    _building_ids = filtered

func _get_config_display_name(config: Variant) -> String:
    if config == null:
        return ""
    if config is Dictionary:
        return String(config.get("display_name", ""))
    if config is Object:
        var object_config := config as Object
        var properties: Array[Dictionary] = object_config.get_property_list()
        for property_data in properties:
            if String(property_data.get("name", "")) == "display_name":
                return String(object_config.get("display_name"))
    return ""

func _matches_search(building_id: String) -> bool:
    if building_id.to_lower().find(_search_text) != -1:
        return true
    var config: Variant = null
    var building_registry := _building_registry()
    if building_registry:
        config = building_registry.get_building(building_id)
    if config == null:
        var town_core := _town_core()
        if town_core:
            config = town_core.get_building_config(building_id)
    if config == null:
        var seal_registry := _seal_registry()
        if seal_registry:
            config = seal_registry.get_seal(building_id)
    if config == null:
        return false
    var display_name := _get_config_display_name(config).to_lower()
    return display_name.find(_search_text) != -1
