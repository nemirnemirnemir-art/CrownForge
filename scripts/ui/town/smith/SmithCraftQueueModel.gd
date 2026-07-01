extends RefCounted
class_name SmithCraftQueueModel

## Manages crafting queue slot state: pending quantity adjustments and ticking.
## Slot state data lives in SmithState.

var _smith_state: SmithState = null

func initialize(smith_state: SmithState) -> void:
	_smith_state = smith_state

func adjust_pending_qty(delta: int) -> void:
	var slot_idx := _smith_state.selected_slot_index
	var st: Dictionary = _smith_state.slot_state[slot_idx]
	if bool(st.get("is_crafting", false)):
		return
	var pending_qty: int = int(st.get("pending_qty", 1))
	st["pending_qty"] = clampi(pending_qty + delta, 1, 999)
	_smith_state.slot_state[slot_idx] = st

func get_pending_qty() -> int:
	var st: Dictionary = _smith_state.slot_state[_smith_state.selected_slot_index]
	return int(st.get("pending_qty", 1))

func is_selected_slot_crafting() -> bool:
	var st: Dictionary = _smith_state.slot_state[_smith_state.selected_slot_index]
	return bool(st.get("is_crafting", false))

func tick(recipes: Array) -> void:
	_smith_state.tick_slots(recipes)
