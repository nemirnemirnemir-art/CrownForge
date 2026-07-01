extends RefCounted
class_name TownInventoryPanelUtility

var _panel
var _transfers

func initialize(panel, transfers) -> void:
	_panel = panel
	_transfers = transfers

func on_stack_all_pressed() -> void:
	_stack_all_for_context("player")
	_stack_all_for_context("town")

func _stack_all_for_context(context: String) -> void:
	var inv_size: int = TownInventory.MAX_SIZE
	if context == "player":
		inv_size = PlayerInventory.MAX_INVENTORY_SIZE

	for i in range(inv_size):
		var base: Dictionary = _transfers.get_item_at_context(context, i)
		if base.is_empty():
			continue
		if bool(base.get("locked", false)):
			continue

		var item_type: int = int(base.get("item_type", -1))
		if not ItemSystem.is_stackable(item_type):
			continue

		var max_stack: int = ItemSystem.get_max_stack_size(item_type)
		var base_qty: int = int(base.get("quantity", 1))
		if base_qty >= max_stack:
			continue

		for j in range(i + 1, inv_size):
			var other: Dictionary = _transfers.get_item_at_context(context, j)
			if other.is_empty():
				continue
			if bool(other.get("locked", false)):
				continue
			if other.get("id", "") != base.get("id", ""):
				continue

			var other_qty: int = int(other.get("quantity", 1))
			if other_qty <= 0:
				continue

			var space: int = max_stack - base_qty
			if space <= 0:
				break

			var moved: int = min(space, other_qty)
			base_qty += moved
			other_qty -= moved
			base["quantity"] = base_qty
			if other_qty <= 0:
				other = {}
			else:
				other["quantity"] = other_qty

			_transfers.set_item_at_context(context, i, base)
			_transfers.set_item_at_context(context, j, other)

			if base_qty >= max_stack:
				break

	_transfers.autosave()

func on_auto_arrange_pressed() -> void:
	_auto_arrange_context("player")
	_auto_arrange_context("town")

func _auto_arrange_context(context: String) -> void:
	var inv_size: int = TownInventory.MAX_SIZE
	if context == "player":
		inv_size = PlayerInventory.MAX_INVENTORY_SIZE
	var locked_mask: Array[bool] = []
	locked_mask.resize(inv_size)
	var locked_items: Array[Dictionary] = []
	locked_items.resize(inv_size)

	var movable: Array[Dictionary] = []
	for i in range(inv_size):
		var it: Dictionary = _transfers.get_item_at_context(context, i)
		var is_locked: bool = (not it.is_empty()) and bool(it.get("locked", false))
		locked_mask[i] = is_locked
		if is_locked:
			locked_items[i] = it
		else:
			locked_items[i] = {}
			if not it.is_empty():
				movable.append(it)

	var movable_i: int = 0
	for i in range(inv_size):
		if locked_mask[i]:
			_transfers.set_item_at_context(context, i, locked_items[i])
		else:
			if movable_i < movable.size():
				_transfers.set_item_at_context(context, i, movable[movable_i])
				movable_i += 1
			else:
				_transfers.set_item_at_context(context, i, {})

	_transfers.autosave()

func on_destroy_pressed() -> void:
	if not _panel._selected_slot:
		return
	
	var idx = _panel._selected_slot.slot_index
	var item = _panel._selected_slot.item_data
	
	if _panel._selected_context == "player":
		PlayerInventory.remove_item_at_index(idx)
	elif _panel._selected_context == "town":
		var town_inv = TownCore.get_town_inventory()
		if town_inv:
			town_inv.remove_item_at(idx)
	
	_transfers.autosave()
	_panel._select_slot(null, "")

func on_sort_pressed(crit: int, ascending: bool) -> void:
	_sort_context("player", crit, ascending)
	_sort_context("town", crit, ascending)

func _sort_context(context: String, crit: int, ascending: bool) -> void:
	var inv_size: int = TownInventory.MAX_SIZE
	if context == "player":
		inv_size = PlayerInventory.MAX_INVENTORY_SIZE

	var movable_indices: Array[int] = []
	var movable_items: Array[Dictionary] = []
	for i in range(inv_size):
		var it: Dictionary = _transfers.get_item_at_context(context, i)
		if it.is_empty():
			continue
		if bool(it.get("locked", false)):
			continue
		movable_indices.append(i)
		movable_items.append(it)

	movable_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var av
		var bv
		match crit:
			0:
				av = int(a.get("item_type", 0))
				bv = int(b.get("item_type", 0))
				if av == bv:
					av = str(a.get("id", ""))
					bv = str(b.get("id", ""))
			1:
				av = int(a.get("rarity", 0))
				bv = int(b.get("rarity", 0))
				if av == bv:
					av = str(a.get("id", ""))
					bv = str(b.get("id", ""))
			2:
				av = str(a.get("name", a.get("id", "")))
				bv = str(b.get("name", b.get("id", "")))
			3:
				av = int(a.get("power", 0))
				bv = int(b.get("power", 0))
			4:
				av = float(a.get("weight", 0.0))
				bv = float(b.get("weight", 0.0))
			5:
				av = int(a.get("obtained_unix", 0))
				bv = int(b.get("obtained_unix", 0))
			_:
				av = str(a.get("id", ""))
				bv = str(b.get("id", ""))

		if ascending:
			return av < bv
		return av > bv
	)

	for k in range(movable_indices.size()):
		var idx: int = movable_indices[k]
		_transfers.set_item_at_context(context, idx, movable_items[k])

	_transfers.autosave()
