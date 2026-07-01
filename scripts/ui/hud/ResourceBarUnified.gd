extends PanelContainer

## Unified Resource Bar - all 13 resources in one row

@export_group("Primary Resource Icons")
@export var water_icon: Texture2D
@export var wheat_icon: Texture2D
@export var wood_icon: Texture2D
@export var clay_icon: Texture2D
@export var iron_ore_icon: Texture2D
@export var crystal_icon: Texture2D
@export var grapes_icon: Texture2D
@export var wine_icon: Texture2D
@export var gold_icon: Texture2D

@export_group("Secondary Resource Icons")
@export var steel_icon: Texture2D
@export var flour_icon: Texture2D
@export var meat_icon: Texture2D
@export var oil_icon: Texture2D

@export_group("Value Background")
@export var value_bg_texture: Texture2D

func _ready() -> void:
	_assign_icons()
	_assign_value_backgrounds()

func _assign_icons() -> void:
	var hbox = get_node_or_null("HBox")
	if not hbox:
		push_error("[ResourceBarUnified] HBox not found!")
		return
	
	# Primary resources
	_set_icon(hbox, "Resource_water", water_icon)
	_set_icon(hbox, "Resource_wheat", wheat_icon)
	_set_icon(hbox, "Resource_wood", wood_icon)
	_set_icon(hbox, "Resource_clay", clay_icon)
	_set_icon(hbox, "Resource_iron_ore", iron_ore_icon)
	_set_icon(hbox, "Resource_crystal", crystal_icon)
	_set_icon(hbox, "Resource_grapes", grapes_icon)
	_set_icon(hbox, "Resource_wine", wine_icon)
	_set_icon(hbox, "Resource_gold", gold_icon)
	
	# Secondary resources
	_set_icon(hbox, "Resource_steel", steel_icon)
	_set_icon(hbox, "Resource_flour", flour_icon)
	_set_icon(hbox, "Resource_meat", meat_icon)
	_set_icon(hbox, "Resource_oil", oil_icon)

func _set_icon(parent: Node, resource_name: String, texture: Texture2D) -> void:
	var resource_container = parent.get_node_or_null(resource_name)
	if not resource_container:
		return
	
	var icon_rect = resource_container.get_node_or_null("Icon")
	if icon_rect and texture:
		icon_rect.texture = texture

func _assign_value_backgrounds() -> void:
	if value_bg_texture == null:
		return
	var hbox = get_node_or_null("HBox")
	if not hbox:
		return
	for child in hbox.get_children():
		if child == null:
			continue
		var bg := child.get_node_or_null("ValueBg") as TextureRect
		if bg:
			bg.texture = value_bg_texture
