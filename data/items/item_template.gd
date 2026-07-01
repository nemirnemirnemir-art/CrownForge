extends Resource
class_name ItemTemplate
## Template for item base stats and properties
## Used to generate items of specific types

## Type of item (from ItemSystem.ItemType enum)
@export var item_type: int = 0

## Base HP bonus for this item type
@export var base_hp: int = 0

## Base damage bonus for this item type
@export var base_damage: int = 0

## Base defense bonus for this item type
@export var base_defense: int = 0

## Icon path for this item type
@export var icon_path: String = "res://icon.svg"

## Item type name (for display)
@export var type_name: String = "Item"
