extends RefCounted
class_name SpellVisualLifecycle


func fade_out_nodes(owner: Node, nodes: Array, duration: float) -> Tween:
	if owner == null:
		return null
	var tween := owner.create_tween()
	for node in nodes:
		if node != null and is_instance_valid(node):
			tween.parallel().tween_property(node, "modulate:a", 0.0, duration)
	return tween
