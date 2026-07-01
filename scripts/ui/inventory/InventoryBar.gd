extends Control
class_name InventoryBar

## UI Component for the player inventory bar

const HUD_SLOT_COUNT: int = 4

## Nodes
@onready var slots_container: HBoxContainer = $SlotsContainer
@onready var equip_button: TextureButton = $Actions/EquipButton
@onready var destroy_button: TextureButton = $Actions/DestroyButton

## Scene reference
const SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory/InventorySlot.tscn")
const ItemTooltipScript := preload("res://scripts/ui/inventory/ItemTooltip.gd")

## State
var selected_index: int = -1
var _tooltip_pinned_index: int = -1

func _get_player_inventory() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("PlayerInventory")

func _get_forge_core() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("ForgeCore")

func _ready() -> void:
	# Connect signals
	var player_inventory := _get_player_inventory()
	if is_instance_valid(player_inventory):
		player_inventory.inventory_updated.connect(_on_inventory_updated)
	
	equip_button.pressed.connect(_on_equip_pressed)
	destroy_button.pressed.connect(_on_destroy_pressed)
	
	# Initial setup
	_create_slots()
	_update_slots()
	_update_buttons()

func _create_slots() -> void:
	# Clear existing
	for child in slots_container.get_children():
		child.queue_free()
	
	for i in range(_get_display_slot_count()):
		var slot = SLOT_SCENE.instantiate()
		slots_container.add_child(slot)
		slot.slot_clicked.connect(_on_slot_clicked)
		if slot.has_signal("slot_hovered"):
			slot.slot_hovered.connect(_on_slot_hovered)
		if slot.has_signal("slot_unhovered"):
			slot.slot_unhovered.connect(_on_slot_unhovered)
		slot.setup(i, {}) # Empty initially


func _get_display_slot_count() -> int:
	var player_inventory := _get_player_inventory()
	if is_instance_valid(player_inventory):
		return mini(HUD_SLOT_COUNT, int(player_inventory.get("MAX_INVENTORY_SIZE")))
	return HUD_SLOT_COUNT

func _update_slots() -> void:
	var player_inventory := _get_player_inventory()
	if player_inventory == null or not player_inventory.has_method("get_items"):
		return
	var items = player_inventory.get_items()
	var slots = slots_container.get_children()
	
	for i in range(slots.size()):
		if i < items.size():
			slots[i].setup(i, items[i])
		else:
			slots[i].setup(i, {})
			
	# Restore selection visual
	if selected_index >= 0 and selected_index < slots.size():
		# Check if selected item is still valid (not empty)
		# Or keep selection even on empty? Usually deselect if item gone.
		if selected_index < items.size() and not items[selected_index].is_empty():
			slots[selected_index].set_selected(true)
		else:
			_deselect()

func _on_inventory_updated() -> void:
	_update_slots()
	# Selection check handled in _update_slots

func _on_slot_clicked(index: int) -> void:
	var player_inventory := _get_player_inventory()
	if player_inventory == null or not player_inventory.has_method("get_items"):
		_deselect()
		return
	var items = player_inventory.get_items()
	if index >= items.size():
		# Invalid index
		_deselect()
		return
		
	if items[index].is_empty():
		# Clicked empty slot
		_deselect()
		return
	
	# Deselect previous
	var slots = slots_container.get_children()
	if selected_index >= 0 and selected_index < slots.size():
		slots[selected_index].set_selected(false)
	
	# Select new
	selected_index = index
	slots[selected_index].set_selected(true)
	_update_buttons()

	_tooltip_pinned_index = index
	ItemTooltipScript.show_global_popup(items[index], self)
	
	# print("[InventoryBar] Selected item: %s" % items[index].id)

func _deselect() -> void:
	var slots = slots_container.get_children()
	if selected_index >= 0 and selected_index < slots.size():
		slots[selected_index].set_selected(false)
	selected_index = -1
	_update_buttons()

	_tooltip_pinned_index = -1
	ItemTooltipScript.hide_all_global_popups(self)

func _on_slot_hovered(index: int) -> void:
	if _tooltip_pinned_index != -1:
		return
	var player_inventory := _get_player_inventory()
	if player_inventory == null or not player_inventory.has_method("get_items"):
		return
	var items = player_inventory.get_items()
	if index < 0 or index >= items.size():
		return
	if items[index].is_empty():
		return
	ItemTooltipScript.show_global_popup(items[index], self)

func _on_slot_unhovered(_index: int) -> void:
	if _tooltip_pinned_index != -1:
		return
	ItemTooltipScript.hide_all_global_popups(self)

func _update_buttons() -> void:
	var has_selection = selected_index != -1
	equip_button.disabled = not has_selection
	destroy_button.disabled = not has_selection

func _on_equip_pressed() -> void:
	if selected_index != -1:
		var player_inventory := _get_player_inventory()
		if player_inventory and player_inventory.has_method("equip_item"):
			player_inventory.equip_item(selected_index)
		# Selection will be handled by update if item moves

func _on_destroy_pressed() -> void:
	if selected_index != -1:
		# Используем ForgeCore для разрушения предмета и получения Forge Cores
		var forge_core := _get_forge_core()
		if forge_core and forge_core.has_method("destroy_item") and forge_core.destroy_item(selected_index):
			# ForgeCore.destroy_item() уже удаляет предмет из инвентаря и добавляет cores
			# print("[InventoryBar] Item destroyed, Forge Cores added.")
			pass
		else:
			# Fallback: просто удаляем предмет, если ForgeCore недоступен
			var player_inventory := _get_player_inventory()
			if player_inventory and player_inventory.has_method("remove_item_at_index"):
				player_inventory.remove_item_at_index(selected_index)
