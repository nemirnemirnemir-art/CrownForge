extends RefCounted
class_name ItemCatalog

## Catalog of item templates for generation

## Equipment visuals are intentionally unified for now.
## Runtime item logic still rolls many templates/stats, but each equipment class shares one icon.
const PLACEHOLDER_ICON = "res://icon.svg" # Fallback

const HELMET_ICON := "res://assets/items/equipment/helmet.png"
const ARMOR_ICON := "res://assets/items/equipment/armor.png"
const WEAPON_ICON := "res://assets/items/equipment/sword.png"
const RING_ICON := "res://assets/items/equipment/ring.png"

## Helmets
const HELMETS: Array = [
	{"icon_path": HELMET_ICON, "base_hp_min": 1, "base_hp_max": 5},
	{"icon_path": HELMET_ICON, "base_hp_min": 2, "base_hp_max": 6},
	{"icon_path": HELMET_ICON, "base_hp_min": 1, "base_hp_max": 5},
	{"icon_path": HELMET_ICON, "base_hp_min": 2, "base_hp_max": 6},
	{"icon_path": HELMET_ICON, "base_hp_min": 3, "base_hp_max": 7},
	{"icon_path": HELMET_ICON, "base_hp_min": 1, "base_hp_max": 5},
	{"icon_path": HELMET_ICON, "base_hp_min": 2, "base_hp_max": 6},
	{"icon_path": HELMET_ICON, "base_hp_min": 3, "base_hp_max": 7},
	{"icon_path": HELMET_ICON, "base_hp_min": 4, "base_hp_max": 8},
	{"icon_path": HELMET_ICON, "base_hp_min": 1, "base_hp_max": 5},
	{"icon_path": HELMET_ICON, "base_hp_min": 2, "base_hp_max": 6},
	{"icon_path": HELMET_ICON, "base_hp_min": 3, "base_hp_max": 7},
	{"icon_path": HELMET_ICON, "base_hp_min": 4, "base_hp_max": 8},
	{"icon_path": HELMET_ICON, "base_hp_min": 5, "base_hp_max": 9},
	{"icon_path": HELMET_ICON, "base_hp_min": 1, "base_hp_max": 5},
	{"icon_path": HELMET_ICON, "base_hp_min": 2, "base_hp_max": 6},
	{"icon_path": HELMET_ICON, "base_hp_min": 3, "base_hp_max": 7},
	{"icon_path": HELMET_ICON, "base_hp_min": 4, "base_hp_max": 8},
	{"icon_path": HELMET_ICON, "base_hp_min": 5, "base_hp_max": 9},
	{"icon_path": HELMET_ICON, "base_hp_min": 1, "base_hp_max": 5},
	{"icon_path": HELMET_ICON, "base_hp_min": 2, "base_hp_max": 6},
	{"icon_path": HELMET_ICON, "base_hp_min": 3, "base_hp_max": 7},
	{"icon_path": HELMET_ICON, "base_hp_min": 4, "base_hp_max": 8},
	{"icon_path": HELMET_ICON, "base_hp_min": 5, "base_hp_max": 9},
	{"icon_path": HELMET_ICON, "base_hp_min": 1, "base_hp_max": 5},
	{"icon_path": HELMET_ICON, "base_hp_min": 2, "base_hp_max": 6},
	{"icon_path": HELMET_ICON, "base_hp_min": 3, "base_hp_max": 7},
	{"icon_path": HELMET_ICON, "base_hp_min": 4, "base_hp_max": 8},
	{"icon_path": HELMET_ICON, "base_hp_min": 5, "base_hp_max": 9},
	{"icon_path": HELMET_ICON, "base_hp_min": 1, "base_hp_max": 5}
]

## Armors
const ARMORS: Array = [
	{
		"icon_path": ARMOR_ICON,
		"base_hp_min": 2,
		"base_hp_max": 8
	},
	{
		"icon_path": ARMOR_ICON,
		"base_hp_min": 3,
		"base_hp_max": 10
	}
]

## Weapons
const WEAPONS: Array = [
	{
		"icon_path": WEAPON_ICON,
		"base_damage_min": 1,
		"base_damage_max": 3
	},
	{
		"icon_path": WEAPON_ICON,
		"base_damage_min": 2,
		"base_damage_max": 4
	}
]

## Rings
const RINGS: Array = [
	{"icon_path": RING_ICON, "base_damage_min": 1, "base_damage_max": 2},
	{"icon_path": RING_ICON, "base_damage_min": 1, "base_damage_max": 3},
	{"icon_path": RING_ICON, "base_damage_min": 2, "base_damage_max": 4},
	{"icon_path": RING_ICON, "base_damage_min": 1, "base_damage_max": 2},
	{"icon_path": RING_ICON, "base_damage_min": 2, "base_damage_max": 3},
	{"icon_path": RING_ICON, "base_damage_min": 1, "base_damage_max": 3},
	{"icon_path": RING_ICON, "base_damage_min": 2, "base_damage_max": 4},
	{"icon_path": RING_ICON, "base_damage_min": 3, "base_damage_max": 5},
	{"icon_path": RING_ICON, "base_damage_min": 1, "base_damage_max": 2},
	{"icon_path": RING_ICON, "base_damage_min": 2, "base_damage_max": 3},
	{"icon_path": RING_ICON, "base_damage_min": 1, "base_damage_max": 3},
	{"icon_path": RING_ICON, "base_damage_min": 2, "base_damage_max": 4},
	{"icon_path": RING_ICON, "base_damage_min": 3, "base_damage_max": 5},
	{"icon_path": RING_ICON, "base_damage_min": 1, "base_damage_max": 2},
	{"icon_path": RING_ICON, "base_damage_min": 2, "base_damage_max": 3},
	{"icon_path": RING_ICON, "base_damage_min": 1, "base_damage_max": 3},
	{"icon_path": RING_ICON, "base_damage_min": 2, "base_damage_max": 4},
	{"icon_path": RING_ICON, "base_damage_min": 3, "base_damage_max": 5},
	{"icon_path": RING_ICON, "base_damage_min": 1, "base_damage_max": 2},
	{"icon_path": RING_ICON, "base_damage_min": 2, "base_damage_max": 3},
	{"icon_path": RING_ICON, "base_damage_min": 1, "base_damage_max": 3},
	{"icon_path": RING_ICON, "base_damage_min": 2, "base_damage_max": 4},
	{"icon_path": RING_ICON, "base_damage_min": 3, "base_damage_max": 5},
	{"icon_path": RING_ICON, "base_damage_min": 1, "base_damage_max": 2},
	{"icon_path": RING_ICON, "base_damage_min": 2, "base_damage_max": 3},
	{"icon_path": RING_ICON, "base_damage_min": 1, "base_damage_max": 3},
	{"icon_path": RING_ICON, "base_damage_min": 2, "base_damage_max": 4},
	{"icon_path": RING_ICON, "base_damage_min": 3, "base_damage_max": 5},
	{"icon_path": RING_ICON, "base_damage_min": 1, "base_damage_max": 2},
	{"icon_path": RING_ICON, "base_damage_min": 2, "base_damage_max": 3}
]

## Helper to get a random template for a type
static func get_random_template(type: int) -> Dictionary:
	var list: Array = []
	match type:
		ItemSystem.ItemType.HELMET: list = HELMETS
		ItemSystem.ItemType.ARMOR: list = ARMORS
		ItemSystem.ItemType.WEAPON: list = WEAPONS
		ItemSystem.ItemType.RING: list = RINGS
	
	if list.is_empty():
		return {}
		
	return list.pick_random()
