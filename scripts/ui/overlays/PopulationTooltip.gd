extends PanelContainer

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

@onready var cost_label: Label = $VBox/PriceHBox/CostLabel
@onready var wood_icon: TextureRect = $VBox/PriceHBox/WoodIcon

func _population_core() -> Node:
    return get_node_or_null("/root/PopulationCore")

func _resource_core() -> Node:
    return get_node_or_null("/root/ResourceCore")

func _ready() -> void:
    if wood_icon:
        var tex := PathRegistryScript.load_resource_icon("wood", {"wood": "wood_1"})
        if tex:
            wood_icon.texture = tex
            wood_icon.visible = true
    if wood_icon:
        wood_icon.custom_minimum_size = Vector2(50, 50)
    update_info()

func update_info() -> void:
    var population_core := _population_core()
    var resource_core := _resource_core()
    if population_core == null or resource_core == null:
        return

    var cost = population_core.get_next_upgrade_cost()
    var current = resource_core.get_resource(population_core.RESOURCE_WOOD)

    cost_label.text = "%d/%d" % [current, cost]
    cost_label.add_theme_font_size_override("font_size", 32)

    # Color red if can't afford
    if current < cost:
        cost_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
    else:
        cost_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
