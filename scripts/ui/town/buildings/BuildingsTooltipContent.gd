extends RefCounted
class_name BuildingsTooltipContent

const BuildingPresentationData := preload("res://scripts/ui/town/buildings/BuildingPresentationData.gd")

func setup_building(tooltip: BuildingsTooltip, building_id: String) -> void:
	tooltip._building_id = building_id
	var building_registry := tooltip._building_registry()
	var seal_registry := tooltip._seal_registry()
	var config: BuildingConfig = null
	if building_registry:
		config = building_registry.get_building(building_id)

	if not config and seal_registry:
		var seal_config = seal_registry.get_seal(building_id)
		if seal_config:
			setup_seal(tooltip, seal_config)
			return

	if not config:
		tooltip._name_label.text = building_id
		tooltip._description_label.text = "Config not found"
		return

	tooltip._name_label.text = config.display_name
	tooltip._timer_label.text = "%.2fs" % config.cycle_time

	var capacity_label = tooltip.get_node_or_null("Margin/VBox/ProductionInfo/CapacityLabel")
	var capacity_icon = tooltip._capacity_icon
	var show_cap := false
	var cap_value := 0

	if config.building_type == BuildingConfig.BuildingType.MILITARY:
		show_cap = true
		cap_value = config.max_units
	elif config.max_units > 0:
		show_cap = true
		cap_value = config.max_units

	if show_cap:
		if capacity_label:
			capacity_label.text = "/ %d" % cap_value
			capacity_label.show()
		if capacity_icon:
			capacity_icon.show()
	else:
		if capacity_label:
			capacity_label.hide()
		if capacity_icon:
			capacity_icon.hide()

	tooltip._update_production_display(config)
	tooltip._update_consumption_display(config)
	var description := BuildingPresentationData.get_description(config.building_id, config.description)
	tooltip._description_label.text = tooltip._get_clean_description(description)
	tooltip._description_label.visible = not tooltip._description_label.text.is_empty()
	tooltip._update_costs_display(config)
 
	if tooltip.show_extras:
		tooltip._extras_helper.rebuild_extras(tooltip, config)
	else:
		tooltip._extras_helper.clear_extras(tooltip)
 
	tooltip.call_deferred("_fit_to_content")

func setup_trade(tooltip: BuildingsTooltip, trade: Dictionary) -> void:
	tooltip._building_id = ""
	tooltip._extras_helper.clear_extras(tooltip)
	tooltip._name_label.text = "Market Exchange"
	var rate_text = "%d:%d" % [trade.amount, trade.to_amount]
	tooltip._timer_label.text = rate_text
	tooltip._timer_icon.text = "⇄"

	tooltip._clear_container(tooltip._input_list)
	tooltip._clear_container(tooltip._output_list)
	tooltip._arrow_icon.visible = false
	tooltip._clear_container(tooltip._prod_row_content)
	tooltip._clear_container(tooltip._cons_row_content)
	tooltip._prod_row.visible = false
	tooltip._cons_row.visible = false
	if tooltip._prod_row_icon:
		tooltip._prod_row_icon.visible = false
	if tooltip._cons_row_icon:
		tooltip._cons_row_icon.visible = false

	if trade.to_amount > 0:
		tooltip._add_resource_to_hbox(tooltip._prod_row_content, trade.to, trade.to_amount)
		tooltip._prod_row.visible = true
		if tooltip._prod_row_icon:
			tooltip._prod_row_icon.visible = true

	tooltip._add_resource_to_hbox(tooltip._cons_row_content, trade.id, trade.amount)
	tooltip._cons_row.visible = true
	if tooltip._cons_row_icon:
		tooltip._cons_row_icon.visible = true
	tooltip._description_label.text = "Exchange rate: %s" % rate_text
	tooltip._description_label.show()
	tooltip._cost_header.hide()
	tooltip._clear_container(tooltip._next_cost_box)
	if tooltip._capacity_label:
		tooltip._capacity_label.hide()
	if tooltip._capacity_icon:
		tooltip._capacity_icon.hide()
	tooltip.call_deferred("_fit_to_content")

func setup_seal(tooltip: BuildingsTooltip, config: SealConfig) -> void:
	tooltip._building_id = String(config.id)
	tooltip._extras_helper.clear_extras(tooltip)
	tooltip._name_label.text = config.display_name
	tooltip._timer_label.text = ""
	tooltip._timer_icon.text = ""
	tooltip._clear_container(tooltip._prod_row_content)
	tooltip._clear_container(tooltip._cons_row_content)
	tooltip._clear_container(tooltip._next_cost_box)
	tooltip._prod_row.visible = false
	tooltip._cons_row.visible = false
	if tooltip._capacity_label:
		tooltip._capacity_label.hide()
	if tooltip._capacity_icon:
		tooltip._capacity_icon.hide()
	tooltip._description_label.text = config.description
	tooltip._description_label.show()
	tooltip._update_seal_costs(config)
	tooltip.call_deferred("_fit_to_content")

func refresh_costs_for_current_target(tooltip: BuildingsTooltip) -> void:
	if not tooltip.visible:
		return
	if tooltip._building_id == "":
		return
	var building_registry := tooltip._building_registry()
	if building_registry:
		var config = building_registry.get_building(tooltip._building_id)
		if config:
			tooltip._update_costs_display(config)
			return
	var seal_registry := tooltip._seal_registry()
	if seal_registry:
		var seal_config = seal_registry.get_seal(tooltip._building_id)
		if seal_config:
			tooltip._update_seal_costs(seal_config)
