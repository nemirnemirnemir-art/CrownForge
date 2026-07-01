extends RefCounted
class_name MainUITooltipProcessFlow

func process_tooltips(tooltips) -> void:
	if tooltips != null and tooltips.has_method("process"):
		tooltips.process()
