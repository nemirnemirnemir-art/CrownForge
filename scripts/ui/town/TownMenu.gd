extends Control
class_name TownMenu

## Main UI for the Town System

var _prev_tree_paused: bool = false

func _get_autoload(name: String) -> Node:
    return get_node_or_null("/root/%s" % name)

func _town_core() -> Node:
    return _get_autoload("TownCore")

func _event_bus() -> Node:
    return _get_autoload("EventBus")

func _economy_core() -> Node:
    return _get_autoload("EconomyCore")

@onready var food_label: Label = $Header/FoodLabel
@onready var potions_label: Label = $Header/PotionsLabel
@onready var population_label: Label = $Header/PopulationLabel
@onready var forge_cores_label: Label = $Header/ForgeCoresLabel
@onready var forge_button: Button = $Header/ForgeButton
@onready var inventory_button: Button = $Header/InventoryButton
@onready var buildings_container: Container = $ScrollContainer/BuildingsGrid
@onready var upgrade_popup: BuildingUpgradePopup = $BuildingUpgradePopup
@onready var smith_panel: SmithCraftPanel = $SmithCraftPanel
@onready var inventory_panel: TownInventoryPanel = $TownInventoryPanel
@onready var back_button: Button = $Header/BackButton

# PackedScene for BuildingCard - assuming we'll load it
var building_card_scene: PackedScene = preload("res://scenes/ui/town/BuildingCard.tscn")

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false

    if back_button:
        back_button.pressed.connect(_on_back_pressed)
    if forge_button:
        forge_button.pressed.connect(_on_forge_pressed)
    
    if inventory_button:
        inventory_button.pressed.connect(_on_inventory_button_pressed)

    if smith_panel:
        smith_panel.hide()
    
    if inventory_panel:
        inventory_panel.hide()
    
    # Connect signals
    var town_core: Node = _town_core()
    if town_core != null:
        if town_core.has_signal("potion_produced"):
            town_core.connect("potion_produced", Callable(self, "_on_potion_produced"))
        if town_core.has_signal("hero_assigned_potion"):
            town_core.connect("hero_assigned_potion", Callable(self, "_on_potion_consumed"))
        if town_core.has_signal("building_upgraded"):
            town_core.connect("building_upgraded", Callable(self, "_on_building_upgraded"))
    var event_bus: Node = _event_bus()
    if event_bus != null and event_bus.has_signal("forge_cores_changed"):
        event_bus.connect("forge_cores_changed", Callable(self, "_on_forge_cores_changed"))
    
    # Initial update
    _update_resources()
    _create_building_cards()

func _update_resources() -> void:
    if food_label:
        food_label.hide()
    if potions_label:
        var town_core: Node = _town_core()
        potions_label.text = "Potions: %d" % (int(town_core.call("get_global_potions")) if town_core != null else 0)
    if population_label:
        population_label.hide()
    _update_forge_label()

func _update_forge_label() -> void:
    var economy_core: Node = _economy_core()
    if forge_cores_label and economy_core != null:
        forge_cores_label.text = "Forge Cores: %d" % int(economy_core.call("get_forge_cores"))

func _create_building_cards() -> void:
    # Clear existing
    for child in buildings_container.get_children():
        child.queue_free()
    
    # Get all buildings (we need a list of IDs)
    # TownCore doesn't expose the list directly via API, but we know them or can add `get_all_building_ids()`
    # Let's add `get_all_building_ids()` to TownCore.
    var town_core: Node = _town_core()
    var ids: Array = town_core.call("get_all_building_ids") if town_core != null else []

    for id in ids:
        var card: BuildingCard = building_card_scene.instantiate() as BuildingCard
        # Оборачиваем карточку в MarginContainer для создания расстояния
        var margin_container = MarginContainer.new()
        margin_container.add_theme_constant_override("margin_left", 100)
        margin_container.add_theme_constant_override("margin_right", 100)
        buildings_container.add_child(margin_container)
        margin_container.add_child(card)
        card.setup(id)
        card.upgrade_requested.connect(_on_upgrade_requested)

func _on_food_changed(new_amount: float, _delta: float) -> void:
    if food_label:
        food_label.text = "Food: %.1f" % new_amount

func _on_potion_produced(amount: int) -> void:
    if potions_label:
        potions_label.text = "Potions: %d" % amount

func _on_potion_consumed(_hero_id: String, amount: int) -> void:
    if potions_label:
        potions_label.text = "Potions: %d" % amount

func _on_building_upgraded(building_id: String, _level: int) -> void:
    # Find the card and update it
    for child in buildings_container.get_children():
        if child is BuildingCard and child.building_id == building_id:
            child.update_display()
            break
    # ✅ Update population capacity
    _update_resources()

func _on_upgrade_requested(building_id: String) -> void:
    if upgrade_popup:
        upgrade_popup.open(building_id)

func _on_forge_pressed() -> void:
    if not smith_panel:
        return
    if smith_panel.visible:
        smith_panel.close()
    else:
        smith_panel.open()

func _on_inventory_button_pressed() -> void:
    if inventory_panel:
        inventory_panel.open()

func open_forge_panel() -> void:
    _on_forge_pressed()

func open_inventory_panel() -> void:
    _on_inventory_button_pressed()

func open_alchemy_panel() -> void:
    if upgrade_popup:
        upgrade_popup.open("alchemist")

func _on_back_pressed() -> void:
    close_menu()

func open_menu() -> void:
    if visible:
        return
    _update_resources()
    var tree := get_tree()
    if tree:
        _prev_tree_paused = tree.paused
        tree.paused = true
        var hero_bar: Node = tree.current_scene.get_node_or_null("UILayer/HeroBar") if tree.current_scene else null
        var hero_card: Node = tree.current_scene.get_node_or_null("UILayer/HeroCard") if tree.current_scene else null
        if hero_bar:
            hero_bar.hide()
        if hero_card:
            hero_card.hide()
    visible = true

func close_menu() -> void:
    if not visible:
        return
    visible = false
    var tree := get_tree()
    if tree:
        tree.paused = _prev_tree_paused
    if smith_panel:
        smith_panel.close()
    if inventory_panel:
        inventory_panel.close()
    # Show HeroBar and HeroCard back when closing TownMenu
    var hero_bar: Node = null
    var hero_card: Node = null
    if tree and tree.current_scene:
        hero_bar = tree.current_scene.get_node_or_null("UILayer/HeroBar")
        hero_card = tree.current_scene.get_node_or_null("UILayer/HeroCard")
    if hero_bar == null and tree:
        hero_bar = tree.get_first_node_in_group("hero_bar")
    if hero_card == null and tree:
        hero_card = tree.get_first_node_in_group("hero_card")
    if hero_bar:
        hero_bar.show()
    if hero_card:
        hero_card.show()

# ✅ Handlers for population updates
func _on_hero_population_changed(_id: String, _data: Dictionary) -> void:
    _update_resources()

func _on_heroes_cleared() -> void:
    _update_resources()

func _on_hero_population_changed_generic() -> void:
    _update_resources()

func _on_forge_cores_changed(_new_amount: int, _delta: int) -> void:
    _update_forge_label()

func _on_population_changed(_used: int, _max_pop: int) -> void:
    _update_resources()
