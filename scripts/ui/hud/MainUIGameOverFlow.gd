extends RefCounted
class_name MainUIGameOverFlow

func open_game_over_panel(current_instance, instantiate_panel: Callable, popup_host, restart_callback: Callable):
    var panel = current_instance
    if panel == null:
        if not instantiate_panel.is_valid():
            return null
        panel = instantiate_panel.call()
        if panel == null:
            return null
        if popup_host and popup_host.has_method("add_popup"):
            popup_host.add_popup(panel)
        if restart_callback.is_valid() and panel.has_signal("restart_requested") and not panel.restart_requested.is_connected(restart_callback):
            panel.restart_requested.connect(restart_callback)
    if panel is CanvasItem:
        (panel as CanvasItem).visible = true
    if panel != null:
        if panel.has_method("mark_top_level"):
            panel.call("mark_top_level", true)
        elif panel.has_method("set_as_top_level"):
            panel.call("set_as_top_level", true)
    return panel
