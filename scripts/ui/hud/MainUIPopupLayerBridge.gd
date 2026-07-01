extends RefCounted
class_name MainUIPopupLayerBridge

func get_popup_host(popup_layer: Control, owner: Control) -> Control:
	return popup_layer if popup_layer != null else owner

func add_popup(popup_layer: Control, owner: Control, node: Node) -> void:
	if node == null:
		return
	var host := get_popup_host(popup_layer, owner)
	if host != null:
		host.add_child(node)
