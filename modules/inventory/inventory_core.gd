extends Node
## InventoryCore - Autoload singleton (no class_name needed)
## Managing player inventory and item logic

## Constants
const MAX_INVENTORY_SIZE: int = 10
const DROP_CHANCE: float = 1.0 # 100% for testing
const RARE_DROP_CHANCE: float = 0.35 # 35% chance for non-UGLY

## Signals
signal inventory_updated()
signal item_added(item: Dictionary)
signal item_removed(item: Dictionary)
signal item_equipped(hero_id: String, item: Dictionary)

## State
var items: Array[Dictionary] = []

var _loot_generator: LootGenerator = LootGenerator.new()

func _ready() -> void:
	print("[PlayerInventory] Initialized")
	# Initialize fixed slots
	items.resize(MAX_INVENTORY_SIZE)
	for i in range(MAX_INVENTORY_SIZE):
		items[i] = {}

## --- Inventory Management ---

## Get all items
func get_items() -> Array[Dictionary]:
	return items

## Get item at index
func get_item_at_index(index: int) -> Dictionary:
	if index < 0 or index >= items.size():
		return {}
	return items[index]

## Set item at index (for drag & drop)
func set_item_at_index(index: int, item: Dictionary) -> bool:
	if index < 0 or index >= items.size():
		return false
	items[index] = item
	inventory_updated.emit()
	if SaveCore: SaveCore.request_save()
	return true

## Swap items (for drag & drop)
func swap_items(index1: int, index2: int) -> void:
	if index1 < 0 or index1 >= items.size() or index2 < 0 or index2 >= items.size():
		return
	var temp = items[index1]
	items[index1] = items[index2]
	items[index2] = temp
	inventory_updated.emit()
	if SaveCore: SaveCore.request_save()

## Add item to inventory
func add_item(item: Dictionary) -> bool:
	# 1. Try to stack if stackable
	if ItemSystem.is_stackable(item.item_type):
		var max_stack = ItemSystem.get_max_stack_size(item.item_type)
		
		# Find existing stacks of same item
		for i in range(items.size()):
			var existing_item = items[i]
			if existing_item.is_empty(): continue
			
			if existing_item.id == item.id: 
				var current_qty = existing_item.get("quantity", 1)
				if current_qty < max_stack:
					var space = max_stack - current_qty
					var to_add = item.get("quantity", 1)
					
					if to_add <= space:
						existing_item["quantity"] = current_qty + to_add
						inventory_updated.emit()
						if SaveCore: SaveCore.request_save()
						return true
					else:
						# Fill this stack and continue with remainder
						existing_item["quantity"] = max_stack
						item["quantity"] = to_add - space
						inventory_updated.emit()
	
	# 2. Add to first empty slot
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
	
## Remove item by index
func remove_item_at_index(index: int) -> void:
	if index < 0 or index >= items.size():
		return
	
	var item = items[index]
	if item.is_empty(): return
	
	items[index] = {}
	inventory_updated.emit()
	item_removed.emit(item)
	print("[PlayerInventory] Removed item at index %d" % index)
	
	# ✅ Автоматическое сохранение при удалении предмета
	if SaveCore:
		SaveCore.request_save()

## Remove item by ID
func remove_item_by_id(id: String) -> void:
	for i in range(items.size()):
		if items[i].id == id:
			remove_item_at_index(i)
			return

## Try to drop items from enemy
func try_drop_from_enemy(mob_type: String, position: Vector2) -> void:
	_loot_generator.try_drop_from_enemy(self, mob_type, position)


## --- Equipment Logic ---

## Equip item from inventory to a hero
func equip_item(index: int) -> void:
	if index < 0 or index >= items.size():
		return
	
	var item = items[index]
	var type = item.item_type
	var slot_name = _get_slot_name_for_type(type)
	
	if slot_name == "":
		print("[PlayerInventory] Unknown slot for item type %d" % type)
		return
	
	# 1. Find unlocked heroes
	# We need to access HeroCore.heroes directly or via a getter
	# Assuming HeroCore is available as autoload
	if not is_instance_valid(HeroCore):
		print("[PlayerInventory] HeroCore not found")
		return
		
	var heroes = HeroCore.heroes.values()
	var unlocked_heroes = []
	for h in heroes:
		# Assuming 'isDead' and 'isRemoved' check is enough, or check if bought
		# For now, let's assume all existing heroes in HeroCore are "unlocked"/available
		if not h.get("isRemoved", false) and not h.get("isDead", false):
			unlocked_heroes.append(h)
	
	if unlocked_heroes.is_empty():
		print("[PlayerInventory] No heroes available to equip")
		return
	
	# 2. Find heroes with empty slot
	var candidates_empty = []
	for h in unlocked_heroes:
		var equipment = h.get("equipment", {})
		if not equipment.has(slot_name) or equipment[slot_name] == null:
			candidates_empty.append(h)
	
	if not candidates_empty.is_empty():
		# Equip to random candidate with empty slot
		var hero = candidates_empty.pick_random()
		_perform_equip(hero.id, item, slot_name)
		remove_item_at_index(index)
		return
	
	# 3. If all full, find heroes with weaker items
	var candidates_weaker = []
	for h in unlocked_heroes:
		var current_item = h.equipment[slot_name]
		if current_item.power <= item.power:
			candidates_weaker.append(h)
	
	if not candidates_weaker.is_empty():
		# Equip to random candidate, replacing old item
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
		ItemSystem.ItemType.ARMOR: return "armor"
		ItemSystem.ItemType.WEAPON: return "weapon"
		ItemSystem.ItemType.RING: return "ring"
	return ""

## --- Save/Load ---

func get_save_data() -> Array:
	return items

func load_save_data(data: Array) -> void:
	# Reset to empty slots
	items.resize(MAX_INVENTORY_SIZE)
	for i in range(MAX_INVENTORY_SIZE):
		items[i] = {}
		
	# Fill from saved data
	for i in range(data.size()):
		if i >= MAX_INVENTORY_SIZE: break
		
		var item_data = data[i]
		if item_data is Dictionary and not item_data.is_empty():
			# Reconstruct item
			var reconstructed = ItemSystem.create_item(
				item_data.get("id", "unknown"),
				int(item_data.get("item_type", 0)),
				int(item_data.get("rarity", 0)),
				item_data.get("icon_path", ""),
				int(item_data.get("hp_bonus", 0)),
				int(item_data.get("damage_bonus", 0))
			)
			# Copy other fields like quantity
			if item_data.has("quantity"):
				reconstructed["quantity"] = item_data["quantity"]
				
			items[i] = reconstructed
			
	inventory_updated.emit()

func reset() -> void:
	items.resize(MAX_INVENTORY_SIZE)
	for i in range(MAX_INVENTORY_SIZE):
		items[i] = {}
	inventory_updated.emit()
