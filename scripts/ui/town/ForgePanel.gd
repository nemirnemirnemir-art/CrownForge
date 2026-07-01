extends Control
class_name ForgePanel

## UI panel for Forge operations - Controller
## Координирует модули для работы с кузницей

# ===========================================
# MODULE PRELOADS
# ===========================================
const ForgePanelInventory = preload("res://scripts/ui/town/forge/ForgePanelInventory.gd")
const ForgePanelCrafting = preload("res://scripts/ui/town/forge/ForgePanelCrafting.gd")
const ForgePanelUI = preload("res://scripts/ui/town/forge/ForgePanelUI.gd")

# ===========================================
# NODE REFERENCES
# ===========================================
@onready var close_button: Button = $Panel/VBoxContainer/Header/CloseButton
@onready var cores_label: Label = $Panel/VBoxContainer/Header/CoresLabel
@onready var inventory_grid: GridContainer = $Panel/VBoxContainer/InventoryGrid
@onready var destroy_button: Button = $Panel/VBoxContainer/DestroyButton
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel

# ===========================================
# MODULE INSTANCES
# ===========================================
var _inventory: Node
var _crafting: Node
var _ui: Node

# ===========================================
# INITIALIZATION
# ===========================================
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	_initialize_modules()
	_connect_signals()

	_inventory.refresh_inventory()
	_ui.update_forge_label()
	_update_buttons()

func _initialize_modules() -> void:
	_inventory = ForgePanelInventory.new()
	_inventory.initialize(inventory_grid)
	_inventory.connect_slot_clicked(_on_slot_clicked)

	_crafting = ForgePanelCrafting.new()
	_crafting.initialize(self)
	_crafting.connect_craft_pressed(_on_craft_pressed)
	_crafting.connect_type_selected(_on_type_selected)
	_crafting.connect_claim_pressed(_on_claim_pressed)

	_ui = ForgePanelUI.new()
	_ui.initialize(cores_label, status_label, destroy_button)

# ===========================================
# SIGNAL CONNECTIONS
# ===========================================
func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_pressed)
	destroy_button.pressed.connect(_on_destroy_pressed)

	if PlayerInventory:
		PlayerInventory.inventory_updated.connect(_refresh_inventory)

	if EventBus:
		EventBus.forge_cores_changed.connect(_on_forge_cores_changed)

# ===========================================
# PUBLIC API
# ===========================================
func open() -> void:
	_inventory.refresh_inventory()
	_ui.update_forge_label()
	_update_buttons()
	show()
	move_to_front()

func close() -> void:
	hide()
	_inventory.deselect()

# ===========================================
# EVENT HANDLERS
# ===========================================
func _on_slot_clicked(index: int) -> void:
	_inventory.select_index(index)
	_update_buttons()

func _on_destroy_pressed() -> void:
	var selected_index = _inventory.get_selected_index()
	if selected_index < 0:
		return
	if not ForgeCore:
		_ui.set_status_text("ForgeCore not available.")
		return
	
	var before = EconomyCore.get_forge_cores() if EconomyCore else 0
	if ForgeCore.destroy_item(selected_index):
		var after = EconomyCore.get_forge_cores() if EconomyCore else before
		var gained = after - before
		_ui.set_status_text("Destroyed item for %d cores." % max(gained, 0))
	else:
		_ui.set_status_text("Failed to destroy item.")
	_update_buttons()

func _on_craft_pressed() -> void:
	var message = _crafting.handle_craft_pressed()
	_ui.set_status_text(message)
	_update_buttons()

func _on_type_selected(index: int) -> void:
	var message = _crafting.handle_type_selected(index)
	_ui.set_status_text(message)

func _on_claim_pressed(index: int) -> void:
	var message = _crafting.handle_claim_pressed(index)
	_ui.set_status_text(message)
	_inventory.refresh_inventory()

func _on_forge_cores_changed(new_amount: int, _delta: int) -> void:
	_ui.update_forge_label()
	_update_buttons()

func _on_close_pressed() -> void:
	close()

# ===========================================
# INTERNAL METHODS
# ===========================================
func _refresh_inventory() -> void:
	_inventory.refresh_inventory()
	_update_buttons()

func _update_buttons() -> void:
	_ui.update_buttons(_inventory.get_selected_index())
	_crafting.update_craft_button()
	_ui.update_status_color()
	_crafting.update_crafting_slots()

func _process(delta: float) -> void:
	if visible:
		_crafting.update_crafting_slots()
