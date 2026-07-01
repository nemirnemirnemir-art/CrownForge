extends RefCounted
class_name TownAlchemyCraft

const MAX_QUEUE: int = 10
const DEFAULT_CRAFT_TIME_SEC: int = 300

const INGREDIENT_ICONS := {
	"ingredient_hollow_bottle": "res://assets/items/ingredients/hollow_bottle.png",
	"ingredient_bat_wing": "res://assets/items/ingredients/bat_wing.png",
	"ingredient_slime_goo": "res://assets/items/ingredients/slime_goo.png",
	"ingredient_mushroom_cap": "res://assets/items/ingredients/mushroom_cap.png",
}

const POTION_DEFS := {
	"minor_heal": {
		"display_name": "Minor Health Elixir",
		"description": "Instantly heal for 15 hp",
		"icon_inventory": "res://assets/ui/craft_panel/minor_heal_inventory.png",
		"ingredients": [
			{"id": "ingredient_hollow_bottle", "qty": 1},
			{"id": "ingredient_bat_wing", "qty": 5},
			{"id": "ingredient_slime_goo", "qty": 2},
		],
	},
	"minor_block": {
		"display_name": "Minor Block Elixir",
		"icon_inventory": "res://assets/ui/craft_panel/block_inventory.png",
		"ingredients": [
			{"id": "ingredient_hollow_bottle", "qty": 1},
			{"id": "ingredient_bat_wing", "qty": 5},
			{"id": "ingredient_mushroom_cap", "qty": 2},
		],
	},
}

var _inventory: TownInventory
var _buildings: TownBuildings

var _queue: Array[Dictionary] = []
var _active_start_unix: int = 0
var _last_update_unix: int = 0

func initialize(inventory: TownInventory, buildings: TownBuildings) -> void:
	_inventory = inventory
	_buildings = buildings

func get_potion_defs() -> Dictionary:
	return POTION_DEFS

func get_queue() -> Array[Dictionary]:
	return _queue

func update(now_unix: int = -1) -> bool:
	return _update_progress(now_unix) > 0

func get_active_remaining_sec(now_unix: int = -1) -> int:
	update(now_unix)
	if _queue.is_empty():
		return 0

	var now: int = now_unix
	if now < 0:
		now = int(Time.get_unix_time_from_system())

	var elapsed: int = max(0, now - _active_start_unix)
	return max(0, DEFAULT_CRAFT_TIME_SEC - elapsed)

func try_enqueue(potion_id: String, now_unix: int = -1) -> bool:
	update(now_unix)

	if not POTION_DEFS.has(potion_id):
		return false

	if _queue.size() >= MAX_QUEUE:
		return false

	if not _buildings:
		return false

	if _buildings.get_building_level("alchemist") < 1:
		return false

	var recipe: Dictionary = POTION_DEFS[potion_id]
	var ingredients: Array = recipe.get("ingredients", [])

	for ing in ingredients:
		var id: String = str(ing.get("id", ""))
		var qty: int = int(ing.get("qty", 0))
		if id == "" or qty <= 0:
			return false
		if not _inventory.has_quantity(id, qty):
			return false

	var consumed: Array[Dictionary] = []
	for ing in ingredients:
		var id2: String = str(ing.get("id", ""))
		var qty2: int = int(ing.get("qty", 0))
		if not _inventory.try_consume(id2, qty2):
			for c in consumed:
				var rid: String = str(c.get("id", ""))
				var rqty: int = int(c.get("qty", 0))
				var icon: String = str(INGREDIENT_ICONS.get(rid, ""))
				if rid == "" or rqty <= 0:
					continue
				var refund := ItemSystem.create_item(
					rid,
					ItemSystem.ItemType.INGREDIENT,
					ItemSystem.Rarity.COMMON,
					icon,
					0,
					0,
					rqty
				)
				_inventory.add_item(refund)
			return false

		consumed.append({"id": id2, "qty": qty2})

	_queue.append({"potion_id": potion_id})

	var now: int = now_unix
	if now < 0:
		now = int(Time.get_unix_time_from_system())

	if _queue.size() == 1:
		_active_start_unix = now

	return true

func try_cancel(index: int, now_unix: int = -1) -> bool:
	update(now_unix)

	if index < 0 or index >= _queue.size():
		return false

	var entry: Dictionary = _queue[index]
	var potion_id: String = str(entry.get("potion_id", ""))
	if not POTION_DEFS.has(potion_id):
		_queue.remove_at(index)
		if index == 0:
			_reset_active_start(now_unix)
		return true

	_refund_ingredients(potion_id)
	_queue.remove_at(index)

	if index == 0:
		_reset_active_start(now_unix)

	return true

func _reset_active_start(now_unix: int) -> void:
	if _queue.is_empty():
		_active_start_unix = 0

		return

	var now: int = now_unix
	if now < 0:
		now = int(Time.get_unix_time_from_system())

	_active_start_unix = now

func _update_progress(now_unix: int = -1) -> int:
	if _queue.is_empty():
		return 0

	var now: int = now_unix
	if now < 0:
		now = int(Time.get_unix_time_from_system())

	if _active_start_unix <= 0:
		_active_start_unix = now

	if now <= _last_update_unix:
		return 0

	_last_update_unix = now

	var elapsed: int = max(0, now - _active_start_unix)
	if elapsed < DEFAULT_CRAFT_TIME_SEC:
		return 0

	var completed_count: int = int(floor(float(elapsed) / float(DEFAULT_CRAFT_TIME_SEC)))
	var completed_processed: int = 0

	for _i in range(completed_count):
		if _queue.is_empty():
			break
		var completed: Dictionary = _queue.pop_front()
		var potion_id: String = str(completed.get("potion_id", ""))
		_grant_potion(potion_id)
		_active_start_unix += DEFAULT_CRAFT_TIME_SEC
		completed_processed += 1

	if _queue.is_empty():
		_active_start_unix = 0

	return completed_processed

func _grant_potion(potion_id: String) -> void:
	if not POTION_DEFS.has(potion_id):
		return

	var def: Dictionary = POTION_DEFS[potion_id]
	var icon: String = str(def.get("icon_inventory", ""))
	var item_id: String = "potion_%s" % potion_id

	var item := ItemSystem.create_item(
		item_id,
		ItemSystem.ItemType.INGREDIENT,
		ItemSystem.Rarity.COMMON,
		icon,
		0,
		0,
		1
	)
	_inventory.add_item(item)

func _refund_ingredients(potion_id: String) -> void:
	if not POTION_DEFS.has(potion_id):
		return

	var recipe: Dictionary = POTION_DEFS[potion_id]
	var ingredients: Array = recipe.get("ingredients", [])

	for ing in ingredients:
		var id: String = str(ing.get("id", ""))
		var qty: int = int(ing.get("qty", 0))
		var icon: String = str(INGREDIENT_ICONS.get(id, ""))
		if id == "" or qty <= 0:
			continue

		var item := ItemSystem.create_item(
			id,
			ItemSystem.ItemType.INGREDIENT,
			ItemSystem.Rarity.COMMON,
			icon,
			0,
			0,
			qty
		)
		_inventory.add_item(item)

func reset() -> void:
	_queue = []
	_active_start_unix = 0
	_last_update_unix = 0


func get_save_data() -> Dictionary:
	return {
		"queue": _queue,
		"active_start_unix": _active_start_unix,
		"last_update_unix": _last_update_unix,
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("queue") and data["queue"] is Array:
		var raw: Array = data["queue"]
		var typed: Array[Dictionary] = []
		typed.resize(raw.size())
		for i in range(raw.size()):
			if raw[i] is Dictionary:
				typed[i] = raw[i]
			else:
				typed[i] = {}
		_queue = typed
	else:
		_queue = []

	_active_start_unix = int(data.get("active_start_unix", 0))
	_last_update_unix = int(data.get("last_update_unix", 0))

	_update_progress(int(Time.get_unix_time_from_system()))
