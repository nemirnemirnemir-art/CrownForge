extends RefCounted
class_name TownInventoryPanelTransfers

var _panel

func initialize(panel) -> void:
	_panel = panel

func autosave() -> void:
	if SaveCore:
		SaveCore.request_save()

func get_item_at_context(context: String, index: int) -> Dictionary:
	if context == "player":
		return PlayerInventory.get_item_at_index(index)
	if context == "town":
		var town_inv: TownInventory = TownCore.get_town_inventory()
		if town_inv:
			return town_inv.get_item_at(index)
	return {}

func set_item_at_context(context: String, index: int, item: Dictionary) -> bool:
	if context == "player":
		return PlayerInventory.set_item_at_index(index, item)
	if context == "town":
		var town_inv: TownInventory = TownCore.get_town_inventory()
		if town_inv:
			return town_inv.set_item_at(index, item)
	return false

func on_lock_toggled(pressed: bool) -> void:
	if not _panel._selected_slot or _panel._selected_context == "":
		return

	var idx: int = _panel._selected_slot.slot_index
	var item: Dictionary = get_item_at_context(_panel._selected_context, idx)
	if item.is_empty():
		return

	item["locked"] = pressed
	set_item_at_context(_panel._selected_context, idx, item)
	autosave()

func try_merge_stacks(source_context: String, source_index: int, target_context: String, target_index: int) -> bool:
	var source_item: Dictionary = get_item_at_context(source_context, source_index)
	var target_item: Dictionary = get_item_at_context(target_context, target_index)
	if source_item.is_empty() or target_item.is_empty():
		return false

	if bool(source_item.get("locked", false)):
		return false
	if bool(target_item.get("locked", false)):
		return false

	if source_item.get("id", "") != target_item.get("id", ""):
		return false

	var item_type: int = int(source_item.get("item_type", -1))
	if not ItemSystem.is_stackable(item_type):
		return false

	var max_stack: int = ItemSystem.get_max_stack_size(item_type)
	var source_qty: int = int(source_item.get("quantity", 1))
	var target_qty: int = int(target_item.get("quantity", 1))
	if source_qty <= 0:
		return false
	if target_qty >= max_stack:
		return false

	var space: int = max_stack - target_qty
	var moved: int = min(space, source_qty)
	if moved <= 0:
		return false

	target_item["quantity"] = target_qty + moved

	var remaining: int = source_qty - moved
	if remaining <= 0:
		source_item = {}
	else:
		source_item["quantity"] = remaining

	set_item_at_context(target_context, target_index, target_item)
	set_item_at_context(source_context, source_index, source_item)
	autosave()
	return true

func swap_between_contexts(source_context: String, source_index: int, target_context: String, target_index: int) -> void:
	var source_item: Dictionary = get_item_at_context(source_context, source_index)
	var target_item: Dictionary = get_item_at_context(target_context, target_index)

	if bool(source_item.get("locked", false)) or bool(target_item.get("locked", false)):
		return

	set_item_at_context(source_context, source_index, target_item)
	set_item_at_context(target_context, target_index, source_item)
	autosave()

func swap_town_items(from_idx: int, to_idx: int) -> void:
	var town_inv = TownCore.get_town_inventory()

	var item_from = town_inv.get_item_at(from_idx)
	var item_to = town_inv.get_item_at(to_idx)

	if bool(item_from.get("locked", false)) or bool(item_to.get("locked", false)):
		return

	town_inv.remove_item_at(from_idx)
	town_inv.remove_item_at(to_idx)

	town_inv.add_item_at(to_idx, item_from)
	town_inv.add_item_at(from_idx, item_to)

	autosave()

func handle_drop(source_data: Dictionary, target_index: int, target_context: String) -> void:
	var source_idx = source_data.get("index")
	var source_context = source_data.get("source").get_meta("context")

	if source_context == target_context and int(source_idx) == int(target_index):
		return

	if source_context == "town" and target_context == "player":
		return

	if try_merge_stacks(source_context, int(source_idx), target_context, int(target_index)):
		return

	var s_item: Dictionary = get_item_at_context(source_context, int(source_idx))
	var t_item: Dictionary = get_item_at_context(target_context, int(target_index))
	if bool(s_item.get("locked", false)) or bool(t_item.get("locked", false)):
		return

	if source_context == target_context:
		if source_context == "player":
			PlayerInventory.swap_items(source_idx, target_index)
			autosave()
		else:
			swap_town_items(source_idx, target_index)
	else:
		swap_between_contexts(source_context, int(source_idx), target_context, int(target_index))

func find_first_empty_slot(context: String) -> int:
	var inv_size: int = TownInventory.MAX_SIZE
	if context == "player":
		inv_size = PlayerInventory.MAX_INVENTORY_SIZE
	for i in range(inv_size):
		if get_item_at_context(context, i).is_empty():
			return i
	return -1

func double_click_transfer(source_context: String, source_index: int) -> void:
	if source_context == "town":
		return

	var target_context := "town"

	var item: Dictionary = get_item_at_context(source_context, source_index)
	if item.is_empty():
		return
	if bool(item.get("locked", false)):
		return

	var item_type: int = int(item.get("item_type", -1))
	if ItemSystem.is_stackable(item_type):
		var remaining: int = int(item.get("quantity", 1))
		var max_stack: int = ItemSystem.get_max_stack_size(item_type)

		var target_size: int = TownInventory.MAX_SIZE
		for i in range(target_size):
			if remaining <= 0:
				break
			var existing: Dictionary = get_item_at_context(target_context, i)
			if existing.is_empty():
				continue
			if bool(existing.get("locked", false)):
				continue
			if existing.get("id", "") != item.get("id", ""):
				continue

			var existing_qty: int = int(existing.get("quantity", 1))
			if existing_qty >= max_stack:
				continue

			var space: int = max_stack - existing_qty
			var moved: int = min(space, remaining)
			existing["quantity"] = existing_qty + moved
			remaining -= moved
			set_item_at_context(target_context, i, existing)

		if remaining <= 0:
			set_item_at_context(source_context, source_index, {})
			autosave()
			return
		item["quantity"] = remaining

	var empty_index := find_first_empty_slot(target_context)
	if empty_index == -1:
		return

	set_item_at_context(target_context, empty_index, item)
	set_item_at_context(source_context, source_index, {})
	autosave()
