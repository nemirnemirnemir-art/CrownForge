extends Control

const SLOT_SIZE := 50.0
const TOOLTIP_OFFSET := Vector2(12, 12)

var _grid: GridContainer
var _tooltip: PanelContainer
var _tooltip_name: Label
var _tooltip_desc: Label

var _slot_by_id: Dictionary = {}

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_mouse_filter_ignore_children(self)
	_build_ui()
	_rebuild_grid()

	if ArtifactCore:
		if not ArtifactCore.artifacts_changed.is_connected(_on_artifacts_changed):
			ArtifactCore.artifacts_changed.connect(_on_artifacts_changed)

func _exit_tree() -> void:
	if ArtifactCore and ArtifactCore.artifacts_changed.is_connected(_on_artifacts_changed):
		ArtifactCore.artifacts_changed.disconnect(_on_artifacts_changed)

func _mouse_filter_ignore_children(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_PASS
	for ch in n.get_children():
		_mouse_filter_ignore_children(ch)

func _build_ui() -> void:
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -300
	offset_top = -350
	offset_right = 300
	offset_bottom = 250
	z_index = 300

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(550, 550)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(scroll)

	_grid = GridContainer.new()
	_grid.name = "Grid"
	_grid.columns = 10
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 2)
	_grid.add_theme_constant_override("v_separation", 2)
	scroll.add_child(_grid)

	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.z_index = 1000
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tooltip)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	_tooltip.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	_tooltip_name = Label.new()
	_tooltip_name.text = ""
	vbox.add_child(_tooltip_name)

	_tooltip_desc = Label.new()
	_tooltip_desc.text = ""
	_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	_tooltip_desc.custom_minimum_size = Vector2(260, 0)
	vbox.add_child(_tooltip_desc)

func _rebuild_grid() -> void:
	_slot_by_id.clear()
	for ch in _grid.get_children():
		ch.queue_free()

	var ids: Array = ArtifactCatalog.get_all_ids_sorted()
	for i in range(ids.size()):
		var id := str(ids[i])
		var slot := _make_slot(id)
		_grid.add_child(slot)
		_slot_by_id[id] = slot

	_update_all_slot_visuals()

func _make_slot(artifact_id: String) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	root.size_flags_horizontal = Control.SIZE_FILL
	root.size_flags_vertical = Control.SIZE_FILL
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.name = "IconBG"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon)

	var border := ReferenceRect.new()
	border.name = "ActiveBorder"
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.border_width = 2.0
	border.border_color = Color(0.2, 1.0, 0.2, 1.0)
	border.visible = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(border)

	root.gui_input.connect(_on_slot_gui_input.bind(artifact_id))
	root.mouse_entered.connect(_on_slot_mouse_entered.bind(artifact_id))
	root.mouse_exited.connect(_on_slot_mouse_exited)

	return root

func _update_slot_visual(artifact_id: String) -> void:
	var slot: Control = _slot_by_id.get(artifact_id)
	if slot == null:
		return
	var def := ArtifactCatalog.get_def(artifact_id)
	var implemented := bool(def.get("implemented", false))
	var owned := ArtifactCore.has_artifact(artifact_id) if ArtifactCore else false
	var active := ArtifactCore.is_active(artifact_id) if ArtifactCore else false

	var bg: ColorRect = slot.get_node_or_null("IconBG")
	if bg:
		var c := Color(0.25, 0.55, 1.0, 1.0) if implemented else Color(1.0, 0.25, 0.25, 1.0)
		if not owned:
			c = c.darkened(0.35)
		bg.color = c

	var icon_node: TextureRect = slot.get_node_or_null("Icon")
	if icon_node:
		var icon_path: String = str(def.get("icon", ""))
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon_node.texture = load(icon_path)
			if not owned:
				icon_node.modulate = Color(0.5, 0.5, 0.5, 0.7)
			else:
				icon_node.modulate = Color.WHITE
		else:
			icon_node.texture = null

	var border: ReferenceRect = slot.get_node_or_null("ActiveBorder")
	if border:
		border.visible = active

func _update_all_slot_visuals() -> void:
	for id in _slot_by_id.keys():
		_update_slot_visual(str(id))

func _on_artifacts_changed() -> void:
	_update_all_slot_visuals()

func _on_slot_gui_input(event: InputEvent, artifact_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if ArtifactCore:
			if not ArtifactCore.has_artifact(artifact_id):
				ArtifactCore.add_artifact(artifact_id, true)
			else:
				ArtifactCore.toggle_active(artifact_id)
		_update_slot_visual(artifact_id)

func _on_slot_mouse_entered(artifact_id: String) -> void:
	var def := ArtifactCatalog.get_def(artifact_id)
	_tooltip_name.text = str(def.get("display_name", artifact_id))
	_tooltip_desc.text = str(def.get("description", ""))
	_tooltip.visible = true
	_tooltip.global_position = get_global_mouse_position() + TOOLTIP_OFFSET

func _on_slot_mouse_exited() -> void:
	_tooltip.visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = global_position - get_global_mouse_position()
			get_viewport().set_input_as_handled()
		else:
			_dragging = false

	if event is InputEventMouseMotion and _dragging:
		global_position = get_global_mouse_position() + _drag_offset
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		if get_viewport():
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if _tooltip and _tooltip.visible:
		_tooltip.global_position = get_global_mouse_position() + TOOLTIP_OFFSET
