extends Node

## ForgePanelInventory module
## Manages inventory slots and selection

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/InventorySlot.tscn")

var _inventory_grid: GridContainer
var _slots: Array[InventorySlot] = []
var _selected_index: int = -1

func initialize(inventory_grid: GridContainer) -> void:
	_inventory_grid = inventory_grid
	_create_slots()

func create_slots() -> void:
	_create_slots()

func _create_slots() -> void:
	for child in _inventory_grid.get_children():
		child.queue_free()
	_slots.clear()

	for i in range(PlayerInventory.MAX_INVENTORY_SIZE):
		var slot = SLOT_SCENE.instantiate() as InventorySlot
		_inventory_grid.add_child(slot)
		_slots.append(slot)

func get_slots() -> Array[InventorySlot]:
	return _slots

func connect_slot_clicked(callback: Callable) -> void:
	for i in range(_slots.size()):
		_slots[i].slot_clicked.connect(callback)

func refresh_inventory() -> void:
	if not PlayerInventory:
		return

	var items = PlayerInventory.get_items()
	for i in range(_slots.size()):
		if i < items.size():
			_slots[i].setup(i, items[i])
		else:
			_slots[i].setup(i, {})

	if _selected_index >= items.size():
		deselect()

func select_index(index: int) -> void:
	deselect()
	if index < 0 or index >= _slots.size():
		_selected_index = -1
		return
	_selected_index = index
	_slots[index].set_selected(true)

func deselect() -> void:
	if _selected_index >= 0 and _selected_index < _slots.size():
		_slots[_selected_index].set_selected(false)
	_selected_index = -1

func get_selected_index() -> int:
	return _selected_index

