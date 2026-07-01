class_name StatusIconService
extends RefCounted

## Shared service for adding, removing, and reflowing status icons above units.
## Consolidates the duplicated _reflow_status_icons() pattern from FrailtyEffect
## and BlindingLightEffect into a single reusable helper.

const DEFAULT_ICON_OFFSET_Y: float = -55.0
const DEFAULT_ICON_SIZE: float = 37.5
const STATUS_ICON_SPACING: float = 42.0


## Creates a status icon Sprite2D, attaches it to the target, and reflows all
## status icons on that target. Returns the created icon node (or null on failure).
static func add_status_icon(
	target: Node2D,
	icon_texture_path: String,
	icon_name: String,
	offset_y: float = DEFAULT_ICON_OFFSET_Y,
	icon_size: float = DEFAULT_ICON_SIZE,
	z_index_value: int = 210,
) -> Sprite2D:
	if target == null or not is_instance_valid(target):
		return null

	var tex := load(icon_texture_path) as Texture2D
	if tex == null:
		push_warning("[StatusIconService] Could not load icon texture: %s" % icon_texture_path)
		return null

	var icon := Sprite2D.new()
	icon.texture = tex
	icon.name = icon_name
	icon.z_index = z_index_value
	icon.position = Vector2(0.0, offset_y)
	icon.set_meta("status_icon", true)
	icon.set_meta("status_icon_offset_y", offset_y)

	var size := tex.get_size()
	if size.x > 0.0 and size.y > 0.0:
		icon.scale = Vector2(icon_size / size.x, icon_size / size.y)

	target.add_child(icon)
	reflow_status_icons(target)
	return icon


## Removes a status icon node (by weak reference or direct reference) and
## reflows the remaining icons on the target.
static func remove_status_icon(target: Node2D, icon_ref: Variant) -> void:
	var icon_node: Node = _resolve_node(icon_ref)
	if icon_node != null and is_instance_valid(icon_node):
		icon_node.queue_free()

	if target != null and is_instance_valid(target):
		_schedule_reflow(target)


## Reflows all children of `target` that have the "status_icon" meta set to true.
## Arranges them in a centered horizontal row.
static func reflow_status_icons(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	var icons: Array[Node2D] = []
	for child in target.get_children():
		if child is Node2D and child.has_meta("status_icon") and bool(child.get_meta("status_icon")):
			icons.append(child as Node2D)

	if icons.is_empty():
		return

	var spacing := STATUS_ICON_SPACING
	var total_width := float(icons.size() - 1) * spacing
	for i in range(icons.size()):
		var icon := icons[i]
		var y := float(icon.get_meta("status_icon_offset_y", DEFAULT_ICON_OFFSET_Y))
		icon.position = Vector2(-total_width * 0.5 + float(i) * spacing, y)


## Schedule a deferred reflow on the target node.
static func schedule_deferred_reflow(target: Node2D) -> void:
	_schedule_reflow(target)


# -- internal helpers --------------------------------------------------------

static func _schedule_reflow(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	var tree := target.get_tree()
	if tree == null:
		StatusIconService.reflow_status_icons(target)
		return

	tree.process_frame.connect(
		func() -> void:
			if target != null and is_instance_valid(target):
				StatusIconService.reflow_status_icons(target),
		Object.CONNECT_ONE_SHOT
	)


static func _resolve_node(value: Variant) -> Node:
	if value == null:
		return null
	if value is WeakRef:
		var obj: Object = (value as WeakRef).get_ref()
		if obj != null and obj is Node:
			return obj as Node
		return null
	if value is Node:
		return value as Node
	return null
