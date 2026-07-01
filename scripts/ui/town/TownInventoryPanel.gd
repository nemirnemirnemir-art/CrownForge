extends Control
class_name TownInventoryPanel

## Panel for managing Town Storage and Player Inventory
## Allows transferring items between them and managing equipment

@onready var player_grid: GridContainer = $Content/PlayerSection/PlayerGrid
@onready var town_grid: GridContainer = $Content/TownSection/TownGrid
@onready var close_button: BaseButton = $CloseButton

# Info Panel
@onready var info_panel_container: Control = $Content/InfoSection
@onready var item_name_label: Label = $Content/InfoSection/InfoPanel/ItemName
@onready var item_desc_label: RichTextLabel = $Content/InfoSection/InfoPanel/ItemDescription
@onready var equip_button: BaseButton = $Content/InfoSection/ActionButtons/EquipButton
@onready var destroy_button: BaseButton = $Content/InfoSection/ActionButtons/DestroyButton
@onready var lock_button: TextureButton = $Content/InfoSection/ActionButtons/LockButton

@onready var auto_arrange_button: BaseButton = $Content/InfoSection/UtilityButtons/AutoArrangeButton
@onready var stack_all_button: BaseButton = $Content/InfoSection/UtilityButtons/StackAllButton
@onready var sort_criteria: OptionButton = $Content/InfoSection/UtilityButtons/SortCriteria
@onready var sort_asc_button: Button = $Content/InfoSection/UtilityButtons/SortAsc
@onready var sort_desc_button: Button = $Content/InfoSection/UtilityButtons/SortDesc
@onready var sort_apply_button: BaseButton = $Content/InfoSection/UtilityButtons/SortApplyButton

const ThaleahFont := preload("res://assets/ui/fonts/ThaleahFat.ttf")

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/InventorySlot.tscn")

const TOWN_INVENTORY_PANEL_SLOTS_SCRIPT = preload("res://scripts/ui/town/TownInventoryPanelSlots.gd")
const TOWN_INVENTORY_PANEL_TRANSFERS_SCRIPT = preload("res://scripts/ui/town/TownInventoryPanelTransfers.gd")
const TOWN_INVENTORY_PANEL_UTILITY_SCRIPT = preload("res://scripts/ui/town/TownInventoryPanelUtility.gd")
const TOWN_INVENTORY_EQUIP_CONTROLLER_SCRIPT = preload("res://scripts/ui/town/TownInventoryEquipToHeroController.gd")

var _selected_slot: InventorySlot = null
var _selected_context: String = "" # "player" or "town"

var _slots_module
var _transfers_module
var _utility_module
var _equip_controller

func _ready() -> void:
    if close_button:
        close_button.pressed.connect(close)

    _apply_thaleah_font()

    _transfers_module = TOWN_INVENTORY_PANEL_TRANSFERS_SCRIPT.new()
    _transfers_module.initialize(self)
    _slots_module = TOWN_INVENTORY_PANEL_SLOTS_SCRIPT.new()
    _slots_module.initialize(self)
    _utility_module = TOWN_INVENTORY_PANEL_UTILITY_SCRIPT.new()
    _utility_module.initialize(self, _transfers_module)
    _equip_controller = TOWN_INVENTORY_EQUIP_CONTROLLER_SCRIPT.new()
    _equip_controller.initialize(self)

    if auto_arrange_button:
        auto_arrange_button.pressed.connect(_on_auto_arrange_pressed)
    if stack_all_button:
        stack_all_button.pressed.connect(_on_stack_all_pressed)

    if sort_criteria:
        sort_criteria.clear()
        sort_criteria.add_item("Type", 0)
        sort_criteria.add_item("Rarity", 1)
        sort_criteria.add_item("Name", 2)
        sort_criteria.add_item("Power", 3)
        sort_criteria.add_item("Weight", 4)
        sort_criteria.add_item("Time", 5)
        sort_criteria.selected = 0

    if sort_asc_button:
        sort_asc_button.pressed.connect(Callable(self, "_on_sort_pressed").bind(true))
    if sort_desc_button:
        sort_desc_button.pressed.connect(Callable(self, "_on_sort_pressed").bind(false))
    if sort_apply_button:
        sort_apply_button.pressed.connect(Callable(self, "_on_sort_pressed").bind(true))
    
    if equip_button:
        equip_button.pressed.connect(_on_equip_pressed)
    if destroy_button:
        destroy_button.pressed.connect(_on_destroy_pressed)
    if lock_button:
        lock_button.toggled.connect(_on_lock_toggled)
    
    # Connect to updates
    if is_instance_valid(PlayerInventory):
        PlayerInventory.inventory_updated.connect(_update_player_grid)
    
    if is_instance_valid(TownCore):
        var town_inv = TownCore.get_town_inventory()
        if town_inv:
            town_inv.inventory_updated.connect(_update_town_grid)
    
    # Initial draw (deferred to ensure nodes are ready)
    call_deferred("_setup_grids")
    
    _update_info_panel()

func _apply_thaleah_font() -> void:
    _apply_thaleah_font_recursive(self)

func _apply_thaleah_font_recursive(node: Node) -> void:
    if node is Label:
        var lbl := node as Label
        lbl.add_theme_font_override("font", ThaleahFont)
        lbl.add_theme_font_size_override("font_size", int(lbl.get_theme_font_size("font_size") * 2))
    elif node is RichTextLabel:
        var rtl := node as RichTextLabel
        rtl.add_theme_font_override("normal_font", ThaleahFont)
        rtl.add_theme_font_size_override("normal_font_size", int(rtl.get_theme_font_size("normal_font_size") * 2))
    elif node is Button:
        var btn := node as Button
        btn.add_theme_font_override("font", ThaleahFont)
        btn.add_theme_font_size_override("font_size", int(btn.get_theme_font_size("font_size") * 2))

    for child in node.get_children():
        _apply_thaleah_font_recursive(child)

func open() -> void:
    show()
    _update_player_grid()
    _update_town_grid()
    _select_slot(null, "")

func close() -> void:
    hide()
    _select_slot(null, "")

func _setup_grids() -> void:
    if _slots_module:
        _slots_module.setup_grids()

func _update_player_grid() -> void:
    if _slots_module:
        _slots_module.update_player_grid()

func _update_town_grid() -> void:
    if _slots_module:
        _slots_module.update_town_grid()

## --- Selection & Info Panel ---

func _select_slot(slot: InventorySlot, context: String) -> void:
    if _slots_module:
        _slots_module.select_slot(slot, context)

func _update_info_panel(item: Dictionary = {}) -> void:
    if _slots_module:
        _slots_module.update_info_panel(item)

func _autosave() -> void:
    if _transfers_module:
        _transfers_module.autosave()

func _on_lock_toggled(pressed: bool) -> void:
    if _transfers_module:
        _transfers_module.on_lock_toggled(pressed)

## --- Interaction Handlers ---

func _on_player_slot_clicked(index: int) -> void:
    var slots = player_grid.get_children()
    if index < slots.size():
        _select_slot(slots[index], "player")

func _on_town_slot_clicked(index: int) -> void:
    var slots = town_grid.get_children()
    if index < slots.size():
        _select_slot(slots[index], "town")

func _on_player_slot_double_clicked(index: int) -> void:
    _double_click_transfer("player", index)

func _on_town_slot_double_clicked(index: int) -> void:
    _double_click_transfer("town", index)

func _double_click_transfer(source_context: String, source_index: int) -> void:
    if _transfers_module:
        _transfers_module.double_click_transfer(source_context, source_index)

func _find_first_empty_slot(context: String) -> int:
    if _transfers_module:
        return _transfers_module.find_first_empty_slot(context)
    return -1

func _on_equip_pressed() -> void:
    if _equip_controller:
        _equip_controller.try_equip_selected(_selected_slot, _selected_context)

func _on_destroy_pressed() -> void:
    if _utility_module:
        _utility_module.on_destroy_pressed()

## --- Drag & Drop Handlers ---

func _get_item_at_context(context: String, index: int) -> Dictionary:
    if _transfers_module:
        return _transfers_module.get_item_at_context(context, index)
    return {}

func _set_item_at_context(context: String, index: int, item: Dictionary) -> bool:
    if _transfers_module:
        return _transfers_module.set_item_at_context(context, index, item)
    return false

func _try_merge_stacks(
    source_context: String,
    source_index: int,
    target_context: String,
    target_index: int
) -> bool:
    if _transfers_module:
        return _transfers_module.try_merge_stacks(source_context, source_index, target_context, target_index)
    return false

func _swap_between_contexts(
    source_context: String,
    source_index: int,
    target_context: String,
    target_index: int
) -> void:
    if _transfers_module:
        _transfers_module.swap_between_contexts(source_context, source_index, target_context, target_index)

func _on_slot_data_dropped(source_data: Dictionary, _target_index: int) -> void:
    var _source_slot = source_data.get("source")
    var _source_idx = source_data.get("index")
    var _source_context = _source_slot.get_meta("context")
    
    # Determine target context based on which grid the dropped slot belongs to
    # But the signal comes from the slot itself.
    # We need to know which grid the target slot is in.
    # We can check parent or meta.
    
    # Since we can't easily get the target slot instance from index alone without knowing grid,
    # let's modify the signal connection to include the target context.
    pass # Logic moved to signal connection wrapper

# Helper to handle drop with context
func _handle_drop(source_data: Dictionary, target_index: int, target_context: String) -> void:
    if _transfers_module:
        _transfers_module.handle_drop(source_data, target_index, target_context)

func _swap_town_items(from_idx: int, to_idx: int) -> void:
    if _transfers_module:
        _transfers_module.swap_town_items(from_idx, to_idx)

func _on_stack_all_pressed() -> void:
    if _utility_module:
        _utility_module.on_stack_all_pressed()

func _on_auto_arrange_pressed() -> void:
    if _utility_module:
        _utility_module.on_auto_arrange_pressed()

func _on_sort_pressed(ascending: bool) -> void:
    var crit: int = 0
    if sort_criteria:
        crit = sort_criteria.get_selected_id()

    if _utility_module:
        _utility_module.on_sort_pressed(crit, ascending)

# We need to update signal connection to pass context
func _on_slot_data_dropped_wrapper(data: Dictionary, index: int, context: String) -> void:
    _handle_drop(data, index, context)
