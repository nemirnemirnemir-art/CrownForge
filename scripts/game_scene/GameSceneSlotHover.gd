extends RefCounted
class_name GameSceneSlotHover

const SLOT_HOVER_TOOLTIP_DELAY := 1.0
const SLOT_HOVER_TOOLTIP_OFFSET_Y := 56.0

var _slot_hover_tooltip: Control = null
var _slot_hover_slot: MapSlot = null
var _slot_hover_timer: float = 0.0
var _slot_hover_revealed: bool = false
var _slot_hover_radial_textures: Array[Texture2D] = []
var _buildings_tooltip_scene: PackedScene = null

func initialize(buildings_tooltip_scene: PackedScene) -> void:
	_buildings_tooltip_scene = buildings_tooltip_scene

func update(game_scene: Node, map_layout_node: Node, delta: float) -> void:
	if map_layout_node == null:
		clear_state()
		return
	
	if _is_hover_blocked_by_ui(game_scene, _slot_hover_tooltip):
		clear_state()
		return
	
	var slot := _find_slot_at_mouse(map_layout_node, true)
	if slot == null or slot.current_building_id == "":
		clear_state()
		return
	
	if _slot_hover_slot != slot:
		_hide_slot_hover_radial(_slot_hover_slot)
		_slot_hover_slot = slot
		_slot_hover_timer = 0.0
		_slot_hover_revealed = false
		_hide_slot_hover_tooltip()
		_set_slot_hover_radial(slot, 0.0)
		return
	
	_slot_hover_timer += delta
	var progress := clampf(_slot_hover_timer / SLOT_HOVER_TOOLTIP_DELAY, 0.0, 1.0)
	_set_slot_hover_radial(slot, progress)
	
	if progress >= 1.0:
		if not _slot_hover_revealed:
			_show_slot_hover_tooltip(game_scene, slot)
			_slot_hover_revealed = true
		else:
			_position_slot_hover_tooltip(slot)

func update_paused(game_scene: Node, map_layout_node: Node) -> void:
	if map_layout_node == null:
		clear_state()
		return
	
	if _is_hover_blocked_by_ui(game_scene, _slot_hover_tooltip):
		clear_state()
		return
	
	var slot := _find_slot_at_mouse(map_layout_node, true)
	if slot == null or slot.current_building_id == "":
		clear_state()
		return
	
	if _slot_hover_slot != slot:
		_hide_slot_hover_radial(_slot_hover_slot)
		_slot_hover_slot = slot
		_slot_hover_timer = 0.0
		_slot_hover_revealed = true
		_hide_slot_hover_radial(slot)
		_show_slot_hover_tooltip(game_scene, slot)
		return
	
	_hide_slot_hover_radial(slot)
	_position_slot_hover_tooltip(slot)

func clear_state() -> void:
	_hide_slot_hover_radial(_slot_hover_slot)
	_hide_slot_hover_tooltip()
	_slot_hover_slot = null
	_slot_hover_timer = 0.0
	_slot_hover_revealed = false

func _ensure_slot_hover_radial_textures() -> void:
	if not _slot_hover_radial_textures.is_empty():
		return
	for i in range(1, 21):
		var path := "res://assets/ui/radialProgressBar/%d.png" % i
		var tex := load(path)
		if tex is Texture2D:
			_slot_hover_radial_textures.append(tex)

func _set_slot_hover_radial(slot: MapSlot, progress: float) -> void:
	if slot == null or not is_instance_valid(slot):
		return
	if slot.radial_progress == null:
		return
	
	_ensure_slot_hover_radial_textures()
	if _slot_hover_radial_textures.is_empty():
		return
	
	var idx := int(round(progress * float(_slot_hover_radial_textures.size() - 1)))
	idx = clampi(idx, 0, _slot_hover_radial_textures.size() - 1)
	slot.radial_progress.texture = _slot_hover_radial_textures[idx]
	slot.radial_progress.visible = true

func _hide_slot_hover_radial(slot: MapSlot) -> void:
	if slot == null or not is_instance_valid(slot):
		return
	if slot.radial_progress:
		slot.radial_progress.visible = false

func _resolve_ui_popup_parent(game_scene: Node) -> CanvasItem:
	var main_ui: Node = game_scene.get_node_or_null("UILayer/MainUI")
	if main_ui == null:
		main_ui = game_scene.get_tree().get_first_node_in_group("main_ui")
	
	if main_ui and main_ui.has_method("get_popup_layer"):
		var popup_layer_value: Variant = main_ui.call("get_popup_layer")
		var popup_layer_canvas: CanvasItem = popup_layer_value as CanvasItem
		if popup_layer_canvas:
			return popup_layer_canvas
	
	if main_ui is CanvasItem:
		return main_ui as CanvasItem
	
	return game_scene

func _show_slot_hover_tooltip(game_scene: Node, slot: MapSlot) -> void:
	if slot == null or not is_instance_valid(slot):
		return
	if slot.current_building_id == "":
		return
	
	if _buildings_tooltip_scene == null:
		return
	
	if _slot_hover_tooltip == null or not is_instance_valid(_slot_hover_tooltip):
		var tooltip_node := _buildings_tooltip_scene.instantiate()
		if tooltip_node == null:
			return
		_resolve_ui_popup_parent(game_scene).add_child(tooltip_node)
		if tooltip_node is Control:
			var tooltip := tooltip_node as Control
			tooltip.top_level = true
			tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tooltip.z_index = 1100
			_slot_hover_tooltip = tooltip
	
	if _slot_hover_tooltip and _slot_hover_tooltip.has_method("setup"):
		_slot_hover_tooltip.setup(slot.current_building_id)
		_slot_hover_tooltip.show()
		_position_slot_hover_tooltip(slot)

func _position_slot_hover_tooltip(slot: MapSlot) -> void:
	if _slot_hover_tooltip == null or not is_instance_valid(_slot_hover_tooltip):
		return
	if slot == null or not is_instance_valid(slot):
		return
	
	if _slot_hover_tooltip.has_method("reset_size"):
		_slot_hover_tooltip.reset_size()
	var sz: Vector2 = _slot_hover_tooltip.get_combined_minimum_size()
	if sz == Vector2.ZERO:
		sz = _slot_hover_tooltip.size
	
	var pos := Vector2(
		slot.global_position.x - sz.x * 0.5,
		slot.global_position.y - SLOT_HOVER_TOOLTIP_OFFSET_Y - sz.y
	)
	
	var screen := _slot_hover_tooltip.get_viewport_rect().size
	pos.x = clamp(pos.x, 5.0, max(5.0, screen.x - sz.x - 5.0))
	pos.y = clamp(pos.y, 5.0, max(5.0, screen.y - sz.y - 5.0))
	_slot_hover_tooltip.global_position = pos

func _hide_slot_hover_tooltip() -> void:
	if _slot_hover_tooltip and is_instance_valid(_slot_hover_tooltip):
		_slot_hover_tooltip.hide()

func _find_slot_at_mouse(map_layout_node: Node, allow_occupied: bool) -> MapSlot:
	var mouse_pos = map_layout_node.get_global_mouse_position()
	for slot in map_layout_node.slots:
		if not slot.is_building_slot:
			continue
		if not allow_occupied and slot.current_building_id != "":
			continue
		var slot_pos = slot.global_position
		var rect = Rect2(slot_pos - Vector2(50, 50), Vector2(100, 100))
		if rect.has_point(mouse_pos):
			return slot
	return null

func _is_hover_blocked_by_ui(game_scene: Node, current_tooltip: Control) -> bool:
	var hovered_control: Control = game_scene.get_viewport().gui_get_hovered_control()
	if hovered_control == null:
		return false
	
	if current_tooltip and is_instance_valid(current_tooltip):
		if hovered_control == current_tooltip or current_tooltip.is_ancestor_of(hovered_control):
			return false
	
	var current: Control = hovered_control
	while current != null:
		if current.mouse_filter == Control.MOUSE_FILTER_STOP:
			return true
		current = current.get_parent() as Control
	
	return false
