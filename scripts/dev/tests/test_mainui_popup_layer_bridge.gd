extends SceneTree

const BridgeScript := preload("res://scripts/ui/hud/MainUIPopupLayerBridge.gd")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var bridge = BridgeScript.new()
	if bridge == null:
		push_error("[test_mainui_popup_layer_bridge] failed to instantiate helper")
		quit(1)
		return
	var owner := Control.new()
	var popup_layer := Control.new()
	owner.add_child(popup_layer)
	if bridge.get_popup_host(popup_layer, owner) != popup_layer:
		push_error("[test_mainui_popup_layer_bridge] explicit popup layer should win")
		quit(1)
		return
	if bridge.get_popup_host(null, owner) != owner:
		push_error("[test_mainui_popup_layer_bridge] owner fallback mismatch")
		quit(1)
		return
	var popup := Control.new()
	bridge.add_popup(popup_layer, owner, popup)
	if popup.get_parent() != popup_layer:
		push_error("[test_mainui_popup_layer_bridge] popup should attach to popup layer")
		quit(1)
		return
	var fallback_popup := Control.new()
	bridge.add_popup(null, owner, fallback_popup)
	if fallback_popup.get_parent() != owner:
		push_error("[test_mainui_popup_layer_bridge] popup should fallback to owner")
		quit(1)
		return
	print("[test_mainui_popup_layer_bridge] PASS")
	quit(0)
