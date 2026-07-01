extends Panel
class_name RewardBuildingUpgradeCard

signal selected(slot_index: int, upgrade_id: String)

const BuildingsTooltipScript := preload("res://scripts/ui/town/BuildingsTooltip.gd")
const BuildingUpgradeVisualsScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeVisuals.gd")
const BuildingUpgradeIconResolverScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeIconResolver.gd")

@onready var icon_rect: TextureRect = get_node_or_null("BuildingFrame/Icon")
@onready var name_label: Label = get_node_or_null("NamePlate/NameLabel")
@onready var offer_title: Label = get_node_or_null("BodyPanel/OfferTitleBar/OfferTitle")
@onready var offer_desc: Label = get_node_or_null("BodyPanel/OfferDescription")
@onready var choose_button: Button = get_node_or_null("BodyPanel/ChooseButton")

@onready var slot_1: ColorRect = get_node_or_null("UpgradesRow/Upgrade1")
@onready var slot_2: ColorRect = get_node_or_null("UpgradesRow/Upgrade2")
@onready var slot_3: ColorRect = get_node_or_null("UpgradesRow/Upgrade3")

@onready var slot_icon_1: TextureRect = get_node_or_null("UpgradesRow/Upgrade1/SlotIcon")
@onready var slot_icon_2: TextureRect = get_node_or_null("UpgradesRow/Upgrade2/SlotIcon")
@onready var slot_icon_3: TextureRect = get_node_or_null("UpgradesRow/Upgrade3/SlotIcon")

@onready var dim_overlay_1: ColorRect = get_node_or_null("UpgradesRow/Upgrade1/DimOverlay")
@onready var dim_overlay_2: ColorRect = get_node_or_null("UpgradesRow/Upgrade2/DimOverlay")
@onready var dim_overlay_3: ColorRect = get_node_or_null("UpgradesRow/Upgrade3/DimOverlay")

@onready var offer_visual: ColorRect = get_node_or_null("OfferVisualFrame/OfferVisual")
@onready var offer_icon: TextureRect = get_node_or_null("OfferVisualFrame/OfferVisual/OfferIcon")

@onready var upgrade_tooltip: Control = get_node_or_null("UpgradeTooltip")
@onready var tooltip_title: Label = get_node_or_null("UpgradeTooltip/Margin/VBox/Title")
@onready var tooltip_desc: Label = get_node_or_null("UpgradeTooltip/Margin/VBox/Desc")

var _slot_index: int = -1
var _building_id: String = ""
var _offer_upgrade_index: int = -1
var _upgrade_defs: Array = []

func _get_autoload(autoload_name: String) -> Node:
	return get_node_or_null("/root/%s" % autoload_name)

func _building_registry() -> Node:
	return _get_autoload("BuildingRegistry")

func _building_upgrade_core() -> Node:
	return _get_autoload("BuildingUpgradeCore")

func _ready() -> void:
	if choose_button:
		choose_button.pressed.connect(_on_choose_pressed)
	_setup_upgrade_slot_hover(slot_1, 0)
	_setup_upgrade_slot_hover(slot_2, 1)
	_setup_upgrade_slot_hover(slot_3, 2)
	if upgrade_tooltip:
		upgrade_tooltip.visible = false

func setup(slot_index: int, building_id: String, offer_upgrade_index: int, upgrade_defs: Array) -> void:
	_slot_index = slot_index
	_building_id = building_id
	_offer_upgrade_index = offer_upgrade_index
	_upgrade_defs = upgrade_defs

	var config: BuildingConfig = null
	var building_registry := _building_registry()
	if building_registry:
		config = building_registry.get_building(_building_id)
	if icon_rect:
		icon_rect.texture = config.get_icon_or_placeholder() if config else null
	if name_label:
		name_label.text = config.display_name if config and config.display_name != "" else _building_id

	_update_upgrade_slots()
	_update_offer_text()
	_update_offer_visual()

func _get_upgrade_id_for_index(idx: int) -> String:
	return "%s:%d" % [_building_id, idx]

func _update_offer_text() -> void:
	var t := ""
	var d := ""
	if _offer_upgrade_index >= 0 and _offer_upgrade_index < _upgrade_defs.size():
		var def: Variant = _upgrade_defs[_offer_upgrade_index]
		if def is Dictionary:
			t = str((def as Dictionary).get("name", "Upgrade"))
			d = str((def as Dictionary).get("desc", ""))
	else:
		t = "Upgrade"
		d = ""

	if offer_title:
		offer_title.text = t
	if offer_desc:
		offer_desc.text = d
	if choose_button:
		choose_button.disabled = _offer_upgrade_index < 0

func _update_offer_visual() -> void:
	if offer_visual == null:
		return
	if _offer_upgrade_index < 0:
		offer_visual.color = BuildingUpgradeVisualsScript.STATUS_COLOR_MISSING
		if offer_icon:
			offer_icon.texture = null
		return
	offer_visual.color = BuildingUpgradeVisualsScript.get_upgrade_color(_building_id, _offer_upgrade_index)
	if offer_icon:
		offer_icon.texture = BuildingUpgradeIconResolverScript.get_icon(_building_id, _offer_upgrade_index)

func _update_upgrade_slots() -> void:
	var slots := [slot_1, slot_2, slot_3]
	var icons := [slot_icon_1, slot_icon_2, slot_icon_3]
	var overlays := [dim_overlay_1, dim_overlay_2, dim_overlay_3]
	var upgrade_core := _building_upgrade_core()

	for i in range(slots.size()):
		var rect: ColorRect = slots[i]
		if rect == null:
			continue

		var icon_node: TextureRect = icons[i] if i < icons.size() else null
		var overlay_node: ColorRect = overlays[i] if i < overlays.size() else null

		if i >= _upgrade_defs.size():
			# Empty slot — no upgrade definition exists for this index
			rect.color = BuildingUpgradeVisualsScript.SLOT_COLOR_EMPTY
			if icon_node:
				icon_node.texture = null
			if overlay_node:
				overlay_node.visible = false
			continue

		var upgrade_id := _get_upgrade_id_for_index(i)
		var applied := bool(upgrade_core.call("has_building_upgrade", _building_id, upgrade_id)) if upgrade_core else false

		# Background color reflects unlock status
		rect.color = BuildingUpgradeVisualsScript.SLOT_COLOR_UNLOCKED if applied else BuildingUpgradeVisualsScript.SLOT_COLOR_LOCKED

		# Set upgrade icon (null if no asset available — background color still shows)
		if icon_node:
			icon_node.texture = BuildingUpgradeIconResolverScript.get_icon(_building_id, i)

		# Dim overlay: visible for locked upgrades, hidden for unlocked
		if overlay_node:
			overlay_node.visible = not applied

func _setup_upgrade_slot_hover(rect: ColorRect, idx: int) -> void:
	if rect == null:
		return
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	rect.mouse_entered.connect(_on_upgrade_slot_hover_entered.bind(idx, rect))
	rect.mouse_exited.connect(_on_upgrade_slot_hover_exited)

func _on_upgrade_slot_hover_entered(idx: int, slot_node: ColorRect) -> void:
	if upgrade_tooltip == null:
		return

	var title := ""
	var desc := ""
	if idx < 0 or idx >= _upgrade_defs.size():
		title = "Locked"
		desc = ""
	else:
		var def: Variant = _upgrade_defs[idx]
		if def is Dictionary:
			title = str((def as Dictionary).get("name", "Upgrade"))
			desc = str((def as Dictionary).get("desc", ""))

	if tooltip_title:
		tooltip_title.text = title
	if tooltip_desc:
		tooltip_desc.text = desc

	upgrade_tooltip.visible = true
	upgrade_tooltip.reset_size()

	# Position tooltip centered above the hovered slot
	var slot_global_rect := slot_node.get_global_rect()
	var tooltip_size := upgrade_tooltip.get_combined_minimum_size()
	if tooltip_size == Vector2.ZERO:
		tooltip_size = upgrade_tooltip.size

	var target_pos := Vector2(
		slot_global_rect.position.x + (slot_global_rect.size.x - tooltip_size.x) * 0.5,
		slot_global_rect.position.y - tooltip_size.y - 8.0
	)

	# Clamp to viewport bounds
	var viewport := get_viewport()
	if viewport:
		var visible_rect := viewport.get_visible_rect()
		target_pos.x = clampf(target_pos.x, visible_rect.position.x + 8.0, visible_rect.end.x - tooltip_size.x - 8.0)
		target_pos.y = clampf(target_pos.y, visible_rect.position.y + 8.0, visible_rect.end.y - tooltip_size.y - 8.0)

	upgrade_tooltip.global_position = target_pos

func _on_upgrade_slot_hover_exited() -> void:
	if upgrade_tooltip:
		upgrade_tooltip.visible = false

func _on_choose_pressed() -> void:
	if _slot_index < 0:
		return
	if _offer_upgrade_index < 0:
		return
	if _offer_upgrade_index >= _upgrade_defs.size():
		return
	var upgrade_id := _get_upgrade_id_for_index(_offer_upgrade_index)
	selected.emit(_slot_index, upgrade_id)
