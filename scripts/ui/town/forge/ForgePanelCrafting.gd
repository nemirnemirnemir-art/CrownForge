extends Node

## ForgePanelCrafting module
## Manages crafting logic, buttons, and crafting queue UI

const EQUIPMENT_ICON_BY_TYPE := {
	ItemSystem.ItemType.HELMET: "res://assets/items/equipment/helmet.png",
	ItemSystem.ItemType.ARMOR: "res://assets/items/equipment/armor.png",
	ItemSystem.ItemType.WEAPON: "res://assets/items/equipment/sword.png",
	ItemSystem.ItemType.RING: "res://assets/items/equipment/ring.png",
}

var _forge_panel: Control
var _craft_type_selector: OptionButton = null
var _craft_button: Button = null
var _rarity_label: Label = null
var _crafting_slots_container: HBoxContainer = null
var _selected_type: int = ItemSystem.ItemType.WEAPON
var _craft_button_visual: TextureRect = null

func initialize(forge_panel: Control) -> void:
	_forge_panel = forge_panel
	_build_type_selector()
	_setup_craft_button()
	_create_crafting_slots_ui()

func get_selected_type() -> int:
	return _selected_type

func set_selected_type(type: int) -> void:
	_selected_type = type

func build_type_selector() -> void:
	_build_type_selector()

func _build_type_selector() -> void:
	if not _craft_type_selector:
		var craft_controls = _forge_panel.get_node_or_null("Panel/VBoxContainer/CraftControls")
		if not craft_controls:
			# print("[ForgePanelCrafting] ⚠️ CraftControls node not found")
			return
		_craft_type_selector = OptionButton.new()
		_craft_type_selector.name = "TypeSelector"
		craft_controls.add_child(_craft_type_selector)
	
	_craft_type_selector.clear()
	_craft_type_selector.add_item("Weapon", ItemSystem.ItemType.WEAPON)
	_craft_type_selector.add_item("Helmet", ItemSystem.ItemType.HELMET)
	_craft_type_selector.add_item("Armor", ItemSystem.ItemType.ARMOR)
	_craft_type_selector.add_item("Ring", ItemSystem.ItemType.RING)
	_craft_type_selector.selected = 0
	_selected_type = ItemSystem.ItemType.WEAPON

func connect_type_selected(callback: Callable) -> void:
	if _craft_type_selector:
		_craft_type_selector.item_selected.connect(callback)

func _setup_craft_button() -> void:
	var vbox = _forge_panel.get_node("Panel/VBoxContainer")
	var main_content = vbox.get_node_or_null("MainContent")
	
	if not main_content:
		main_content = HBoxContainer.new()
		main_content.name = "MainContent"
		vbox.add_child(main_content)
		vbox.move_child(main_content, 2)
		
		var inventory_grid = vbox.get_node_or_null("InventoryGrid")
		if inventory_grid and inventory_grid.get_parent() == vbox:
			vbox.remove_child(inventory_grid)
			main_content.add_child(inventory_grid)
	
	var craft_controls = main_content.get_node_or_null("CraftControls")
	if not craft_controls:
		craft_controls = VBoxContainer.new()
		craft_controls.name = "CraftControls"
		craft_controls.custom_minimum_size = Vector2(200, 0)
		main_content.add_child(craft_controls)
	
	if not _craft_button:
		_craft_button = Button.new()
		_craft_button.name = "CraftButton"
		_craft_button.custom_minimum_size = Vector2(200, 200)
		_craft_button.text = "CRAFT"
		craft_controls.add_child(_craft_button)
	
	_craft_button.text = ""
	_craft_button.flat = true
	
	if _craft_button_visual == null:
		_craft_button_visual = TextureRect.new()
		_craft_button_visual.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		_craft_button_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_craft_button_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_craft_button_visual.anchors_preset = Control.PRESET_FULL_RECT
		_craft_button_visual.anchor_left = 0.0
		_craft_button_visual.anchor_top = 0.0
		_craft_button_visual.anchor_right = 1.0
		_craft_button_visual.anchor_bottom = 1.0
		_craft_button_visual.offset_left = 0
		_craft_button_visual.offset_top = 0
		_craft_button_visual.offset_right = 0
		_craft_button_visual.offset_bottom = 0
		_craft_button.add_child(_craft_button_visual)
	_update_craft_button_visual()
	
	if not _rarity_label:
		_rarity_label = Label.new()
		_rarity_label.name = "RarityLabel"
		_rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_rarity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_rarity_label.custom_minimum_size = Vector2(200, 0)
		craft_controls.add_child(_rarity_label)

func connect_craft_pressed(callback: Callable) -> void:
	if _craft_button:
		_craft_button.pressed.connect(callback)

func update_craft_button() -> void:
	if not _craft_button or not ForgeCore or not EconomyCore:
		return
	_update_craft_button_visual()
	
	var cost = ForgeCore.RANDOM_CRAFT_COST
	_craft_button.text = "CRAFT (%d cores)" % cost
	_craft_button.disabled = not EconomyCore.can_afford_forge_cores(cost)
	
	if _rarity_label:
		var chances = ForgeCore.get_rarity_chances()
		var parts = []
		for rarity in [ItemSystem.Rarity.UGLY, ItemSystem.Rarity.COMMON, ItemSystem.Rarity.NORMAL, 
					ItemSystem.Rarity.EPIC, ItemSystem.Rarity.LEGENDARY, ItemSystem.Rarity.COSMIC, ItemSystem.Rarity.GOD]:
			var chance = chances.get(rarity, 0.0)
			if chance > 0.01:
				var rarity_letter = ItemSystem.get_rarity_name(rarity).substr(0, 1)
				parts.append("%s - %.0f%%" % [rarity_letter, chance])
		_rarity_label.text = " | ".join(parts)

func handle_craft_pressed() -> String:
	if not ForgeCore:
		return "ForgeCore not available."
	
	var slot_index = ForgeCore.start_random_rarity_crafting(_selected_type)
	if slot_index == -1:
		return "Craft failed (No slots or cores)."
	
	return "Started crafting %s..." % ItemSystem.get_type_name(_selected_type)

func handle_type_selected(index: int) -> String:
	_selected_type = _craft_type_selector.get_item_id(index)
	_update_craft_button_visual()
	return "Crafting %s gear." % ItemSystem.get_type_name(_selected_type)


func _update_craft_button_visual() -> void:
	if _craft_button_visual == null:
		return
	var visual_path: String = str(EQUIPMENT_ICON_BY_TYPE.get(_selected_type, ""))
	if visual_path != "" and ResourceLoader.exists(visual_path):
		_craft_button_visual.texture = load(visual_path) as Texture2D
	else:
		_craft_button_visual.texture = null

func _create_crafting_slots_ui() -> void:
	if not _forge_panel.has_node("Panel/VBoxContainer/CraftingSlots"):
		var container = HBoxContainer.new()
		container.name = "CraftingSlots"
		container.alignment = BoxContainer.ALIGNMENT_CENTER
		_forge_panel.get_node("Panel/VBoxContainer").add_child(container)
		_forge_panel.get_node("Panel/VBoxContainer").move_child(container, 2)
		_crafting_slots_container = container
	
	for child in _crafting_slots_container.get_children():
		child.queue_free()
		
	for i in range(ForgeCore.MAX_CRAFT_SLOTS):
		var slot_ui = _create_single_crafting_slot(i)
		_crafting_slots_container.add_child(slot_ui)

func _create_single_crafting_slot(index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(60, 60)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	panel.add_child(vbox)
	
	var hammer_icon = TextureRect.new()
	hammer_icon.name = "HammerIcon"
	hammer_icon.custom_minimum_size = Vector2(40, 40)
	hammer_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	hammer_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hammer_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var icon_path = "res://assets/environment/buildings/forge.png"
	if ResourceLoader.exists(icon_path):
		hammer_icon.texture = load(icon_path)
	hammer_icon.visible = false
	vbox.add_child(hammer_icon)
	
	var label = Label.new()
	label.name = "Status"
	label.text = "Empty"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(label)
	
	var btn = Button.new()
	btn.name = "ClaimBtn"
	btn.text = "Claim"
	btn.visible = false
	btn.add_theme_font_size_override("font_size", 10)
	vbox.add_child(btn)
	
	return panel

func connect_claim_pressed(callback: Callable) -> void:
	if not _crafting_slots_container:
		return
	
	for i in range(_crafting_slots_container.get_child_count()):
		var slot_ui = _crafting_slots_container.get_child(i)
		var vbox = slot_ui.get_node("VBoxContainer")
		var btn = vbox.get_node("ClaimBtn")
		btn.pressed.connect(callback.bind(i))

func update_crafting_slots() -> void:
	if not _crafting_slots_container:
		return
	
	for i in range(ForgeCore.MAX_CRAFT_SLOTS):
		if i >= _crafting_slots_container.get_child_count():
			break
		var slot_ui = _crafting_slots_container.get_child(i)
		var info = ForgeCore.get_slot_info(i)
		
		var vbox = slot_ui.get_node("VBoxContainer")
		var hammer_icon = vbox.get_node("HammerIcon")
		var label = vbox.get_node("Status")
		var btn = vbox.get_node("ClaimBtn")
		
		if info.is_empty():
			label.text = "Empty"
			btn.visible = false
			hammer_icon.visible = false
		else:
			if info.get("is_ready", false):
				label.text = "Ready!"
				btn.visible = true
				hammer_icon.visible = false
			else:
				var t = info.get("time_left", 0.0)
				var m = int(t / 60)
				var s = int(t) % 60
				label.text = "%02d:%02d" % [m, s]
				btn.visible = false
				hammer_icon.visible = true

func handle_claim_pressed(index: int) -> String:
	if ForgeCore.claim_item(index):
		return "Claimed item!"
	else:
		return "Inventory full!"

