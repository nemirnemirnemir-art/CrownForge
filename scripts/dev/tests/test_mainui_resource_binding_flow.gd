extends SceneTree

const MainUIResourceBindingFlowScript := preload("res://scripts/ui/hud/MainUIResourceBindingFlow.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MainUIResourceBindingFlowScript.new()
	if flow == null:
		push_error("[test_mainui_resource_binding_flow] failed to instantiate helper")
		quit(1)
		return

	var hbox := HBoxContainer.new()

	var water_container := Control.new()
	water_container.name = "Resource_water"
	var water_label := Label.new()
	water_label.name = "ValueLabel"
	water_container.add_child(water_label)
	hbox.add_child(water_container)

	var wood_container := Control.new()
	wood_container.name = "Resource_wood"
	var wrapper := Control.new()
	wrapper.name = "Nested"
	var wood_label := Label.new()
	wood_label.name = "ValueLabel"
	wrapper.add_child(wood_label)
	wood_container.add_child(wrapper)
	hbox.add_child(wood_container)

	var missing_container := Control.new()
	missing_container.name = "Resource_clay"
	hbox.add_child(missing_container)

	var labels: Dictionary = flow.collect_resource_labels(hbox, ["water", "wood", "clay"])
	if labels.get("water", null) != water_label:
		push_error("[test_mainui_resource_binding_flow] direct ValueLabel lookup mismatch")
		quit(1)
		return
	if labels.get("wood", null) != wood_label:
		push_error("[test_mainui_resource_binding_flow] nested ValueLabel fallback mismatch")
		quit(1)
		return
	if labels.has("clay"):
		push_error("[test_mainui_resource_binding_flow] missing ValueLabel should be skipped")
		quit(1)
		return

	print("[test_mainui_resource_binding_flow] PASS")
	quit(0)
