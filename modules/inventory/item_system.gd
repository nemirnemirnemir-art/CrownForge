extends RefCounted
class_name ItemSystem

## Core definitions for the Item System

## Item Types
enum ItemType {
	HELMET,
	ARMOR,
	WEAPON,
	RING,
	INGREDIENT,
	ACCESSORY,
}

## Item Rarities
enum Rarity {
	UGLY,
	COMMON,
	NORMAL,
	EPIC,
	LEGENDARY,
	COSMIC,
	GOD,
}

## Rarity configuration (loaded from Resource or fallback)
static var _rarity_config: RarityConfig = null

## Get the rarity configuration resource
static func get_rarity_config() -> RarityConfig:
	if _rarity_config == null:
		# Try to load from Resource file
		if ResourceLoader.exists("res://data/items/rarity_config.tres"):
			_rarity_config = load("res://data/items/rarity_config.tres")
		else:
			# Fallback: create default config
			_rarity_config = RarityConfig.new()
			# Use hardcoded values as fallback
			_rarity_config.multipliers = {
				Rarity.UGLY: 1.0,
				Rarity.COMMON: 2.0,
				Rarity.NORMAL: 3.0,
				Rarity.EPIC: 3.0,
				Rarity.LEGENDARY: 4.0,
				Rarity.COSMIC: 5.0,
				Rarity.GOD: 5.0,
			}
			_rarity_config.colors = {
				Rarity.UGLY: Color("8B4513"),
				Rarity.COMMON: Color("808080"),
				Rarity.NORMAL: Color("F5F5F5"),
				Rarity.EPIC: Color("800080"),
				Rarity.LEGENDARY: Color("FFD700"),
				Rarity.COSMIC: Color("00FFFF"),
				Rarity.GOD: Color("FF4500"),
			}
			_rarity_config.names = {
				Rarity.UGLY: "Ugly",
				Rarity.COMMON: "Common",
				Rarity.NORMAL: "Normal",
				Rarity.EPIC: "Epic",
				Rarity.LEGENDARY: "Legendary",
				Rarity.COSMIC: "Cosmic",
				Rarity.GOD: "God",
			}
	
	return _rarity_config

## Get rarity multiplier
static func get_rarity_multiplier(rarity: Rarity) -> float:
	return get_rarity_config().multipliers.get(rarity, 1.0)

## Get rarity color
static func get_rarity_color(rarity: Rarity) -> Color:
	return get_rarity_config().colors.get(rarity, Color.WHITE)

## Get rarity name
static func get_rarity_name(rarity: Rarity) -> String:
	return get_rarity_config().names.get(rarity, "Unknown")

## Item Structure Helper
## Creates a new dictionary representing an item
static func create_item(
	id: String,
	type: ItemType,
	rarity: Rarity,
	icon_path: String,
	hp_bonus: int = 0,
	damage_bonus: int = 0,
	quantity: int = 1
) -> Dictionary:
	
	var power: int = (damage_bonus * 5) + (hp_bonus * 1)
	
	return {
		"id": id,
		"item_type": type,
		"rarity": rarity,
		"icon_path": icon_path,
		"hp_bonus": hp_bonus,
		"damage_bonus": damage_bonus,
		"power": power,
		"quantity": quantity
	}

## Get string name for ItemType
static func get_type_name(type: ItemType) -> String:
	match type:
		ItemType.HELMET: return "Helmet"
		ItemType.ARMOR: return "Armor"
		ItemType.WEAPON: return "Weapon"
		ItemType.RING: return "Ring"
		ItemType.INGREDIENT: return "Ingredient"
		ItemType.ACCESSORY: return "Accessory"
		_: return "Unknown"

static func is_stackable(type: ItemType) -> bool:
	return type == ItemType.INGREDIENT

static func get_max_stack_size(type: ItemType) -> int:
	if type == ItemType.INGREDIENT:
		return 50
	return 1
