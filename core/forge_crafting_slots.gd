## Manages the crafting slot state machine for ForgeCore.

signal crafting_started(slot_index: int, time_left: float)
signal crafting_completed(slot_index: int, item: Dictionary)
signal crafting_claimed(slot_index: int)
signal crafting_tick(slot_index: int, time_left: float)

var crafting_slots: Dictionary = {}
var _forge: Node

func init(forge_core_ref: Node) -> void:
	_forge = forge_core_ref
	for i in range(_forge.MAX_CRAFT_SLOTS):
		if not crafting_slots.has(i):
			crafting_slots[i] = null

func tick(delta: float) -> void:
	for i in range(_forge.MAX_CRAFT_SLOTS):
		var slot = crafting_slots.get(i, null)
		if slot != null and slot.has("is_ready") and not slot["is_ready"]:
			slot["time_left"] -= delta
			if slot["time_left"] <= 0:
				slot["time_left"] = 0
				slot["is_ready"] = true
				_finish_crafting(i)

func start_crafting(item_type: ItemSystem.ItemType, rarity: ItemSystem.Rarity) -> int:
	var slot_index = find_free_slot()
	if slot_index == -1:
		print("[ForgeCraftingSlots] No free crafting slots.")
		return -1
	var cost = _forge._get_craft_cost(rarity)
	if not EconomyCore.can_afford_forge_cores(cost):
		print("[ForgeCraftingSlots] Not enough forge cores.")
		return -1
	if not EconomyCore.spend_forge_cores(cost):
		return -1
	return _assign_slot(slot_index, item_type, rarity)

## Start crafting without deducting cost (cost was already paid by the caller).
func start_crafting_preapproved(item_type: ItemSystem.ItemType, rarity: ItemSystem.Rarity) -> int:
	var slot_index = find_free_slot()
	if slot_index == -1:
		print("[ForgeCraftingSlots] No free crafting slots.")
		return -1
	return _assign_slot(slot_index, item_type, rarity)

func find_free_slot() -> int:
	for i in range(_forge.MAX_CRAFT_SLOTS):
		if crafting_slots.get(i, null) == null:
			return i
	return -1

func claim_item(slot_index: int) -> bool:
	var slot = crafting_slots.get(slot_index, null)
	if slot == null or not slot.has("is_ready") or not slot["is_ready"]:
		return false
	var item = slot["item"]
	if item.is_empty():
		crafting_slots[slot_index] = null
		return false
	if PlayerInventory.add_item(item):
		crafting_slots[slot_index] = null
		emit_signal("crafting_claimed", slot_index)
		print("[ForgeCraftingSlots] Claimed item from slot %d" % slot_index)
		return true
	else:
		print("[ForgeCraftingSlots] Inventory full, cannot claim item.")
		return false

func reset() -> void:
	crafting_slots.clear()
	for i in range(_forge.MAX_CRAFT_SLOTS):
		crafting_slots[i] = null

func get_slot_info(slot_index: int) -> Dictionary:
	var slot = crafting_slots.get(slot_index, null)
	if slot == null:
		return {}
	return slot

func _assign_slot(slot_index: int, item_type: ItemSystem.ItemType, rarity: ItemSystem.Rarity) -> int:
	crafting_slots[slot_index] = {
		"type": item_type,
		"rarity": rarity,
		"time_left": _forge.CRAFT_DURATION_SEC,
		"is_ready": false,
		"item": {}
	}
	emit_signal("crafting_started", slot_index, _forge.CRAFT_DURATION_SEC)
	print("[ForgeCraftingSlots] Started crafting in slot %d (Duration: %.1fs)" % [slot_index, _forge.CRAFT_DURATION_SEC])
	return slot_index

func _finish_crafting(slot_index: int) -> void:
	var slot = crafting_slots.get(slot_index, null)
	if slot == null:
		return
	# _forge._item_gen is guaranteed set by the time _process fires
	var crafted = _forge._item_gen.create_crafted_item(slot["type"], slot["rarity"])
	slot["item"] = crafted
	emit_signal("crafting_completed", slot_index, crafted)
	print("[ForgeCraftingSlots] Crafting completed in slot %d: %s" % [slot_index, crafted.get("id", "unknown")])
