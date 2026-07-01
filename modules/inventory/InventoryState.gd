extends RefCounted
class_name InventoryState

const MAX_INVENTORY_SIZE: int = 10

signal inventory_updated()
signal item_added(item: Dictionary)
signal item_removed(item: Dictionary)
signal item_equipped(hero_id: String, item: Dictionary)

var items: Array[Dictionary] = []

func init() -> void:
	items.resize(MAX_INVENTORY_SIZE)
	for i in range(MAX_INVENTORY_SIZE):
		items[i] = {}

func get_items() -> Array[Dictionary]:
	return items

func get_item_at_index(index: int) -> Dictionary:
	if index < 0 or index >= items.size():
		return {}
	return items[index]

func set_item_at_index(index: int, item: Dictionary) -> bool:
	if index < 0 or index >= items.size():
		return false
	items[index] = item
	inventory_updated.emit()
	if SaveCore: SaveCore.request_save()
	return true

func swap_items(index1: int, index2: int) -> void:
	if index1 < 0 or index1 >= items.size() or index2 < 0 or index2 >= items.size():
		return
	var temp = items[index1]
	items[index1] = items[index2]
	items[index2] = temp
	inventory_updated.emit()
	if SaveCore: SaveCore.request_save()

func add_item(item: Dictionary) -> bool:
	if ItemSystem.is_stackable(item.item_type):
		var max_stack := ItemSystem.get_max_stack_size(item.item_type)
		for i in range(items.size()):
			var existing_item := items[i]
			if existing_item.is_empty(): continue
			if existing_item.id == item.id:
				var current_qty: int = existing_item.get("quantity", 1)
				if current_qty < max_stack:
					var space := max_stack - current_qty
					var to_add: int = item.get("quantity", 1)
					if to_add <= space:
						existing_item["quantity"] = current_qty + to_add
						inventory_updated.emit()
						if SaveCore: SaveCore.request_save()
						return true
					else:
						existing_item["quantity"] = max_stack
						item["quantity"] = to_add - space
						inventory_updated.emit()

	for i in range(items.size()):
		if items[i].is_empty():
			items[i] = item
			inventory_updated.emit()
			item_added.emit(item)
			print("[PlayerInventory] Added item: %s at slot %d" % [item.id, i])
			if SaveCore: SaveCore.request_save()
			return true

	print("[PlayerInventory] Inventory full, cannot add item")
	return false

func has_empty_slot() -> bool:
	for i in range(items.size()):
		if items[i].is_empty():
			return true
	return false

func remove_item_at_index(index: int) -> void:
	if index < 0 or index >= items.size():
		return
	var item := items[index]
	if item.is_empty(): return
	items[index] = {}
	inventory_updated.emit()
	item_removed.emit(item)
	print("[PlayerInventory] Removed item at index %d" % index)
	if SaveCore:
		SaveCore.request_save()

func remove_item_by_id(id: String) -> void:
	for i in range(items.size()):
		if items[i].id == id:
			remove_item_at_index(i)
			return

func equip_item(index: int) -> void:
	if index < 0 or index >= items.size():
		return
	var item := items[index]
	var type := item.item_type
	var slot_name := _get_slot_name_for_type(type)
	if slot_name == "":
		print("[PlayerInventory] Unknown slot for item type %d" % type)
		return
	if not is_instance_valid(HeroCore):
		print("[PlayerInventory] HeroCore not found")
		return
	var heroes := HeroCore.heroes.values()
	var unlocked_heroes: Array = []
	for h in heroes:
		if not h.get("isRemoved", false) and not h.get("isDead", false):
			unlocked_heroes.append(h)
	if unlocked_heroes.is_empty():
		print("[PlayerInventory] No heroes available to equip")
		return
	var candidates_empty: Array = []
	for h in unlocked_heroes:
		var equipment: Dictionary = h.get("equipment", {})
		if not equipment.has(slot_name) or equipment[slot_name] == null:
			candidates_empty.append(h)
	if not candidates_empty.is_empty():
		var hero = candidates_empty.pick_random()
		_perform_equip(hero.id, item, slot_name)
		remove_item_at_index(index)
		return
	var candidates_weaker: Array = []
	for h in unlocked_heroes:
		var current_item = h.equipment[slot_name]
		if current_item.power <= item.power:
			candidates_weaker.append(h)
	if not candidates_weaker.is_empty():
		var hero = candidates_weaker.pick_random()
		_perform_equip(hero.id, item, slot_name)
		remove_item_at_index(index)
		return
	print("[PlayerInventory] No suitable hero found to equip item")

func _perform_equip(hero_id: String, item: Dictionary, slot_name: String) -> void:
	HeroCore.equip_item_to_hero(hero_id, item, slot_name)
	item_equipped.emit(hero_id, item)
	print("[PlayerInventory] Equipped item to hero %s in slot %s" % [hero_id, slot_name])

func _get_slot_name_for_type(type: int) -> String:
	match type:
		ItemSystem.ItemType.HELMET: return "helmet"
		ItemSystem.ItemType.ARMOR:  return "armor"
		ItemSystem.ItemType.WEAPON: return "weapon"
		ItemSystem.ItemType.RING:   return "ring"
	return ""

func get_save_data() -> Array:
	return items

func load_save_data(data: Array) -> void:
	items.resize(MAX_INVENTORY_SIZE)
	for i in range(MAX_INVENTORY_SIZE):
		items[i] = {}
	for i in range(data.size()):
		if i >= MAX_INVENTORY_SIZE: break
		var item_data = data[i]
		if item_data is Dictionary and not item_data.is_empty():
			var reconstructed := ItemSystem.create_item(
				item_data.get("id", "unknown"),
				int(item_data.get("item_type", 0)),
				int(item_data.get("rarity", 0)),
				item_data.get("icon_path", ""),
				int(item_data.get("hp_bonus", 0)),
				int(item_data.get("damage_bonus", 0))
			)
			if item_data.has("quantity"):
				reconstructed["quantity"] = item_data["quantity"]
			items[i] = reconstructed
	inventory_updated.emit()

func reset() -> void:
	items.resize(MAX_INVENTORY_SIZE)
	for i in range(MAX_INVENTORY_SIZE):
		items[i] = {}
	inventory_updated.emit()
