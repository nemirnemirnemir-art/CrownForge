extends Control

## UI Panel for Forge: Crafting and Slots

@onready var slots_container: GridContainer = $Content/SlotsContainer
@onready var craft_button: Button = $Content/Controls/CraftButton
@onready var rarity_option: OptionButton = $Content/Controls/RarityOption
@onready var type_option: OptionButton = $Content/Controls/TypeOption
@onready var cost_label: Label = $Content/Controls/CostLabel
@onready var cores_label: Label = $Content/Header/CoresLabel

var slot_scenes: Array[Control] = []

func _ready() -> void:
	_setup_options()
	_create_slots()
	
	if craft_button:
		craft_button.pressed.connect(_on_craft_pressed)
	if rarity_option:
		rarity_option.item_selected.connect(_on_options_changed)
	
	# Connect signals
	if ForgeCore:
		ForgeCore.crafting_started.connect(_on_crafting_started)
		ForgeCore.crafting_completed.connect(_on_crafting_completed)
		ForgeCore.crafting_claimed.connect(_on_crafting_claimed)
		ForgeCore.forge_cores_gained.connect(_on_cores_changed)
	if EventBus:
		EventBus.forge_cores_changed.connect(_on_cores_changed_bus)
		
	_update_ui()

func _setup_options() -> void:
	if rarity_option:
		rarity_option.clear()
		rarity_option.add_item("Common", ItemSystem.Rarity.COMMON)
		rarity_option.add_item("Normal", ItemSystem.Rarity.NORMAL)
		rarity_option.add_item("Epic", ItemSystem.Rarity.EPIC)
		rarity_option.add_item("Legendary", ItemSystem.Rarity.LEGENDARY)
		rarity_option.add_item("Cosmic", ItemSystem.Rarity.COSMIC)
		rarity_option.add_item("God", ItemSystem.Rarity.GOD)
		rarity_option.selected = 0
		
	if type_option:
		type_option.clear()
		type_option.add_item("Weapon", ItemSystem.ItemType.WEAPON)
		type_option.add_item("Armor", ItemSystem.ItemType.ARMOR)
		type_option.add_item("Helmet", ItemSystem.ItemType.HELMET)
		type_option.add_item("Ring", ItemSystem.ItemType.RING)
		type_option.selected = 0

func _create_slots() -> void:
	if not slots_container: return
	
	for child in slots_container.get_children():
		child.queue_free()
	slot_scenes.clear()
	
	for i in range(ForgeCore.MAX_CRAFT_SLOTS):
		var slot = _create_slot_ui(i)
		slots_container.add_child(slot)
		slot_scenes.append(slot)

func _create_slot_ui(index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(80, 80)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Empty"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)
	
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(icon)
	
	var action_button = Button.new()
	action_button.name = "ActionButton"
	action_button.text = "Claim"
	action_button.visible = false
	action_button.pressed.connect(_on_claim_pressed.bind(index))
	vbox.add_child(action_button)
	
	return panel

func _process(delta: float) -> void:
	if not visible: return
	
	# Update timers
	for i in range(ForgeCore.MAX_CRAFT_SLOTS):
		var info = ForgeCore.get_slot_info(i)
		_update_slot_visual(i, info)

func _update_slot_visual(index: int, info: Dictionary) -> void:
	if index >= slot_scenes.size(): return
	var slot_ui = slot_scenes[index]
	var status_label = slot_ui.get_node("VBoxContainer/StatusLabel")
	var action_button = slot_ui.get_node("VBoxContainer/ActionButton")
	var icon = slot_ui.get_node("VBoxContainer/Icon")
	
	if info == null:
		status_label.text = "Empty"
		action_button.visible = false
		icon.texture = null
	else:
		if info["is_ready"]:
			status_label.text = "Ready!"
			action_button.visible = true
			action_button.text = "Claim"
			# Show item icon if available
			if info["item"] and info["item"].has("icon_path"):
				icon.texture = load(info["item"]["icon_path"])
		else:
			var time = info["time_left"]
			var mins = int(time / 60)
			var secs = int(time) % 60
			status_label.text = "%02d:%02d" % [mins, secs]
			action_button.visible = false
			icon.texture = load("res://assets/items/res/forge_cores.png") # Placeholder for crafting

func _on_craft_pressed() -> void:
	var rarity = rarity_option.get_selected_id()
	var type = type_option.get_selected_id()
	
	ForgeCore.start_crafting(type, rarity)
	_update_ui()

func _on_claim_pressed(index: int) -> void:
	ForgeCore.claim_item(index)
	_update_ui()

func _on_options_changed(_index: int) -> void:
	_update_ui()

func _update_ui() -> void:
	if not is_inside_tree(): return
	
	# Update cost
	var rarity = rarity_option.get_selected_id()
	var cost = ForgeCore.get_craft_cost(rarity)
	if cost_label:
		cost_label.text = "Cost: %d Cores" % cost
		
	# Update cores
	if cores_label:
		cores_label.text = "Cores: %d" % EconomyCore.get_forge_cores()

func _on_crafting_started(slot_index: int, time_left: float) -> void:
	_update_ui()

func _on_crafting_completed(slot_index: int, item: Dictionary) -> void:
	_update_ui()

func _on_crafting_claimed(slot_index: int) -> void:
	_update_ui()

func _on_cores_changed(amount: int) -> void:
	_update_ui()

func _on_cores_changed_bus(new_amount: int, delta: int) -> void:
	_update_ui()
