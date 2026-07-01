extends Control
class_name BuildingUpgradePopup

## Popup to show upgrade details and confirm action

const BuildingPresentationDataScript := preload("res://scripts/ui/town/buildings/BuildingPresentationData.gd")

@onready var title_label: Label = $Panel/TitleLabel
@onready var description_label: Label = $Panel/DescriptionLabel
@onready var current_stats_label: Label = $Panel/CurrentStatsLabel
@onready var next_stats_label: Label = $Panel/NextStatsLabel
@onready var upgrade_grid: UpgradeGrid = $Panel/UpgradeGrid
@onready var cost_label: Label = $Panel/CostLabel
@onready var upgrade_button: Button = $Panel/UpgradeButton
@onready var buy_bottle_button: Button = $Panel/BuyBottleButton
@onready var craft_button: Button = $Panel/CraftButton
@onready var close_button: SliderButton = $Panel/CloseButton
@onready var alchemist_craft_panel: AlchemistCraftPanel = $AlchemistCraftPanel

var building_id: String = ""

func _ready() -> void:
    visibility_changed.connect(_on_visibility_changed)

    if close_button:
        close_button.pressed.connect(_on_close_pressed)
    if upgrade_button:
        upgrade_button.pressed.connect(_on_upgrade_pressed)
    if buy_bottle_button:
        buy_bottle_button.pressed.connect(_on_buy_bottle_pressed)
    if craft_button:
        craft_button.pressed.connect(_on_craft_pressed)
    
    hide()

func _on_visibility_changed() -> void:
    if not visible and alchemist_craft_panel:
        alchemist_craft_panel.hide()

func open(id: String) -> void:
    building_id = id
    update_info()

    if alchemist_craft_panel:
        alchemist_craft_panel.hide()

    # Only standard buildings remain (alchemist/forge/house/hospital)
    # Only standard buildings remain (alchemist/forge/house/hospital)
    if upgrade_grid:
        upgrade_grid.setup(id)
        upgrade_grid.show()
    show()

func update_info() -> void:
    if building_id == "": return
    
    var data = TownCore.get_building_config(building_id)
    if not data: return
    
    title_label.text = data.display_name
    description_label.text = BuildingPresentationDataScript.get_description(building_id, data.description)
    
    var level = TownCore.get_building_level(building_id)
    var cost = TownCore.get_building_upgrade_cost(building_id)
    
    cost_label.text = "Cost: %d Gold" % cost
    
    # Check affordability
    if cost > 0 and EconomyCore.can_afford(cost):
        upgrade_button.disabled = false
        cost_label.modulate = Color.WHITE
    else:
        upgrade_button.disabled = true
        cost_label.modulate = Color.RED
        
    # Stats display
    # This is generic, ideally we format based on building type
    var current_stats = _get_stats_text(data, level)
    var next_stats = _get_stats_text(data, level + 1)
    
    current_stats_label.text = "Current (Lvl %d):\n%s" % [level, current_stats]
    next_stats_label.text = "Next (Lvl %d):\n%s" % [level + 1, next_stats]

    _update_alchemist_craft_ui()
    _update_mage_tower_ui()

func _update_mage_tower_ui() -> void:
    var mage_tower_panel := get_node_or_null("Panel/MageTowerPanel") as Control
    if not mage_tower_panel:
        return

    # Mage tower removed from the game; keep panel hidden.
    mage_tower_panel.visible = false
    if upgrade_grid:
        upgrade_grid.visible = true

func _update_alchemist_craft_ui() -> void:
    if not craft_button:
        return

    if building_id != "alchemist":
        craft_button.visible = false
        return

    craft_button.visible = true
    craft_button.disabled = TownCore.get_building_level("alchemist") < 1

func _on_craft_pressed() -> void:
    if building_id != "alchemist":
        return
    if not alchemist_craft_panel:
        return
    alchemist_craft_panel.open()

func _on_close_pressed() -> void:
    if alchemist_craft_panel:
        alchemist_craft_panel.hide()
    hide()

func _get_stats_text(data: BuildingData, level: int) -> String:
    var text = ""
    
    # REFACTOR: Food больше не генерируется от зданий, только от охоты
    # if data.base_food_per_sec > 0 or data.food_per_level > 0:
    #    var val = data.base_food_per_sec + (data.food_per_level * (level - 1))
    #    text += "Food: %.1f/s\n" % val
        
    if data.base_gold_per_sec > 0 or data.gold_per_level > 0:
        var val = data.base_gold_per_sec + (data.gold_per_level * (level - 1))
        text += "Gold: %.1f/s\n" % val
        
    if data.base_passive_damage_per_sec > 0 or data.passive_damage_per_level > 0:
        var val = data.base_passive_damage_per_sec + (data.passive_damage_per_level * (level - 1))
        text += "Dmg: %.1f/s\n" % val
        
    if data.base_potion_production_cycle_sec > 0:
        text += "Potions: Every %.0fs\n" % data.base_potion_production_cycle_sec
        
    if data.base_hospital_heal_interval_sec > 0:
        text += "Heal: Every %.0fs\n" % data.base_hospital_heal_interval_sec
        
    # Global bonuses (new buildings)
    if data.global_defense_per_level > 0:
        var val = data.global_defense_per_level * level
        text += "Global Defense: +%d\n" % val
        
    if data.global_damage_percent_per_level > 0:
        var val = data.global_damage_percent_per_level * level * 100.0
        text += "Global Damage: +%.0f%%\n" % val
        
    if data.global_xp_percent_per_level > 0:
        var val = data.global_xp_percent_per_level * level * 100.0
        text += "Global XP: +%.0f%%\n" % val
        
    return text

func _on_upgrade_pressed() -> void:
    if TownCore.try_upgrade_building(building_id):
        update_info()
        # Обновляем UpgradeGrid после апгрейда
        if upgrade_grid: upgrade_grid.setup(building_id)
        # Optional: play sound
    else:
        # Failed (shouldn't happen if button disabled, but race condition possible)
        update_info()

func _on_buy_bottle_pressed() -> void:
    # town_hall removed
    return
