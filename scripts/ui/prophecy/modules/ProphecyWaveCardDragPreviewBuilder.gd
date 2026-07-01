extends RefCounted
class_name ProphecyWaveCardDragPreviewBuilder


static func create_drag_preview(scene_path: String, option_patterns: Array, card_min_width: float, mob_portrait_size: Vector2) -> Control:
    var preview_scene: PackedScene = load(scene_path)
    if preview_scene == null:
        return null

    var wrapper := Control.new()
    wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
    wrapper.z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 1
    wrapper.top_level = true
    wrapper.set_anchors_preset(Control.PRESET_TOP_LEFT)
    wrapper.position = Vector2.ZERO

    var preview := preview_scene.instantiate()
    wrapper.add_child(preview)

    if preview and preview.has_method("set_interactive"):
        preview.call("set_interactive", false)
    if preview and preview.has_method("setup"):
        preview.call_deferred("setup", option_patterns)

    var preview_control := preview as Control
    if preview_control:
        preview_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
        preview_control.set_anchors_preset(Control.PRESET_TOP_LEFT)
        var base_size := preview_control.get_combined_minimum_size()
        if base_size == Vector2.ZERO:
            base_size = preview_control.size
        if base_size == Vector2.ZERO:
            base_size = Vector2(card_min_width, mob_portrait_size.y * 3.0)
        preview_control.custom_minimum_size = base_size
        preview_control.size = base_size

    var scale_factor := 0.65
    if preview is CanvasItem:
        (preview as CanvasItem).modulate = Color(1, 1, 1, 0.92)
    if preview is Node2D:
        (preview as Node2D).scale = Vector2(scale_factor, scale_factor)
        (preview as Node2D).position = Vector2.ZERO
    elif preview is Control:
        (preview as Control).scale = Vector2(scale_factor, scale_factor)
        (preview as Control).position = Vector2.ZERO

    var preview_size := wrapper.get_combined_minimum_size()
    if preview_size == Vector2.ZERO and preview_control:
        preview_size = preview_control.get_combined_minimum_size() * scale_factor
    wrapper.custom_minimum_size = preview_size
    wrapper.size = preview_size
    wrapper.pivot_offset = preview_size * 0.5
    return wrapper
