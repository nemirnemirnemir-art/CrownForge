extends RefCounted
class_name BuildingsTooltipIconResolver

func resolve_icon_path(resource_id: String) -> String:
	var candidates: Array[String] = [
		"res://assets/resources/%s.png" % resource_id,
		"res://assets/ui/resources/%s.png" % resource_id,
		"res://assets/resources/icons/%s.png" % resource_id,
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			return path
	return ""

func resolve_ui_icon_path(icon_name: String) -> String:
	var path := "res://assets/ui/icons/%s.png" % icon_name
	if ResourceLoader.exists(path):
		return path
	return ""
