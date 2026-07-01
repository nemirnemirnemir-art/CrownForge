extends Resource
class_name SmithCraftRecipes

const HELMET_ICON := "res://assets/items/equipment/helmet.png"
const ARMOR_ICON := "res://assets/items/equipment/armor.png"
const WEAPON_ICON := "res://assets/items/equipment/sword.png"
const RING_ICON := "res://assets/items/equipment/ring.png"

const CRAFT_VISUALS := {
	"wh": HELMET_ICON,
	"wa": ARMOR_ICON,
	"ww": WEAPON_ICON,
	"bh": HELMET_ICON,
	"ba": ARMOR_ICON,
	"bw": WEAPON_ICON,
	"wbh": HELMET_ICON,
	"wba": ARMOR_ICON,
	"wbw": WEAPON_ICON,
}

const ING_WOOD_ID: String = "ingredient_wood_scrap"
const ING_WOOD_ICON: String = "res://assets/items/ingredients/wood_scrap.png"
const ING_SWORD_ID: String = "ingredient_sword"
const ING_SWORD_ICON: String = "res://assets/items/ingredients/crypt/sword_ing.png"

const RECIPES: Array[Dictionary] = [
	{
		"id": "wh",
		"display_name": "Wooden Helmet",
		"icon_recipe": HELMET_ICON,
		"item_type": ItemSystem.ItemType.HELMET,
		"cost": [{"id": ING_WOOD_ID, "qty": 1, "icon": ING_WOOD_ICON}],
	},
	{
		"id": "wa",
		"display_name": "Wooden Armor",
		"icon_recipe": ARMOR_ICON,
		"item_type": ItemSystem.ItemType.ARMOR,
		"cost": [{"id": ING_WOOD_ID, "qty": 1, "icon": ING_WOOD_ICON}],
	},
	{
		"id": "ww",
		"display_name": "Wooden Weapon",
		"icon_recipe": WEAPON_ICON,
		"item_type": ItemSystem.ItemType.WEAPON,
		"cost": [{"id": ING_SWORD_ID, "qty": 1, "icon": ING_SWORD_ICON}],
	},
	{
		"id": "bh",
		"display_name": "Bone Helmet",
		"icon_recipe": HELMET_ICON,
		"item_type": ItemSystem.ItemType.HELMET,
		"cost": [{"id": ING_WOOD_ID, "qty": 1, "icon": ING_WOOD_ICON}],
	},
	{
		"id": "ba",
		"display_name": "Bone Armor",
		"icon_recipe": ARMOR_ICON,
		"item_type": ItemSystem.ItemType.ARMOR,
		"cost": [{"id": ING_WOOD_ID, "qty": 1, "icon": ING_WOOD_ICON}],
	},
	{
		"id": "bw",
		"display_name": "Bone Weapon",
		"icon_recipe": WEAPON_ICON,
		"item_type": ItemSystem.ItemType.WEAPON,
		"cost": [{"id": ING_SWORD_ID, "qty": 1, "icon": ING_SWORD_ICON}],
	},
	{
		"id": "wbh",
		"display_name": "WooBon Helmet",
		"icon_recipe": HELMET_ICON,
		"item_type": ItemSystem.ItemType.HELMET,
		"cost": [{"id": ING_WOOD_ID, "qty": 1, "icon": ING_WOOD_ICON}],
	},
	{
		"id": "wba",
		"display_name": "WooBon Armor",
		"icon_recipe": ARMOR_ICON,
		"item_type": ItemSystem.ItemType.ARMOR,
		"cost": [{"id": ING_WOOD_ID, "qty": 1, "icon": ING_WOOD_ICON}],
	},
	{
		"id": "wbw",
		"display_name": "WooBon Weapon",
		"icon_recipe": WEAPON_ICON,
		"item_type": ItemSystem.ItemType.WEAPON,
		"cost": [{"id": ING_SWORD_ID, "qty": 1, "icon": ING_SWORD_ICON}],
	},
]

static func get_recipe(index: int) -> Dictionary:
	if index < 0 or index >= RECIPES.size():
		return {}
	return RECIPES[index]

static func get_recipe_count() -> int:
	return RECIPES.size()

static func get_craft_visual_path(recipe: Dictionary) -> String:
	var recipe_id := str(recipe.get("id", ""))
	if recipe_id != "":
		var override_path: String = str(CRAFT_VISUALS.get(recipe_id, ""))
		if override_path != "":
			return override_path
	return str(recipe.get("icon_recipe", ""))
