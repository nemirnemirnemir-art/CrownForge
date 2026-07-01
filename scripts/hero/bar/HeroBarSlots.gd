extends Node

## HeroBarSlots module
## Manages hero slot creation and management

var _slots_grid: GridContainer
var _hero_slots: Array[TextureButton] = []
const HEROES_PER_PAGE: int = 5

func initialize(slots_grid: GridContainer) -> void:
	_slots_grid = slots_grid
	_create_hero_slots()

func create_hero_slots() -> void:
	_create_hero_slots()

func _create_hero_slots() -> void:
	if _slots_grid == null:
		return
	
	_hero_slots.clear()
	for i in range(HEROES_PER_PAGE):
		var slot: TextureButton = TextureButton.new()
		slot.custom_minimum_size = Vector2(96, 96)
		slot.pivot_offset = slot.custom_minimum_size * 0.5
		slot.scale = Vector2(1.0, 1.0)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		_slots_grid.add_child(slot)
		_hero_slots.append(slot)

func get_slots() -> Array[TextureButton]:
	return _hero_slots

func get_slot(index: int) -> TextureButton:
	if index >= 0 and index < _hero_slots.size():
		return _hero_slots[index]
	return null

func connect_slot_clicked(slot_index: int, callback: Callable) -> void:
	if slot_index >= 0 and slot_index < _hero_slots.size():
		_hero_slots[slot_index].pressed.connect(callback)

