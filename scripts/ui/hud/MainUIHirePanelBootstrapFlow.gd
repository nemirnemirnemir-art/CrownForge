extends RefCounted
class_name MainUIHirePanelBootstrapFlow

func apply_initial_state(hire_panel: CanvasItem) -> void:
	if hire_panel == null:
		return
	hire_panel.visible = false
	hire_panel.process_mode = Node.PROCESS_MODE_DISABLED
