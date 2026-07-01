extends RefCounted
class_name MainUITownOverlays

const TownInventoryPanelScene: PackedScene = preload("res://scenes/ui/town/TownInventoryPanel.tscn")
const SmithCraftPanelScene: PackedScene = preload("res://scenes/ui/town/SmithCraftPanel.tscn")
const BuildingUpgradePopupScene: PackedScene = preload("res://scenes/ui/town/BuildingUpgradePopup.tscn")
const AlchemistCraftPanelScene: PackedScene = preload("res://scenes/ui/town/AlchemistCraftPanel.tscn")

var _parent: Control = null
var _inventory_overlay: TownInventoryPanel = null
var _smith_overlay: SmithCraftPanel = null
var _alchemy_popup: BuildingUpgradePopup = null
var _alchemy_overlay: AlchemistCraftPanel = null

var _on_overlay_changed: Callable = Callable()

func initialize(parent: Control, on_overlay_changed: Callable) -> void:
	_parent = parent
	_on_overlay_changed = on_overlay_changed

func open_inventory() -> void:
	var panel := _ensure_inventory_panel()
	if panel:
		panel.open()
		_notify_overlay_changed()

func open_storage_inventory() -> void:
	open_inventory()

func open_smith() -> void:
	var panel := _ensure_smith_panel()
	if panel:
		panel.open()
		_notify_overlay_changed()

func open_alchemy() -> void:
	var panel := _ensure_alchemist_panel()
	if panel:
		panel.open()
		_notify_overlay_changed()

func _ensure_inventory_panel() -> TownInventoryPanel:
	if _inventory_overlay and is_instance_valid(_inventory_overlay):
		return _inventory_overlay
	if not TownInventoryPanelScene:
		return null
	_inventory_overlay = TownInventoryPanelScene.instantiate()
	_inventory_overlay.name = "InventoryOverlay"
	_parent.add_child(_inventory_overlay)
	_inventory_overlay.hide()
	if not _inventory_overlay.visibility_changed.is_connected(_on_panel_visibility_changed):
		_inventory_overlay.visibility_changed.connect(_on_panel_visibility_changed)
	return _inventory_overlay

func _ensure_smith_panel() -> SmithCraftPanel:
	if _smith_overlay and is_instance_valid(_smith_overlay):
		return _smith_overlay
	if not SmithCraftPanelScene:
		return null
	_smith_overlay = SmithCraftPanelScene.instantiate()
	_smith_overlay.name = "SmithOverlay"
	_parent.add_child(_smith_overlay)
	_smith_overlay.hide()
	if not _smith_overlay.visibility_changed.is_connected(_on_panel_visibility_changed):
		_smith_overlay.visibility_changed.connect(_on_panel_visibility_changed)
	return _smith_overlay

func _ensure_alchemy_popup() -> BuildingUpgradePopup:
	if _alchemy_popup and is_instance_valid(_alchemy_popup):
		return _alchemy_popup
	if not BuildingUpgradePopupScene:
		return null
	_alchemy_popup = BuildingUpgradePopupScene.instantiate()
	_alchemy_popup.name = "AlchemyPopup"
	_parent.add_child(_alchemy_popup)
	_alchemy_popup.hide()
	if not _alchemy_popup.visibility_changed.is_connected(_on_panel_visibility_changed):
		_alchemy_popup.visibility_changed.connect(_on_panel_visibility_changed)
	return _alchemy_popup

func _ensure_alchemist_panel() -> AlchemistCraftPanel:
	if _alchemy_overlay and is_instance_valid(_alchemy_overlay):
		return _alchemy_overlay
	if not AlchemistCraftPanelScene:
		return null
	_alchemy_overlay = AlchemistCraftPanelScene.instantiate()
	_alchemy_overlay.name = "AlchemistOverlay"
	_parent.add_child(_alchemy_overlay)
	_alchemy_overlay.hide()
	if not _alchemy_overlay.visibility_changed.is_connected(_on_panel_visibility_changed):
		_alchemy_overlay.visibility_changed.connect(_on_panel_visibility_changed)
	return _alchemy_overlay

func _on_panel_visibility_changed() -> void:
	_notify_overlay_changed()

func _notify_overlay_changed() -> void:
	if _on_overlay_changed.is_valid():
		_on_overlay_changed.call()

func is_any_overlay_visible() -> bool:
	if _inventory_overlay and is_instance_valid(_inventory_overlay) and _inventory_overlay.visible:
		return true
	if _smith_overlay and is_instance_valid(_smith_overlay) and _smith_overlay.visible:
		return true
	if _alchemy_popup and is_instance_valid(_alchemy_popup) and _alchemy_popup.visible:
		return true
	if _alchemy_overlay and is_instance_valid(_alchemy_overlay) and _alchemy_overlay.visible:
		return true
	return false

static func is_alchemist_built(parent: Control) -> bool:
	if not TownCore:
		return false
	var level := TownCore.get_building_level("alchemist")
	if level > 0:
		return true
	var tree := parent.get_tree()
	if tree == null:
		return false
	var building_menu: Node = tree.get_first_node_in_group("building_menu")
	if building_menu and building_menu.has_method("has_built_alchemist"):
		return building_menu.has_built_alchemist()
	return false
