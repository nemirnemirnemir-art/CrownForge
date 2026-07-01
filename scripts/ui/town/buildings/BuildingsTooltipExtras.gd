extends RefCounted
class_name BuildingsTooltipExtras

const UnitInfoPanelScene: PackedScene = preload("res://scenes/ui/town/UnitInfoPanel.tscn")
const UpgradeItemPanelScene: PackedScene = preload("res://scenes/ui/town/UpgradeItemPanel.tscn")
const BuildingUpgradeDataScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeData.gd")
const BuildingUpgradeVisualsScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeVisuals.gd")
const BuildingUpgradeIconResolverScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeIconResolver.gd")
const UnitTraitLibraryScript := preload("res://scripts/ui/town/UnitTraitLibrary.gd")

func process(tooltip: BuildingsTooltip) -> void:
	if not tooltip.visible:
		return
	if tooltip._unit_panel_popup or tooltip._upgrade_popups.size() > 0:
		position_extras(tooltip)

func handle_visibility_changed(tooltip: BuildingsTooltip) -> void:
	if not tooltip.visible:
		clear_extras(tooltip)

func rebuild_extras(tooltip: BuildingsTooltip, config: BuildingConfig) -> void:
	clear_extras(tooltip)
	if not config:
		return
	tooltip._extras_parent = resolve_extras_parent(tooltip)
	if not tooltip._extras_parent:
		return

	var show_unit_panel := (
		config.building_type == BuildingConfig.BuildingType.MILITARY
		and not String(config.produced_unit_id).is_empty()
	)
	if show_unit_panel:
		tooltip._unit_panel_popup = UnitInfoPanelScene.instantiate() as UnitInfoPanel
		if tooltip._unit_panel_popup:
			tooltip._extras_parent.add_child(tooltip._unit_panel_popup)
			tooltip._unit_panel_popup.top_level = true
			tooltip._unit_panel_popup.z_index = tooltip.z_index
			tooltip._unit_panel_popup.setup(config.produced_unit_id)
			tooltip._unit_panel_popup.reset_size()

	var upgrades: Array = BuildingUpgradeDataScript.get_upgrades(config.building_id)
	for upgrade_index in range(upgrades.size()):
		var upgrade_data = upgrades[upgrade_index]
		if not _should_show_upgrade(config, upgrade_data):
			continue
		var upgrade_panel := UpgradeItemPanelScene.instantiate() as UpgradeItemPanel
		if upgrade_panel:
			tooltip._extras_parent.add_child(upgrade_panel)
			upgrade_panel.top_level = true
			upgrade_panel.z_index = tooltip.z_index
			upgrade_panel.setup(
				upgrade_data["name"],
				upgrade_data["desc"],
				BuildingUpgradeIconResolverScript.get_icon(config.building_id, upgrade_index),
				BuildingUpgradeVisualsScript.get_upgrade_color(config.building_id, upgrade_index)
			)
			upgrade_panel.reset_size()
			tooltip._upgrade_popups.append(upgrade_panel)

	tooltip.call_deferred("_position_extras")

func _should_show_upgrade(config: BuildingConfig, upgrade_data: Variant) -> bool:
	if not (upgrade_data is Dictionary):
		return true
	var unit_id := String(config.produced_unit_id).strip_edges().to_lower()
	if unit_id == "":
		return true
	var trait_text := UnitTraitLibraryScript.get_trait_text(unit_id)
	if trait_text == "":
		return true
	var data := upgrade_data as Dictionary
	var upgrade_text := String(data.get("desc", "")).strip_edges()
	if upgrade_text == "":
		upgrade_text = String(data.get("name", "")).strip_edges()
	return not UnitTraitLibraryScript.is_duplicate_trait_text(upgrade_text, trait_text)

func clear_extras(tooltip: BuildingsTooltip) -> void:
	if tooltip._unit_panel_popup:
		tooltip._unit_panel_popup.queue_free()
		tooltip._unit_panel_popup = null
	for p in tooltip._upgrade_popups:
		if p:
			p.queue_free()
	tooltip._upgrade_popups.clear()
	tooltip._extras_parent = null

func resolve_extras_parent(tooltip: BuildingsTooltip) -> CanvasItem:
	var tree := tooltip.get_tree()
	var main_ui: Node = null
	if tree and tree.current_scene:
		main_ui = tree.current_scene.get_node_or_null("UILayer/MainUI")
	if main_ui == null and tree:
		main_ui = tree.get_first_node_in_group("main_ui")
	if main_ui and main_ui.has_method("get_popup_layer"):
		var popup_layer = main_ui.call("get_popup_layer")
		if popup_layer is CanvasItem:
			return popup_layer
	if main_ui is CanvasItem:
		return main_ui as CanvasItem
	return tooltip.get_parent() as CanvasItem

func position_extras(tooltip: BuildingsTooltip) -> void:
	if not tooltip.visible:
		return
	var base_pos := tooltip.global_position
	var padding := 10.0
	if tooltip._unit_panel_popup:
		tooltip._unit_panel_popup.reset_size()
		tooltip._unit_panel_popup.global_position = base_pos + Vector2(tooltip.size.x + padding, 0)
	if tooltip._upgrade_popups.size() > 0:
		var upgrade_x := base_pos.x + tooltip.size.x + padding
		var upgrade_y := base_pos.y
		if tooltip._unit_panel_popup:
			upgrade_x = tooltip._unit_panel_popup.global_position.x + tooltip._unit_panel_popup.size.x + padding
			upgrade_y = tooltip._unit_panel_popup.global_position.y
		for p in tooltip._upgrade_popups:
			if not p:
				continue
			p.reset_size()
			p.global_position = Vector2(upgrade_x, upgrade_y)
			upgrade_y += p.size.y + 6.0
