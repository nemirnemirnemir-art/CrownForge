extends RefCounted
class_name SmithCraftRecipesModel

## Manages recipe list selection and scroll state for the Smith panel.
## Recipe data itself lives in SmithCraftRecipes.

const VISIBLE_ROWS: int = 4

var _smith_state: SmithState = null

func initialize(smith_state: SmithState) -> void:
	_smith_state = smith_state

func scroll_by(delta: int) -> void:
	var max_scroll: int = max(0, SmithCraftRecipes.RECIPES.size() - VISIBLE_ROWS)
	_smith_state.recipes_scroll = int(clamp(_smith_state.recipes_scroll + delta, 0, max_scroll))

func select_at_visible_index(row_index: int) -> void:
	var idx := _smith_state.recipes_scroll + row_index
	if idx < 0 or idx >= SmithCraftRecipes.RECIPES.size():
		return
	_smith_state.selected_recipe_index = idx
	var slot_idx := _smith_state.selected_slot_index
	var st: Dictionary = _smith_state.slot_state[slot_idx]
	if not bool(st.get("is_crafting", false)):
		st["pending_recipe_index"] = idx
		_smith_state.slot_state[slot_idx] = st

func get_selected_recipe() -> Dictionary:
	return SmithCraftRecipes.get_recipe(_smith_state.selected_recipe_index)

func get_recipe_count() -> int:
	return SmithCraftRecipes.get_recipe_count()

func get_scroll() -> int:
	return _smith_state.recipes_scroll

func get_selected_index() -> int:
	return _smith_state.selected_recipe_index
