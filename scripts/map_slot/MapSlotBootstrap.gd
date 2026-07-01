extends RefCounted
class_name MapSlotBootstrap

const MapSlotUIScript := preload("res://scripts/map_slot/MapSlotUI.gd")


func initialize_modules(slot, create_production: Callable, create_market: Callable, create_seal_logic: Callable, create_military_tracker: Callable, create_animations: Callable, create_helpers: Array) -> void:
	slot._production = create_production.call()
	if slot._production and slot._production.has_signal("production_completed"):
		slot._production.production_completed.connect(Callable(slot, "_on_production_completed"))
	if slot._production and slot._production.has_signal("hero_produced"):
		slot._production.hero_produced.connect(Callable(slot, "_on_hero_produced"))

	slot._market = create_market.call()
	if slot._market and slot._market.has_signal("trade_completed"):
		slot._market.trade_completed.connect(Callable(slot, "_on_trade_completed"))

	slot._seal_logic = create_seal_logic.call()
	if slot._seal_logic and slot._seal_logic.has_method("initialize"):
		slot._seal_logic.initialize(slot, slot._production)

	slot._military_tracker = create_military_tracker.call()
	slot._animations = create_animations.call()
	if slot._animations and slot._animations.has_method("initialize"):
		slot._animations.initialize(slot)

	if create_helpers.size() >= 7:
		slot._popup_controller = create_helpers[0].call()
		slot._special_runtime = create_helpers[1].call()
		slot._building_lifecycle = create_helpers[2].call()
		slot._interaction_controller = create_helpers[3].call()
		slot._production_flow = create_helpers[4].call()
		slot._special_flow = create_helpers[5].call()
		slot._feedback_flow = create_helpers[6].call()
		if create_helpers.size() > 7:
			slot._action_ui_flow = create_helpers[7].call()
		if create_helpers.size() > 8:
			slot._vzor_visual_flow = create_helpers[8].call()
		if create_helpers.size() > 9:
			slot._tick_routing = create_helpers[9].call()
		if create_helpers.size() > 10:
			slot._building_config_flow = create_helpers[10].call()


func setup_ui_nodes(slot) -> void:
	var overlay_size := Vector2(72.0, 24.0)
	var overlay_x := -overlay_size.x * 0.5

	slot._unit_count_label = Label.new()
	slot._unit_count_label.name = "UnitCountLabel"
	slot.add_child(slot._unit_count_label)
	slot._unit_count_label.position = Vector2(overlay_x, -32.0)
	slot._unit_count_label.custom_minimum_size = overlay_size
	slot._unit_count_label.size = overlay_size
	slot._unit_count_label.add_theme_font_size_override("font_size", 21)
	slot._unit_count_label.add_theme_color_override("font_color", Color.WHITE)
	slot._unit_count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	slot._unit_count_label.add_theme_constant_override("outline_size", 4)
	slot._unit_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot._unit_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot._unit_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot._unit_count_label.z_as_relative = false
	slot._unit_count_label.z_index = 3000
	slot._unit_count_label.visible = false

	slot._durability_label = Label.new()
	slot._durability_label.name = "DurabilityLabel"
	slot.add_child(slot._durability_label)
	slot._durability_label.position = Vector2(overlay_x, -28.0)
	slot._durability_label.custom_minimum_size = overlay_size
	slot._durability_label.size = overlay_size
	slot._durability_label.add_theme_font_size_override("font_size", 21)
	slot._durability_label.add_theme_color_override("font_color", Color.WHITE)
	slot._durability_label.add_theme_color_override("font_outline_color", Color.BLACK)
	slot._durability_label.add_theme_constant_override("outline_size", 4)
	slot._durability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot._durability_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot._durability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot._durability_label.z_as_relative = false
	slot._durability_label.z_index = 3000
	slot._durability_label.visible = false

	slot._ui = MapSlotUIScript.new()
	slot._ui.initialize(slot.progress_bar, slot.radial_progress, slot._unit_count_label, slot._durability_label)


func setup_market_features(slot) -> void:
	slot._market_action_btn = Button.new()
	slot._market_action_btn.name = "MarketActionBtn"
	slot._market_action_btn.custom_minimum_size = Vector2(44, 44)
	slot._market_action_btn.size = Vector2(44, 44)
	slot._market_action_btn.position = Vector2(2, -38)
	slot._market_action_btn.text = ""
	slot._market_action_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var market_style := StyleBoxFlat.new()
	market_style.bg_color = Color(0.93, 0.93, 0.93, 0.98)
	market_style.border_color = Color(0.1, 0.1, 0.1, 1.0)
	market_style.set_border_width_all(3)
	market_style.set_corner_radius_all(3)
	slot._market_action_btn.add_theme_stylebox_override("normal", market_style)
	slot._market_action_btn.add_theme_stylebox_override("hover", market_style.duplicate())
	slot._market_action_btn.add_theme_stylebox_override("pressed", market_style.duplicate())
	slot._market_action_btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05, 1.0))
	var market_under := TextureRect.new()
	market_under.name = "Under"
	market_under.texture = slot.UnderTexture
	market_under.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	market_under.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	market_under.anchor_right = 1.0
	market_under.anchor_bottom = 1.0
	market_under.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot._market_action_btn.add_child(market_under)
	var market_icon := TextureRect.new()
	market_icon.name = "Icon"
	market_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	market_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	market_icon.anchor_left = 0.15
	market_icon.anchor_top = 0.15
	market_icon.anchor_right = 0.85
	market_icon.anchor_bottom = 0.85
	market_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot._market_action_btn.add_child(market_icon)
	var market_label := Label.new()
	market_label.name = "ModeLabel"
	market_label.text = "Nothing"
	market_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	market_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	market_label.anchor_left = 0.0
	market_label.anchor_top = 1.0
	market_label.anchor_right = 1.0
	market_label.anchor_bottom = 1.0
	market_label.offset_top = 2.0
	market_label.offset_bottom = 18.0
	market_label.add_theme_font_size_override("font_size", 10)
	market_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot._market_action_btn.add_child(market_label)
	slot.add_child(slot._market_action_btn)
	slot._market_action_btn.z_as_relative = false
	slot._market_action_btn.z_index = 3002
	slot._market_action_btn.pressed.connect(Callable(slot, "_on_market_action_pressed"))
	slot._market_action_btn.visible = false
	if slot.has_method("_instantiate_market_ui"):
		slot._market_ui = slot._instantiate_market_ui()
	if slot._market_ui:
		slot.add_child(slot._market_ui)
		slot._market_ui.add_to_group("map_slot_special_popup")
		slot._market_ui.set_meta("slot_owner", slot)
		slot._market_ui.z_as_relative = false
		slot._market_ui.z_index = 3001
		slot._market_ui.top_level = true
		slot._market_ui.visible = false
		if slot._market_ui.has_signal("trade_requested"):
			slot._market_ui.trade_requested.connect(Callable(slot, "_on_trade_requested"))
		if slot._market_ui.has_signal("close_requested"):
			slot._market_ui.close_requested.connect(func() -> void:
				slot._close_special_popup(slot._market_ui)
			)


func setup_basic_construction_features(slot) -> void:
	if slot.BasicConstructionUIScene:
		slot._basic_construction_ui = slot.BasicConstructionUIScene.instantiate()
		slot.add_child(slot._basic_construction_ui)
		slot._basic_construction_ui.add_to_group("map_slot_special_popup")
		slot._basic_construction_ui.set_meta("slot_owner", slot)
		slot._basic_construction_ui.position = Vector2(42, -118)
		slot._basic_construction_ui.top_level = true
		slot._basic_construction_ui.z_as_relative = false
		slot._basic_construction_ui.z_index = 3001
		slot._basic_construction_ui.visible = false
		if slot._basic_construction_ui.has_signal("target_requested"):
			slot._basic_construction_ui.target_requested.connect(Callable(slot, "_on_basic_construction_target_requested"))
		if slot._basic_construction_ui.has_signal("close_requested"):
			slot._basic_construction_ui.close_requested.connect(Callable(slot, "_on_basic_construction_close_requested"))

	slot._basic_action_btn = Button.new()
	slot._basic_action_btn.name = "BasicConstructionActionBtn"
	slot._basic_action_btn.custom_minimum_size = Vector2(44, 44)
	slot._basic_action_btn.size = Vector2(44, 44)
	slot._basic_action_btn.position = Vector2(2, -38)
	slot._basic_action_btn.text = ""
	slot._basic_action_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot._basic_action_btn.visible = false
	slot._basic_action_btn.z_as_relative = false
	slot._basic_action_btn.z_index = 3002
	var basic_style := StyleBoxFlat.new()
	basic_style.bg_color = Color(0.93, 0.93, 0.93, 0.98)
	basic_style.border_color = Color(0.1, 0.1, 0.1, 1.0)
	basic_style.set_border_width_all(3)
	basic_style.set_corner_radius_all(3)
	slot._basic_action_btn.add_theme_stylebox_override("normal", basic_style)
	slot._basic_action_btn.add_theme_stylebox_override("hover", basic_style.duplicate())
	slot._basic_action_btn.add_theme_stylebox_override("pressed", basic_style.duplicate())
	slot._basic_action_btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05, 1.0))
	slot._basic_action_btn.add_theme_font_size_override("font_size", 11)
	var basic_under := TextureRect.new()
	basic_under.name = "UnderIcon"
	basic_under.texture = slot.UnderTexture
	basic_under.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	basic_under.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	basic_under.anchor_right = 1.0
	basic_under.anchor_bottom = 1.0
	basic_under.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot._basic_action_btn.add_child(basic_under)
	slot.add_child(slot._basic_action_btn)
	slot._basic_action_btn.pressed.connect(Callable(slot, "_on_basic_action_pressed"))


func setup_research_table_features(slot) -> void:
	if slot.ResearchTableUIScene:
		slot._research_table_ui = slot.ResearchTableUIScene.instantiate()
		slot.add_child(slot._research_table_ui)
		slot._research_table_ui.add_to_group("map_slot_special_popup")
		slot._research_table_ui.set_meta("slot_owner", slot)
		slot._position_popup_near_slot(slot._research_table_ui, true)
		slot._research_table_ui.top_level = true
		slot._research_table_ui.z_as_relative = false
		slot._research_table_ui.z_index = 3001
		slot._research_table_ui.visible = false
		if slot._research_table_ui.has_signal("mode_requested"):
			slot._research_table_ui.mode_requested.connect(Callable(slot, "_on_research_mode_requested"))
		if slot._research_table_ui.has_signal("close_requested"):
			slot._research_table_ui.close_requested.connect(func() -> void:
				slot._close_special_popup(slot._research_table_ui)
			)

	slot._research_mode_badge = Button.new()
	slot._research_mode_badge.name = "ResearchModeBadge"
	slot._research_mode_badge.custom_minimum_size = Vector2(44, 44)
	slot._research_mode_badge.size = Vector2(44, 44)
	slot._research_mode_badge.position = Vector2(2, -38)
	slot._research_mode_badge.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot._research_mode_badge.z_as_relative = false
	slot._research_mode_badge.z_index = 3002
	slot._research_mode_badge.visible = false
	slot.add_child(slot._research_mode_badge)
	var research_style := StyleBoxFlat.new()
	research_style.bg_color = Color(0.93, 0.93, 0.93, 0.98)
	research_style.border_color = Color(0.1, 0.1, 0.1, 1.0)
	research_style.set_border_width_all(3)
	research_style.set_corner_radius_all(3)
	slot._research_mode_badge.add_theme_stylebox_override("normal", research_style)
	slot._research_mode_badge.add_theme_stylebox_override("hover", research_style.duplicate())
	slot._research_mode_badge.add_theme_stylebox_override("pressed", research_style.duplicate())
	slot._research_mode_badge.pressed.connect(Callable(slot, "_toggle_research_table_ui"))
	var under := TextureRect.new()
	under.name = "Under"
	under.texture = slot.UnderTexture
	under.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	under.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	under.anchor_right = 1.0
	under.anchor_bottom = 1.0
	under.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot._research_mode_badge.add_child(under)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.anchor_left = 0.15
	icon.anchor_top = 0.15
	icon.anchor_right = 0.85
	icon.anchor_bottom = 0.85
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot._research_mode_badge.add_child(icon)


func configure_click_area(slot) -> void:
	if slot.click_area:
		slot.click_area.input_pickable = true
	if not slot.collision_shape:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 60)
	slot.collision_shape.shape = rect
