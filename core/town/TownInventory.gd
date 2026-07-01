extends RefCounted
class_name TownInventory

## Town Inventory Module
## Manages persistent storage in town (10x10 grid)

signal inventory_updated()

const MAX_SIZE: int = 100 # 10x10

var _items: Array[Dictionary] = []

func initialize() -> void:
	# Initialize with empty slots if needed, or just use dynamic array
	# Dynamic array is easier, but for grid UI fixed size with nulls/empty dicts might be better.
	# Let's use array of empty dictionaries for fixed slots.
	_items.resize(MAX_SIZE)
	for i in range(MAX_SIZE):
		_items[i] = {}

func get_items() -> Array[Dictionary]:
	return _items

func add_item(item: Dictionary) -> bool:
	# 1. Try to stack if stackable
	if ItemSystem.is_stackable(item.get("item_type", -1)):
		var max_stack = ItemSystem.get_max_stack_size(item.get("item_type", -1))
		
		# Find existing stacks of same item
		for i in range(MAX_SIZE):
			var existing = _items[i]
			if not existing.is_empty() and existing.get("id") == item.get("id"):
				var current_qty = existing.get("quantity", 1)
				if current_qty < max_stack:
					var space = max_stack - current_qty
					var to_add = item.get("quantity", 1)
					
					if to_add <= space:
						existing["quantity"] = current_qty + to_add
						inventory_updated.emit()
						return true
					else:
						# Fill this stack and continue with remainder
						existing["quantity"] = max_stack
						item["quantity"] = to_add - space
						# Continue searching for next stack or empty slot with remainder
	
	# 2. Add to first empty slot
	for i in range(MAX_SIZE):
		if _items[i].is_empty():
			_items[i] = item
			inventory_updated.emit()
			return true
	return false

func add_item_at(index: int, item: Dictionary) -> bool:
	if index < 0 or index >= MAX_SIZE:
		return false
	if not _items[index].is_empty():
		return false
	
	_items[index] = item
	inventory_updated.emit()
	return true

func set_item_at(index: int, item: Dictionary) -> bool:
	if index < 0 or index >= MAX_SIZE:
		return false

	_items[index] = item
	inventory_updated.emit()
	return true

func remove_item_at(index: int) -> Dictionary:
	if index < 0 or index >= MAX_SIZE:
		return {}
	
	var item = _items[index]
	_items[index] = {}
	inventory_updated.emit()
	return item

func get_item_at(index: int) -> Dictionary:
	if index < 0 or index >= MAX_SIZE:
		return {}
	return _items[index]

func has_quantity(item_id: String, qty: int) -> bool:
	if item_id == "" or qty <= 0:
		return false

	var total: int = 0
	for i in range(MAX_SIZE):
		var it: Dictionary = _items[i]
		if it.is_empty():
			continue
		if it.get("id", "") != item_id:
			continue
		total += int(it.get("quantity", 1))
		if total >= qty:
			return true

	return false

func get_quantity(item_id: String) -> int:
	if item_id == "":
		return 0

	var total: int = 0
	for i in range(MAX_SIZE):
		var it: Dictionary = _items[i]
		if it.is_empty():
			continue
		if it.get("id", "") != item_id:
			continue
		total += int(it.get("quantity", 1))
	return total

func try_consume(item_id: String, qty: int) -> bool:
	if item_id == "" or qty <= 0:
		return false

	if not has_quantity(item_id, qty):
		return false

	var remaining: int = qty
	for i in range(MAX_SIZE):
		if remaining <= 0:
			break

		var it: Dictionary = _items[i]
		if it.is_empty():
			continue
		if it.get("id", "") != item_id:
			continue

		var have: int = int(it.get("quantity", 1))
		var take: int = min(have, remaining)
		have -= take
		remaining -= take

		if have <= 0:
			_items[i] = {}
		else:
			it["quantity"] = have
			_items[i] = it

	inventory_updated.emit()
	return remaining <= 0

## Save/Load
func get_save_data() -> Array:
	return _items

func load_save_data(data: Array) -> void:
	# Ensure _items is initialized and correctly sized
	if _items.size() != MAX_SIZE:
		_items.resize(MAX_SIZE)
		for i in range(MAX_SIZE):
			_items[i] = {}

	# Manually copy data to ensure type safety (Array -> Array[Dictionary])
	for i in range(MAX_SIZE):
		if i < data.size() and data[i] is Dictionary:
			_items[i] = data[i]
		else:
			_items[i] = {}
	
	inventory_updated.emit()
