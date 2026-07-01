extends Control

const ICON_SIZE := 50.0
const COLUMNS := 5
const TOOLTIP_OFFSET := Vector2(12, 12)

@onready var toggle_button: TextureButton = get_node_or_null("ToggleButton")
@onready var dropdown: PanelContainer = get_node_or_null("Dropdown")
@onready var grid: GridContainer = get_node_or_null("Dropdown/Grid")

var _slot_by_id: Dictionary = {}
var _tooltip: PanelContainer
var _tooltip_name: Label
var _tooltip_desc: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if toggle_button:
		toggle_button.pressed.connect(_on_toggle_pressed)
	if dropdown:
		dropdown.visible = false
	if grid:
		grid.columns = COLUMNS

	_build_tooltip()
	_rebuild()

	if ArtifactCore:
		if not ArtifactCore.artifacts_changed.is_connected(_on_artifacts_changed):
			ArtifactCore.artifacts_changed.connect(_on_artifacts_changed)

func _exit_tree() -> void:
	if ArtifactCore and ArtifactCore.artifacts_changed.is_connected(_on_artifacts_changed):
		ArtifactCore.artifacts_changed.disconnect(_on_artifacts_changed)

func _on_toggle_pressed() -> void:
	if dropdown:
		dropdown.visible = not dropdown.visible

func _on_artifacts_changed() -> void:
	_rebuild()

func _rebuild() -> void:
	if grid == null:
		return
	_slot_by_id.clear()
	for ch in grid.get_children():
		ch.queue_free()

	var ids: Array = ArtifactCatalog.get_all_ids_sorted()
	for i in range(ids.size()):
		var id := str(ids[i])
		if ArtifactCore == null:
			continue
		if not ArtifactCore.has_artifact(id):
			continue
		var slot := _make_slot(id)
		grid.add_child(slot)
		_slot_by_id[id] = slot

	_update_all_slot_visuals()

func _make_slot(artifact_id: String) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)

	var bg := ColorRect.new()
	bg.name = "IconBG"
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.anchors_preset = Control.PRESET_FULL_RECT
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon)

	var border := ReferenceRect.new()
	border.name = "ActiveBorder"
	border.anchors_preset = Control.PRESET_FULL_RECT
	border.border_width = 2.0
	border.border_color = Color(0.2, 1.0, 0.2, 1.0)
	border.visible = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(border)

	root.mouse_entered.connect(_on_slot_mouse_entered.bind(artifact_id))
	root.mouse_exited.connect(_on_slot_mouse_exited)
	root.gui_input.connect(_on_slot_gui_input) # eat clicks

	return root

func _update_slot_visual(artifact_id: String) -> void:
	var slot: Control = _slot_by_id.get(artifact_id)
	if slot == null:
		return
	var def := ArtifactCatalog.get_def(artifact_id)
	var implemented := bool(def.get("implemented", false))
	var active := ArtifactCore.is_active(artifact_id) if ArtifactCore else false

	var bg: ColorRect = slot.get_node_or_null("IconBG")
	if bg:
		bg.color = Color(0.25, 0.55, 1.0, 1.0) if implemented else Color(1.0, 0.25, 0.25, 1.0)

	var icon_node: TextureRect = slot.get_node_or_null("Icon")
	if icon_node:
		var icon_path: String = str(def.get("icon", ""))
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon_node.texture = load(icon_path)
		else:
			icon_node.texture = null

	var border: ReferenceRect = slot.get_node_or_null("ActiveBorder")
	if border:
		border.visible = active

func _update_all_slot_visuals() -> void:
	for id in _slot_by_id.keys():
		_update_slot_visual(str(id))

func _build_tooltip() -> void:
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

func _on_slot_mouse_entered(artifact_id: String) -> void:
	var def := ArtifactCatalog.get_def(artifact_id)
	_tooltip_name.text = str(def.get("display_name", artifact_id))
	_tooltip_desc.text = str(def.get("description", ""))
	_tooltip.visible = true
	_tooltip.global_position = get_global_mouse_position() + TOOLTIP_OFFSET

func _on_slot_mouse_exited() -> void:
	_tooltip.visible = false

func _on_slot_gui_input(_event: InputEvent) -> void:
	# View-only panel: do nothing, but keep input from passing through.
	pass

func _process(_delta: float) -> void:
	if _tooltip and _tooltip.visible:
		_tooltip.global_position = get_global_mouse_position() + TOOLTIP_OFFSET
