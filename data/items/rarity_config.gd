extends Resource
class_name RarityConfig
## Configuration for item rarity system
## Contains multipliers and colors for different rarity levels

## Rarity multipliers for item stats
@export var multipliers: Dictionary = {
	0: 1.0,    # COMMON
	1: 1.5,    # RARE
	2: 2.5,    # EPIC
	3: 5.0     # LEGENDARY
}

## Colors for rarity display
@export var colors: Dictionary = {
	0: Color(0.6, 0.6, 0.6, 1.0),  # COMMON - Gray
	1: Color(0.2, 0.5, 1.0, 1.0),  # RARE - Blue
	2: Color(0.7, 0.3, 1.0, 1.0),  # EPIC - Purple
	3: Color(1.0, 0.6, 0.2, 1.0)   # LEGENDARY - Orange
}

## Rarity names for display
@export var names: Dictionary = {
	0: "Common",
	1: "Rare",
	2: "Epic",
	3: "Legendary"
}
