extends RefCounted
class_name BuildingMenuTooltipController

var hovered_id: String = ""

func on_hover_started(id: String) -> void:
	hovered_id = id

## Returns true if state changed (so caller can decide whether to refresh).
func on_hover_ended(id: String) -> bool:
	if id != hovered_id:
		return false
	hovered_id = ""
	return true
