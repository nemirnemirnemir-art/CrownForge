extends RefCounted
class_name SmithCraftLogic

const ItemCatalogResource := preload("res://modules/inventory/item_catalog.gd")
const SmithCraftRecipesScript := preload("res://scripts/ui/town/smith/SmithCraftRecipes.gd")

const CRAFT_TIME_SEC: int = 60

var _slot_state: Array[Dictionary] = []

signal slot_changed(slot_index: int)
signal crafting_completed(slot_index: int, success: bool)

func initialize(slot_count: int) -> void:
	_slot_state.clear()
	_slot_state.resize(slot_count)
	for i in range(_slot_state.size()):
		_slot_state[i] = {
			"is_crafting": false,
			"recipe_index": -1,
			"qty_total": 0,
			"qty_left": 0,
			"sec_left": 0,
			"craft_icon_path": "",
			"pending_qty": 1,
			"pending_recipe_index": 0,
		}

func get_slot_state(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= _slot_state.size():
		return {}
	return _slot_state[slot_index]

func set_slot_state(slot_index: int, state: Dictionary) -> void:
	if slot_index < 0 or slot_index >= _slot_state.size():
		return
	_slot_state[slot_index] = state

func tick_slots() -> void:
	for i in range(_slot_state.size()):
		_tick_slot(i)

func _tick_slot(slot_index: int) -> void:
	var st: Dictionary = _slot_state[slot_index]
	var is_crafting: bool = bool(st.get("is_crafting", false))
	if not is_crafting:
		return

	var qty_left: int = int(st.get("qty_left", 0))
	if qty_left <= 0:
		st["is_crafting"] = false
		st["sec_left"] = 0
		st["craft_icon_path"] = ""
		_slot_state[slot_index] = st
		return

	var sec_left: int = int(st.get("sec_left", 0))
	if sec_left <= 0:
		sec_left = CRAFT_TIME_SEC

	sec_left -= 1
	if sec_left <= 0:
		var ok := _finish_one_item(slot_index)
		if not ok:
			st["is_crafting"] = false
			st["qty_left"] = 0
			st["qty_total"] = 0
			st["sec_left"] = 0
			st["craft_icon_path"] = ""
			_slot_state[slot_index] = st
			crafting_completed.emit(slot_index, false)
			return

		qty_left -= 1
		if qty_left > 0:
			sec_left = CRAFT_TIME_SEC
		else:
			sec_left = 0
			st["is_crafting"] = false
			st["craft_icon_path"] = ""

	st["qty_left"] = qty_left
	st["sec_left"] = sec_left
	_slot_state[slot_index] = st

func _finish_one_item(slot_index: int) -> bool:
	var st: Dictionary = _slot_state[slot_index]
	var recipe_index: int = int(st.get("recipe_index", -1))
	var recipe := SmithCraftRecipesScript.get_recipe(recipe_index)
	if recipe.is_empty():
		return false

	var item_type: int = int(recipe.get("item_type", ItemSystem.ItemType.WEAPON))

	var template := ItemCatalogResource.get_random_template(item_type)
	if template.is_empty():
		return false

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var rarity: int = ItemSystem.Rarity.UGLY
	var mult := ItemSystem.get_rarity_multiplier(rarity)
	var hp_bonus := 0
	var damage_bonus := 0

	if template.has("base_hp_min"):
		var hp_min = int(template.get("base_hp_min", 0) * mult)
		var hp_max = int(template.get("base_hp_max", hp_min) * mult)
		hp_bonus = rng.randi_range(hp_min, max(hp_min, hp_max))
	elif template.has("base_damage_min"):
		var dmg_min = int(template.get("base_damage_min", 0) * mult)
		var dmg_max = int(template.get("base_damage_max", dmg_min) * mult)
		damage_bonus = rng.randi_range(dmg_min, max(dmg_min, dmg_max))

	var id := "smith_%d" % Time.get_ticks_msec()
	var icon_path: String = str(template.get("icon_path", "res://icon.svg"))
	var item := ItemSystem.create_item(id, item_type, rarity, icon_path, hp_bonus, damage_bonus)

	if not TownCore:
		return false
	var town_inv: TownInventory = TownCore.get_town_inventory()
	if not town_inv:
		return false
	return town_inv.add_item(item)

func can_start_craft(slot_index: int, recipe_index: int, qty: int) -> bool:
	if not TownCore:
		return false
	var town_inv: TownInventory = TownCore.get_town_inventory()
	if not town_inv:
		return false

	var st: Dictionary = get_slot_state(slot_index)
	if bool(st.get("is_crafting", false)):
		return false

	if qty <= 0:
		return false

	var recipe := SmithCraftRecipesScript.get_recipe(recipe_index)
	if recipe.is_empty():
		return false

	var cost: Array = recipe.get("cost", [])
	for ing in cost:
		var id: String = str(ing.get("id", ""))
		var need: int = int(ing.get("qty", 0)) * qty
		if not town_inv.has_quantity(id, need):
			return false

	return true

func start_craft(slot_index: int, recipe_index: int, qty: int) -> bool:
	if not can_start_craft(slot_index, recipe_index, qty):
		return false

	var town_inv: TownInventory = TownCore.get_town_inventory()
	var recipe := SmithCraftRecipesScript.get_recipe(recipe_index)
	var cost: Array = recipe.get("cost", [])

	for ing in cost:
		var id: String = str(ing.get("id", ""))
		var need: int = int(ing.get("qty", 0)) * qty
		if not town_inv.try_consume(id, need):
			refund_ingredients(recipe, qty)
			return false

	var st: Dictionary = get_slot_state(slot_index)
	st["is_crafting"] = true
	st["recipe_index"] = recipe_index
	st["qty_total"] = qty
	st["qty_left"] = qty
	st["sec_left"] = CRAFT_TIME_SEC
	st["craft_icon_path"] = SmithCraftRecipesScript.get_craft_visual_path(recipe)
	_slot_state[slot_index] = st

	slot_changed.emit(slot_index)
	return true

func cancel_craft(slot_index: int) -> void:
	var st: Dictionary = get_slot_state(slot_index)
	var qty_left: int = int(st.get("qty_left", 0))
	var recipe_index: int = int(st.get("recipe_index", -1))
	var recipe := SmithCraftRecipesScript.get_recipe(recipe_index)

	if qty_left > 0 and not recipe.is_empty():
		refund_ingredients(recipe, qty_left)

	st["is_crafting"] = false
	st["recipe_index"] = -1
	st["qty_total"] = 0
	st["qty_left"] = 0
	st["sec_left"] = 0
	st["craft_icon_path"] = ""
	_slot_state[slot_index] = st

	slot_changed.emit(slot_index)

func refund_ingredients(recipe: Dictionary, qty: int) -> void:
	if not TownCore:
		return
	var town_inv: TownInventory = TownCore.get_town_inventory()
	if not town_inv:
		return

	var cost: Array = recipe.get("cost", [])
	for ing in cost:
		var id: String = str(ing.get("id", ""))
		var icon: String = str(ing.get("icon", ""))
		var base_qty: int = int(ing.get("qty", 0))
		var give: int = base_qty * qty
		if give <= 0 or id == "":
			continue
		var item := ItemSystem.create_item(id, ItemSystem.ItemType.INGREDIENT, ItemSystem.Rarity.COMMON, icon, 0, 0, give)
		town_inv.add_item(item)

func adjust_pending_qty(slot_index: int, delta: int) -> void:
	var st: Dictionary = get_slot_state(slot_index)
	if bool(st.get("is_crafting", false)):
		return
	var pending_qty: int = int(st.get("pending_qty", 1))
	st["pending_qty"] = clampi(pending_qty + delta, 1, 999)
	_slot_state[slot_index] = st
	slot_changed.emit(slot_index)

func set_pending_recipe(slot_index: int, recipe_index: int) -> void:
	var st: Dictionary = get_slot_state(slot_index)
	if bool(st.get("is_crafting", false)):
		return
	st["pending_recipe_index"] = recipe_index
	_slot_state[slot_index] = st
	slot_changed.emit(slot_index)
