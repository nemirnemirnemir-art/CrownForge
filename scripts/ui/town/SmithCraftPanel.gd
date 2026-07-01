extends Control
class_name SmithCraftPanel

const TownAlchemyCraftScript := preload("res://core/town/TownAlchemyCraft.gd")
const ItemCatalogResource := preload("res://modules/inventory/item_catalog.gd")
const FactorUiTexture: Texture2D = preload("res://assets/ui/craft_panel/factor_ui.png")
const ThaleahFont := preload("res://assets/ui/fonts/ThaleahFat.ttf")
const SmithCraftRecipesModelScript := preload("res://scripts/ui/town/smith/SmithCraftRecipesModel.gd")
const SmithCraftQueueModelScript := preload("res://scripts/ui/town/smith/SmithCraftQueueModel.gd")

const _CRAFT_BUTTON_HOVER_COLOR := Color(1.15, 1.15, 1.15, 1.0)
const _CRAFT_BUTTON_IDLE_COLOR := Color(1, 1, 1, 1)
const _FONT_OUTLINE_COLOR := Color(0, 0, 0, 1)
const _FONT_OUTLINE_SIZE := 2

@onready var close_button: SliderButton = $Canvas/CloseButton
@onready var slot_buttons: Array[TextureButton] = [
    $Canvas/Slot0,
    $Canvas/Slot1,
    $Canvas/Slot2,
    $Canvas/Slot3,
    $Canvas/Slot4,
    $Canvas/Slot5,
]

@onready var plus_button: SliderButton = $Canvas/Plus
@onready var minus_button: SliderButton = $Canvas/Minus

@onready var title_label: Label = $Canvas/CraftCard/Header/Title
@onready var description_label: Label = $Canvas/CraftCard/Description
@onready var ingredients_rows: VBoxContainer = $Canvas/CraftCard/IngredientsRows
@onready var recipes_panel: Control = $Canvas/RecipesPanel
@onready var recipes_list: VBoxContainer = $Canvas/RecipesPanel/RecipesList
@onready var craft_button: TextureButton = $Canvas/RecipesPanel/CraftButton
@onready var slot_status_nodes: Array[Control] = [
    $Canvas/SlotStatusContainer/SlotStatus0,
    $Canvas/SlotStatusContainer/SlotStatus1,
    $Canvas/SlotStatusContainer/SlotStatus2,
    $Canvas/SlotStatusContainer/SlotStatus3,
    $Canvas/SlotStatusContainer/SlotStatus4,
    $Canvas/SlotStatusContainer/SlotStatus5,
]
var _tick_timer: Timer

var _smith_state: SmithState
var _ui_builder: SmithUIBuilder
var _recipes_model: SmithCraftRecipesModel
var _queue_model: SmithCraftQueueModel

var _ingredient_row_nodes: Array[Control] = []

const _RECIPES_VISIBLE_ROWS: int = 4

const _REQ_ICON_SIZE: float = 32.0

func _ready() -> void:
    _ui_builder = SmithUIBuilder.new()

    if close_button:
        close_button.pressed.connect(_on_close_pressed)

    if title_label:
        _apply_thaleah_font(title_label, 2.0)
    if description_label:
        _apply_thaleah_font(description_label, 1.5)

    for i in range(slot_buttons.size()):
        var b := slot_buttons[i]
        if b:
            b.pressed.connect(Callable(self, "_select_slot").bind(i))

        var cancel_btn: Button = b.get_node_or_null("Cancel")
        if cancel_btn:
            cancel_btn.pressed.connect(Callable(self, "_on_cancel_pressed").bind(i))

    if plus_button:
        plus_button.pressed.connect(_on_plus_pressed)
    if minus_button:
        minus_button.pressed.connect(_on_minus_pressed)

    _smith_state = SmithState.new()
    _smith_state.setup(slot_buttons.size())
    _recipes_model = SmithCraftRecipesModelScript.new()
    _recipes_model.initialize(_smith_state)
    _queue_model = SmithCraftQueueModelScript.new()
    _queue_model.initialize(_smith_state)

    _tick_timer = Timer.new()
    _tick_timer.one_shot = false
    _tick_timer.wait_time = 1.0
    _tick_timer.timeout.connect(_on_tick)
    add_child(_tick_timer)

    if recipes_panel:
        recipes_panel.gui_input.connect(_on_recipes_panel_gui_input)
    if craft_button:
        craft_button.pressed.connect(_on_craft_pressed)
        craft_button.mouse_entered.connect(_on_craft_button_mouse_entered)
        craft_button.mouse_exited.connect(_on_craft_button_mouse_exited)

    _ui_builder.rebuild_recipe_rows(recipes_list, _RECIPES_VISIBLE_ROWS, Callable(self, "_on_recipe_row_pressed"))

    _select_slot(_smith_state.selected_slot_index)
    hide()

func open() -> void:
    show()
    _select_slot(_smith_state.selected_slot_index)
    _tick_timer.start()
    _refresh()

func close() -> void:
    _tick_timer.stop()
    hide()

func _on_close_pressed() -> void:
    close()

func _on_tick() -> void:
    if not visible:
        _tick_timer.stop()
        return
    _queue_model.tick(SmithCraftRecipes.RECIPES)
    _refresh()

func _select_slot(slot_index: int) -> void:
    _smith_state.selected_slot_index = clamp(slot_index, 0, slot_buttons.size() - 1)
    for i in range(slot_buttons.size()):
        if slot_buttons[i]:
            slot_buttons[i].button_pressed = (i == _smith_state.selected_slot_index)
    _refresh()

func _on_plus_pressed() -> void:
    _queue_model.adjust_pending_qty(1)
    _refresh()

func _on_minus_pressed() -> void:
    _queue_model.adjust_pending_qty(-1)
    _refresh()

func _on_cancel_pressed(slot_index: int) -> void:
    _smith_state.cancel_crafting(slot_index, SmithCraftRecipes.RECIPES)
    _refresh()

func _refresh() -> void:
    title_label.text = "Forge Slot %d" % (_smith_state.selected_slot_index + 1)
    if description_label:
        var recipe: Dictionary = _recipes_model.get_selected_recipe()
        description_label.text = str(recipe.get("display_name", ""))

    _refresh_craftcard_ingredients()

    var is_crafting := _queue_model.is_selected_slot_crafting()
    if plus_button:
        plus_button.disabled = is_crafting
    if minus_button:
        minus_button.disabled = is_crafting

    if craft_button:
        craft_button.disabled = not _smith_state.can_start_selected(SmithCraftRecipes.RECIPES)
        if craft_button.disabled:
            craft_button.self_modulate = _CRAFT_BUTTON_IDLE_COLOR

    _ui_builder.refresh_slot_ui(slot_buttons, slot_status_nodes, _smith_state.slot_state, SmithCraftRecipes.RECIPES)
    _ui_builder.refresh_recipe_rows(recipes_list, _RECIPES_VISIBLE_ROWS, _recipes_model.get_scroll(), _recipes_model.get_selected_index(), SmithCraftRecipes.RECIPES)

func _refresh_craftcard_ingredients() -> void:
    var pending_qty: int = _queue_model.get_pending_qty()
    var recipe: Dictionary = _recipes_model.get_selected_recipe()
    var base_cost: Array = recipe.get("cost", [])

    var rows: Array = []
    for c in base_cost:
        rows.append({"id": c.get("id", ""), "qty": int(c.get("qty", 0)) * pending_qty, "icon": c.get("icon", "")})

    _ingredient_row_nodes = _ui_builder.refresh_ingredient_rows(ingredients_rows, _ingredient_row_nodes, rows)

func _on_craft_pressed() -> void:
    _smith_state.start_crafting(SmithCraftRecipes.RECIPES, Callable(self, "_get_craft_visual_for_recipe"))
    _refresh()

func _on_recipes_panel_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.pressed:
            recipes_panel.grab_focus()
            if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
                _recipes_model.scroll_by(-1)
                _ui_builder.refresh_recipe_rows(recipes_list, _RECIPES_VISIBLE_ROWS, _recipes_model.get_scroll(), _recipes_model.get_selected_index(), SmithCraftRecipes.RECIPES)
            elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
                _recipes_model.scroll_by(1)
                _ui_builder.refresh_recipe_rows(recipes_list, _RECIPES_VISIBLE_ROWS, _recipes_model.get_scroll(), _recipes_model.get_selected_index(), SmithCraftRecipes.RECIPES)

func _on_recipe_row_pressed(row_index: int) -> void:
    _recipes_model.select_at_visible_index(row_index)
    _refresh()

func _on_craft_button_mouse_entered() -> void:
    if craft_button and not craft_button.disabled:
        craft_button.self_modulate = _CRAFT_BUTTON_HOVER_COLOR

func _on_craft_button_mouse_exited() -> void:
    if craft_button:
        craft_button.self_modulate = _CRAFT_BUTTON_IDLE_COLOR

func _apply_thaleah_font(label: Label, size_multiplier: float = 1.0) -> void:
    _ui_builder.apply_thaleah_font(label, size_multiplier)

func _get_craft_visual_for_recipe(recipe: Dictionary) -> String:
    return SmithCraftRecipes.get_craft_visual_path(recipe)
