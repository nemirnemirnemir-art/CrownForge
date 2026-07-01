extends RefCounted
class_name TownInventoryPanelSlots

var _panel

func initialize(panel) -> void:
	_panel = panel

func setup_grids() -> void:
	for child in _panel.player_grid.get_children():
		child.queue_free()

	for i in range(PlayerInventory.MAX_INVENTORY_SIZE):
		var slot = _panel.SLOT_SCENE.instantiate()
		_panel.player_grid.add_child(slot)
		slot.custom_minimum_size = Vector2(62.5, 62.5)
		slot.slot_clicked.connect(_panel._on_player_slot_clicked)
		slot.slot_double_clicked.connect(_panel._on_player_slot_double_clicked)
		if slot.has_signal("data_dropped"):
			slot.data_dropped.connect(Callable(_panel, "_on_slot_data_dropped_wrapper").bind("player"))
		slot.setup(i, {})
		slot.set_meta("context", "player")

	for child in _panel.town_grid.get_children():
		child.queue_free()

	for i in range(100):
		var slot = _panel.SLOT_SCENE.instantiate()
		_panel.town_grid.add_child(slot)
		slot.custom_minimum_size = Vector2(62.5, 62.5)
		slot.slot_clicked.connect(_panel._on_town_slot_clicked)
		slot.slot_double_clicked.connect(_panel._on_town_slot_double_clicked)
		if slot.has_signal("data_dropped"):
			slot.data_dropped.connect(Callable(_panel, "_on_slot_data_dropped_wrapper").bind("town"))
		slot.setup(i, {})
		slot.set_meta("context", "town")

	update_player_grid()
	update_town_grid()

func update_player_grid() -> void:
	if not _panel.visible:
		return

	var items = PlayerInventory.get_items()
	var slots = _panel.player_grid.get_children()

	for i in range(slots.size()):
		if i < items.size():
			slots[i].setup(i, items[i])
		else:
			slots[i].setup(i, {})

	if _panel._selected_slot and _panel._selected_context == "player":
		var idx = _panel._selected_slot.slot_index
		if idx < slots.size():
			select_slot(slots[idx], "player")
		else:
			select_slot(null, "")

func update_town_grid() -> void:
	if not _panel.visible:
		return

	var town_inv = TownCore.get_town_inventory()
	if not town_inv:
		return

	var items = town_inv.get_items()
	var slots = _panel.town_grid.get_children()

	for i in range(slots.size()):
		if i < items.size():
			slots[i].setup(i, items[i])
		else:
			slots[i].setup(i, {})

	if _panel._selected_slot and _panel._selected_context == "town":
		var idx = _panel._selected_slot.slot_index
		if idx < slots.size():
			select_slot(slots[idx], "town")
		else:
			select_slot(null, "")

func select_slot(slot: InventorySlot, context: String) -> void:
	if _panel._selected_slot and is_instance_valid(_panel._selected_slot):
		_panel._selected_slot.set_selected(false)

	_panel._selected_slot = slot
	_panel._selected_context = context

	if _panel._selected_slot:
		_panel._selected_slot.set_selected(true)
		update_info_panel(_panel._selected_slot.item_data)
	else:
		update_info_panel({})

func update_info_panel(item: Dictionary = {}) -> void:
	if item.is_empty():
		_panel.item_name_label.text = "Select Item"
		_panel.item_desc_label.text = ""
		_panel.equip_button.disabled = true
		_panel.destroy_button.disabled = true
		if _panel.lock_button:
			_panel.lock_button.disabled = true
			_panel.lock_button.button_pressed = false
		return

	var item_name = item.get("id", "Unknown")
	if item.has("name"):
		item_name = item["name"]

	var desc = ""
	var rarity = item.get("rarity", ItemSystem.Rarity.UGLY)
	var rarity_name = ItemSystem.get_rarity_name(rarity)
	var rarity_color = ItemSystem.get_rarity_color(rarity)

	desc += "[color=#%s]%s[/color]\n" % [rarity_color.to_html(), rarity_name]

	var type = item.get("item_type", ItemSystem.ItemType.WEAPON)
	if type == ItemSystem.ItemType.WEAPON:
		desc += "Type: Weapon\n"
	elif type == ItemSystem.ItemType.ARMOR:
		desc += "Type: Armor\n"
	elif type == ItemSystem.ItemType.ACCESSORY:
		desc += "Type: Accessory\n"
	elif type == ItemSystem.ItemType.INGREDIENT:
		desc += "Type: Material\n"

	if item.has("min_damage") and item.has("max_damage"):
		desc += "Damage: %d - %d\n" % [item.min_damage, item.max_damage]
	if item.has("damage_bonus"):
		desc += "Damage: +%d\n" % item.damage_bonus
	if item.has("hp_bonus"):
		desc += "HP: +%d\n" % item.hp_bonus
	if item.has("description"):
		desc += "\n" + item.description

	_panel.item_name_label.text = item_name.capitalize()
	_panel.item_desc_label.text = desc

	_panel.destroy_button.disabled = false

	var is_equip = (type == ItemSystem.ItemType.WEAPON or type == ItemSystem.ItemType.ARMOR or type == ItemSystem.ItemType.ACCESSORY)
	_panel.equip_button.disabled = not (_panel._selected_context == "player" and is_equip)

	if _panel.lock_button:
		_panel.lock_button.disabled = false
		_panel.lock_button.button_pressed = bool(item.get("locked", false))
