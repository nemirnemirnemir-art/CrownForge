extends SceneTree

const CARD_SCENE := preload("res://scenes/ui/rewards/RewardBuildingUpgradeCard.tscn")
const BUILDING_UPGRADE_DATA := preload("res://scripts/ui/town/buildings/BuildingUpgradeData.gd")
const EXPECTED_WORKING_COLOR := Color(0.25, 0.8, 0.35, 1.0)
const EXPECTED_LOCKED_COLOR := Color(0.45, 0.45, 0.45, 1.0)
const EXPECTED_EMPTY_COLOR := Color(0.95, 0.95, 0.95, 1.0)

var _failed := false

func _upgrade_core() -> Node:
	return get_root().get_node_or_null("BuildingUpgradeCore")

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_reward_building_upgrade_card_runtime] %s" % message)
	quit(1)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var card := CARD_SCENE.instantiate() as Control
	if card == null:
		_fail("Failed to instantiate RewardBuildingUpgradeCard")
		return
	get_root().add_child(card)
	await process_frame

	var upgrade_core := _upgrade_core()
	if upgrade_core:
		upgrade_core.call("load_save_data", {"upgrades_by_slot": {}})
		upgrade_core.call("unlock_building_upgrade", "concert", "concert:0")

	var defs := BUILDING_UPGRADE_DATA.get_upgrades("concert")
	card.call("setup", 1, "concert", 0, defs)
	await process_frame

	var offer_visual := card.get_node_or_null("OfferVisualFrame/OfferVisual") as ColorRect
	if offer_visual == null:
		_fail("RewardBuildingUpgradeCard must expose OfferVisual placeholder")
		return
	if offer_visual.color != EXPECTED_WORKING_COLOR:
		_fail("OfferVisual must use working-status green for implemented concert upgrade")
		return

	var upgrade_1 := card.get_node_or_null("UpgradesRow/Upgrade1") as ColorRect
	var upgrade_2 := card.get_node_or_null("UpgradesRow/Upgrade2") as ColorRect
	var upgrade_3 := card.get_node_or_null("UpgradesRow/Upgrade3") as ColorRect
	var description_label := card.get_node_or_null("BodyPanel/OfferDescription") as Label
	var choose_button := card.get_node_or_null("BodyPanel/ChooseButton") as Button
	if upgrade_1 == null or upgrade_2 == null or upgrade_3 == null:
		_fail("RewardBuildingUpgradeCard must expose three upgrade slot indicators")
		return
	if description_label == null or choose_button == null:
		_fail("RewardBuildingUpgradeCard must expose description and choose button nodes")
		return
	if upgrade_1.color != EXPECTED_WORKING_COLOR:
		_fail("Taken upgrade slot must be green")
		return
	if upgrade_2.color != EXPECTED_LOCKED_COLOR:
		_fail("Existing but untaken upgrade slot must be gray")
		return
	if upgrade_3.color != EXPECTED_EMPTY_COLOR:
		_fail("Missing upgrade slot must be white")
		return

	# --- New structural checks for icon slots and overlays ---

	var slot_icon_1 := card.get_node_or_null("UpgradesRow/Upgrade1/SlotIcon") as TextureRect
	var slot_icon_2 := card.get_node_or_null("UpgradesRow/Upgrade2/SlotIcon") as TextureRect
	var slot_icon_3 := card.get_node_or_null("UpgradesRow/Upgrade3/SlotIcon") as TextureRect
	if slot_icon_1 == null or slot_icon_2 == null or slot_icon_3 == null:
		_fail("Each upgrade slot must have a SlotIcon TextureRect child")
		return

	var dim_overlay_1 := card.get_node_or_null("UpgradesRow/Upgrade1/DimOverlay") as ColorRect
	var dim_overlay_2 := card.get_node_or_null("UpgradesRow/Upgrade2/DimOverlay") as ColorRect
	var dim_overlay_3 := card.get_node_or_null("UpgradesRow/Upgrade3/DimOverlay") as ColorRect
	if dim_overlay_1 == null or dim_overlay_2 == null or dim_overlay_3 == null:
		_fail("Each upgrade slot must have a DimOverlay ColorRect child")
		return

	# Unlocked upgrade (concert:0): overlay should be hidden
	if dim_overlay_1.visible:
		_fail("DimOverlay for unlocked upgrade slot must be hidden")
		return
	# Locked upgrade (concert:1): overlay should be visible
	if not dim_overlay_2.visible:
		_fail("DimOverlay for locked upgrade slot must be visible")
		return
	# Empty slot (no upgrade def): overlay should be hidden
	if dim_overlay_3.visible:
		_fail("DimOverlay for empty upgrade slot must be hidden")
		return

	# --- Tooltip structure check (new PanelContainer layout) ---

	var tooltip_node := card.get_node_or_null("UpgradeTooltip") as PanelContainer
	if tooltip_node == null:
		_fail("UpgradeTooltip must be a PanelContainer")
		return
	var tooltip_title := card.get_node_or_null("UpgradeTooltip/Margin/VBox/Title") as Label
	var tooltip_desc := card.get_node_or_null("UpgradeTooltip/Margin/VBox/Desc") as Label
	if tooltip_title == null or tooltip_desc == null:
		_fail("UpgradeTooltip must contain Margin/VBox/Title and Margin/VBox/Desc labels")
		return

	# --- Slot size check (should be >= 72x72) ---

	if upgrade_1.custom_minimum_size.x < 72.0 or upgrade_1.custom_minimum_size.y < 72.0:
		_fail("Upgrade slot minimum size must be at least 72x72, got %s" % str(upgrade_1.custom_minimum_size))
		return

	# --- Font check: NameLabel should use ThaleahFat and bigger font size ---

	var name_label := card.get_node_or_null("NamePlate/NameLabel") as Label
	if name_label:
		var font_size_override: int = name_label.get_theme_font_size("font_size")
		if font_size_override < 22:
			_fail("NameLabel font_size must be at least 22 (25%% increase from 18), got %d" % font_size_override)
			return

	if choose_button.size.x > 160.0:
		_fail("Choose button must be compact, got width %.1f" % choose_button.size.x)
		return
	if choose_button.global_position.y < description_label.global_position.y + description_label.size.y + 12.0:
		_fail("Choose button must stay clearly below upgrade description")
		return

	print("[test_reward_building_upgrade_card_runtime] PASS")
	quit(0)
