extends RefCounted
class_name SmithState

## Handles crafting state, ticking, and inventory transactions for the Smith

const ItemCatalogResource := preload("res://modules/inventory/item_catalog.gd")
const _CRAFT_TIME_SEC: int = 60

var slot_state: Array[Dictionary] = []
var selected_slot_index: int = 0
var selected_recipe_index: int = 0
var recipes_scroll: int = 0

func setup(slot_count: int) -> void:
    slot_state.clear()
    slot_state.resize(slot_count)
    for i in range(slot_state.size()):
        slot_state[i] = {
            "is_crafting": false,
            "recipe_index": -1,
            "qty_total": 0,
            "qty_left": 0,
            "sec_left": 0,
            "craft_icon_path": "",
            "pending_qty": 1,
            "pending_recipe_index": 0,
        }

func tick_slots(recipes: Array) -> void:
    for i in range(slot_state.size()):
        var st: Dictionary = slot_state[i]
        var is_crafting: bool = bool(st.get("is_crafting", false))
        if not is_crafting:
            continue

        var qty_left: int = int(st.get("qty_left", 0))
        if qty_left <= 0:
            st["is_crafting"] = false
            st["sec_left"] = 0
            st["craft_icon_path"] = ""
            slot_state[i] = st
            continue

        var sec_left: int = int(st.get("sec_left", 0))
        if sec_left <= 0:
            sec_left = _CRAFT_TIME_SEC

        sec_left -= 1
        if sec_left <= 0:
            var ok := _finish_one_item(i, recipes)
            if not ok:
                st["is_crafting"] = false
                st["qty_left"] = 0
                st["qty_total"] = 0
                st["sec_left"] = 0
                st["craft_icon_path"] = ""
                slot_state[i] = st
                continue

            qty_left -= 1
            if qty_left > 0:
                sec_left = _CRAFT_TIME_SEC
            else:
                sec_left = 0
                st["is_crafting"] = false
                st["craft_icon_path"] = ""

        st["qty_left"] = qty_left
        st["sec_left"] = sec_left
        slot_state[i] = st

func _finish_one_item(slot_index: int, recipes: Array) -> bool:
    var st: Dictionary = slot_state[slot_index]
    var recipe_index: int = int(st.get("recipe_index", -1))
    if recipe_index < 0 or recipe_index >= recipes.size():
        return false

    var recipe: Dictionary = recipes[recipe_index]
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

    var eng := Engine.get_main_loop() as SceneTree
    var time_msec = Time.get_ticks_msec()
    var id := "smith_%d" % time_msec
    var icon_path: String = str(template.get("icon_path", "res://icon.svg"))
    var item := ItemSystem.create_item(id, item_type, rarity, icon_path, hp_bonus, damage_bonus)

    var town_core = eng.root.get_node_or_null("/root/TownCore") if eng else null
    if not town_core:
        return false
    var town_inv = town_core.get_town_inventory()
    if not town_inv:
        return false
    return town_inv.add_item(item)

func can_start_selected(recipes: Array) -> bool:
    var eng := Engine.get_main_loop() as SceneTree
    var town_core = eng.root.get_node_or_null("/root/TownCore") if eng else null
    if not town_core:
        return false
    var town_inv = town_core.get_town_inventory()
    if not town_inv:
        return false

    var st: Dictionary = slot_state[selected_slot_index]
    if bool(st.get("is_crafting", false)):
        return false

    var pending_qty: int = int(st.get("pending_qty", 1))
    if pending_qty <= 0:
        return false

    var recipe: Dictionary = recipes[selected_recipe_index]
    var cost: Array = recipe.get("cost", [])
    for ing in cost:
        var id: String = str(ing.get("id", ""))
        var need: int = int(ing.get("qty", 0)) * pending_qty
        if not town_inv.has_quantity(id, need):
            return false

    return true

func refund_ingredients(recipe: Dictionary, qty: int) -> void:
    var eng := Engine.get_main_loop() as SceneTree
    var town_core = eng.root.get_node_or_null("/root/TownCore") if eng else null
    if not town_core:
        return
    var town_inv = town_core.get_town_inventory()
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

func start_crafting(recipes: Array, get_visual_func: Callable) -> void:
    if not can_start_selected(recipes):
        return

    var eng := Engine.get_main_loop() as SceneTree
    var town_core = eng.root.get_node_or_null("/root/TownCore") if eng else null
    var town_inv = town_core.get_town_inventory()
    var st: Dictionary = slot_state[selected_slot_index]
    var pending_qty: int = int(st.get("pending_qty", 1))
    var recipe: Dictionary = recipes[selected_recipe_index]
    var cost: Array = recipe.get("cost", [])

    for ing in cost:
        var id: String = str(ing.get("id", ""))
        var need: int = int(ing.get("qty", 0)) * pending_qty
        if not town_inv.try_consume(id, need):
            refund_ingredients(recipe, pending_qty)
            return

    st["is_crafting"] = true
    st["recipe_index"] = selected_recipe_index
    st["qty_total"] = pending_qty
    st["qty_left"] = pending_qty
    st["sec_left"] = _CRAFT_TIME_SEC
    st["craft_icon_path"] = get_visual_func.call(recipe)
    slot_state[selected_slot_index] = st

func cancel_crafting(slot_index: int, recipes: Array) -> void:
    if slot_index < 0 or slot_index >= slot_state.size():
        return

    var st: Dictionary = slot_state[slot_index]
    var qty_left: int = int(st.get("qty_left", 0))
    var recipe_index: int = int(st.get("recipe_index", -1))

    if qty_left > 0 and recipe_index >= 0 and recipe_index < recipes.size():
        refund_ingredients(recipes[recipe_index], qty_left)

    st["is_crafting"] = false
    st["recipe_index"] = -1
    st["qty_total"] = 0
    st["qty_left"] = 0
    st["sec_left"] = 0
    st["craft_icon_path"] = ""
