extends RefCounted
class_name MapSlotActionUIFlow

const RewardPresentationRegistryScript := preload("res://scripts/ui/rewards/RewardPresentationRegistry.gd")


func on_market_action_pressed(market_ui: Control, basic_construction_ui: Control, research_table_ui: Control, position_popup_callback: Callable, close_other_special_popups: Callable = Callable(), cancel_vzor_drag: Callable = Callable(), refresh_visibility: Callable = Callable()) -> void:
	if market_ui == null:
		return
	var should_open := not market_ui.visible
	if should_open and cancel_vzor_drag.is_valid():
		cancel_vzor_drag.call()
	if should_open and close_other_special_popups.is_valid():
		close_other_special_popups.call(market_ui)
	if position_popup_callback.is_valid():
		position_popup_callback.call(market_ui, true)
	market_ui.visible = should_open
	if basic_construction_ui:
		basic_construction_ui.visible = false
	if research_table_ui:
		research_table_ui.visible = false
	if refresh_visibility.is_valid():
		refresh_visibility.call()


func on_trade_requested(resource_id: String, market, market_ui: Control, update_market_visuals: Callable) -> void:
	if market:
		market.set_active_resource(resource_id)
		if update_market_visuals.is_valid():
			update_market_visuals.call()
	if market_ui:
		market_ui.visible = false


func on_basic_construction_target_requested(building_id: String, special_handler: RefCounted, basic_construction_ui: Control, research_table_ui: Control, save_core) -> bool:
	if building_id == "":
		if basic_construction_ui:
			basic_construction_ui.visible = false
		return true
	if special_handler == null or not special_handler.has_method("convert_to"):
		return false
	if not bool(special_handler.call("convert_to", building_id)):
		return false
	if basic_construction_ui:
		basic_construction_ui.visible = false
	if research_table_ui:
		research_table_ui.visible = false
	if save_core and save_core.has_method("request_save"):
		save_core.request_save()
	return true


func on_basic_construction_close_requested(basic_construction_ui: Control) -> void:
	if basic_construction_ui:
		basic_construction_ui.visible = false


func on_basic_action_pressed(toggle_basic_popup: Callable) -> void:
	if toggle_basic_popup.is_valid():
		toggle_basic_popup.call()


func update_basic_construction_visuals(current_building_id: String, basic_action_btn: Button, special_handler: RefCounted, basic_construction_ui: Control = null) -> void:
	if basic_action_btn == null:
		return
	var show_button := false
	if current_building_id == "basic_construction" and special_handler and special_handler.has_method("is_ready"):
		show_button = bool(special_handler.call("is_ready"))
	if basic_construction_ui and basic_construction_ui.visible:
		show_button = false
	basic_action_btn.visible = show_button
	if show_button:
		basic_action_btn.text = "Nothing"


func update_market_action_visibility(current_building_id: String, market_action_btn: Button, market_ui: Control = null) -> void:
	if market_action_btn == null:
		return
	market_action_btn.visible = current_building_id == "market" and (market_ui == null or not market_ui.visible)


func update_market_visuals(market_action_btn: Button, market, animations) -> void:
	if market_action_btn == null or market == null:
		return
	if market_action_btn.has_method("show_empty_state") and market_action_btn.has_method("show_active_resource"):
		var active_resource := String(market.get_active_resource())
		if active_resource == "":
			market_action_btn.call("show_empty_state")
		else:
			market_action_btn.call("show_active_resource", active_resource)
		return
	var icon_node = market_action_btn.get_node_or_null("Icon")
	var active_res = market.get_active_resource()
	if active_res == "":
		if icon_node:
			icon_node.texture = null
		return
	if icon_node and animations and animations.has_method("_get_resource_icon_texture"):
		icon_node.texture = animations._get_resource_icon_texture(active_res)


func update_research_table_visuals(current_building_id: String, research_mode_badge: Control, special_handler: RefCounted, research_table_ui: Control = null) -> void:
	if research_mode_badge == null:
		return
	var is_research_building := current_building_id == "research_table" or current_building_id == "research_laboratory"
	research_mode_badge.visible = is_research_building and (research_table_ui == null or not research_table_ui.visible)
	if not is_research_building:
		return
	var icon_node := research_mode_badge.get_node_or_null("Icon") as TextureRect
	if icon_node == null:
		return
	var reward_type := -1
	if special_handler and special_handler.has_method("get_current_reward_type"):
		reward_type = int(special_handler.call("get_current_reward_type"))
	icon_node.texture = RewardPresentationRegistryScript.get_reward_icon(reward_type) if reward_type >= 0 else null
