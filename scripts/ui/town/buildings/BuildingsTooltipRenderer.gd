extends RefCounted
class_name BuildingsTooltipRenderer

const ResourceAmountRowScene: PackedScene = preload("res://scenes/ui/town/ResourceAmountRow.tscn")
const UnitFaceLibraryScript := preload("res://scripts/utils/UnitFaceLibrary.gd")

const BODY_COLOR := Color(0.8, 0.8, 0.8, 1.0)
const BODY_OUTLINE_COLOR := Color(0.05, 0.05, 0.05, 1.0)
const TITLE_COLOR := Color(1.0, 0.9, 0.7, 1.0)

var resource_icon_size: float = 28.0

## Generic render dispatch. data["type"] = "unit" | "resource"
func render(container: Node, data: Dictionary) -> void:
	if not container:
		return
	match str(data.get("type", "")):
		"unit":
			add_unit_to_list(container as Control, str(data.get("unit_id", "")), int(data.get("amount", 1)))
		"resource":
			add_resource_to_hbox(container as Control, str(data.get("resource_id", "")), int(data.get("amount", 0)))

func setup_icon_fallback(icon_rect: Control, symbol: String, color: Color) -> Control:
	if not icon_rect:
		return null
	var label := Label.new()
	label.text = symbol
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", BODY_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = icon_rect.custom_minimum_size
	var parent := icon_rect.get_parent()
	if parent:
		var idx := icon_rect.get_index()
		parent.remove_child(icon_rect)
		parent.add_child(label)
		parent.move_child(label, idx)
		icon_rect.queue_free()
		return label
	return icon_rect

func add_unit_to_list(container: Control, unit_id: String, amount: int) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	container.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(50, 50)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = UnitFaceLibraryScript.get_face_texture(unit_id, unit_id.replace("_", " "))
	icon.modulate = Color(1, 1, 1, 1) if icon.texture != null else Color(0.5, 0.5, 0.5, 1.0)
	row.add_child(icon)

	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", BODY_COLOR)
	label.add_theme_color_override("font_outline_color", BODY_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

func add_resource_to_hbox(container: Control, res_id: String, amount: int) -> void:
	var row = ResourceAmountRowScene.instantiate()
	container.add_child(row)
	if row.has_method("setup"):
		row.setup(res_id, amount, -1)
	row.custom_minimum_size = Vector2(0, 56)
	if row is HBoxContainer:
		(row as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
	var icon = row.get_node_or_null("Icon")
	if icon:
		icon.custom_minimum_size = Vector2(resource_icon_size, resource_icon_size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var label = row.get_node_or_null("ValueLabel")
	if label:
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_color", BODY_COLOR)
		label.add_theme_color_override("font_outline_color", BODY_OUTLINE_COLOR)
		label.add_theme_constant_override("outline_size", 2)
		label.modulate = Color(1, 1, 1, 1)

func update_cost_row(row: ResourceAmountRow, res_id: String, required: int, owned: int, icon_size: float) -> void:
	if not row:
		return
	if row.has_method("setup"):
		row.setup(res_id, required, owned)
	var icon := row.get_node_or_null("Icon") as TextureRect
	if icon:
		icon.custom_minimum_size = Vector2(icon_size, icon_size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var label := row.get_node_or_null("ValueLabel") as Label
	if label:
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		label.add_theme_color_override("font_outline_color", BODY_OUTLINE_COLOR)
		label.add_theme_constant_override("outline_size", 2)
		label.modulate = Color(1.0, 0.3, 0.3, 1.0) if owned < required else Color(0.3, 1.0, 0.3, 1.0)
	row.custom_minimum_size = Vector2(0, 56)
	if row is HBoxContainer:
		(row as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER

func add_cost_row(container: VBoxContainer, res_id: String, required: int, owned: int) -> void:
	var row: ResourceAmountRow = ResourceAmountRowScene.instantiate()
	container.add_child(row)
	update_cost_row(row, res_id, required, owned, resource_icon_size)

func update_production_display(output_list: Control, arrow_icon: Control, prod_row: Control, prod_row_icon: Control, config: BuildingConfig) -> void:
	clear_container(output_list)
	arrow_icon.visible = false
	if not prod_row:
		return
	var prod_content: HBoxContainer = prod_row.get_node_or_null("Content")
	if not prod_content:
		return
	clear_container(prod_content)
	if config.building_type == BuildingConfig.BuildingType.MILITARY:
		add_unit_to_list(prod_content, config.produced_unit_id, 1)
	else:
		for prod in config.produces:
			if prod:
				add_resource_to_hbox(prod_content, prod.resource_id, prod.amount)
	prod_row.visible = prod_content.get_child_count() > 0
	if prod_row_icon:
		prod_row_icon.visible = prod_row.visible

func update_consumption_display(input_list: Control, arrow_icon: Control, cons_row: Control, cons_row_icon: Control, config: BuildingConfig) -> void:
	clear_container(input_list)
	if cons_row:
		var cons_content: HBoxContainer = cons_row.get_node_or_null("Content")
		if cons_content:
			clear_container(cons_content)
			if config.consumes.is_empty():
				cons_row.visible = false
			else:
				for cons in config.consumes:
					if cons:
						add_resource_to_hbox(cons_content, cons.resource_id, cons.amount)
				cons_row.visible = cons_content.get_child_count() > 0
		if cons_row_icon:
			cons_row_icon.visible = cons_row.visible
	for cons in config.consumes:
		if cons:
			add_resource_to_hbox(input_list, cons.resource_id, cons.amount)
	arrow_icon.visible = not config.consumes.is_empty()

func rebuild_cost_rows(container: VBoxContainer, sorted_ids: Array, costs: Dictionary, owned_amount_provider: Variant, icon_size: float) -> void:
	var existing_count := container.get_child_count()
	var needed_count := sorted_ids.size()
	while existing_count > needed_count:
		var child = container.get_child(existing_count - 1)
		container.remove_child(child)
		child.queue_free()
		existing_count -= 1
	for i in range(needed_count):
		var res_id := str(sorted_ids[i])
		var amount: int = costs[res_id]
		var owned := _get_owned_amount(owned_amount_provider, res_id)
		var row: ResourceAmountRow
		if i < existing_count:
			row = container.get_child(i) as ResourceAmountRow
		else:
			row = ResourceAmountRowScene.instantiate()
			container.add_child(row)
		update_cost_row(row, res_id, amount, owned, icon_size)


func _get_owned_amount(owned_amount_provider: Variant, res_id: String) -> int:
	if owned_amount_provider != null and owned_amount_provider.has_method("_get_owned_amount"):
		return int(owned_amount_provider.call("_get_owned_amount", res_id))
	if owned_amount_provider != null and owned_amount_provider.has_method("get_resource"):
		return int(owned_amount_provider.get_resource(res_id))
	return 0

func clear_container(container: Control) -> void:
	if not container:
		return
	for c in container.get_children():
		c.queue_free()
