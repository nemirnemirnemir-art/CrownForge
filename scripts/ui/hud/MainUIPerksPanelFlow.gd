extends RefCounted
class_name MainUIPerksPanelFlow

func open_perks_panel(perks_test_panel) -> void:
	if perks_test_panel != null and perks_test_panel.has_method("open"):
		perks_test_panel.open()
