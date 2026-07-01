extends SceneTree

const ResolverScript := preload("res://scripts/ui/hud/MainUIResourceBarResolver.gd")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var resolver = ResolverScript.new()
	if resolver == null:
		push_error("[test_mainui_resource_bar_resolver] failed to instantiate helper")
		quit(1)
		return
	var owner := Control.new()
	var bar := PanelContainer.new()
	bar.name = "ResourceBarUnified"
	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	bar.add_child(hbox)
	owner.add_child(bar)
	var resolved: Dictionary = resolver.resolve_resource_bar(null, owner)
	if resolved.get("resource_bar_unified", null) != bar or resolved.get("resource_bar_hbox", null) != hbox:
		push_error("[test_mainui_resource_bar_resolver] fallback lookup mismatch")
		quit(1)
		return
	var direct_bar := PanelContainer.new()
	var direct_hbox := HBoxContainer.new()
	direct_hbox.name = "HBox"
	direct_bar.add_child(direct_hbox)
	var direct: Dictionary = resolver.resolve_resource_bar(direct_bar, owner)
	if direct.get("resource_bar_unified", null) != direct_bar or direct.get("resource_bar_hbox", null) != direct_hbox:
		push_error("[test_mainui_resource_bar_resolver] direct lookup mismatch")
		quit(1)
		return
	print("[test_mainui_resource_bar_resolver] PASS")
	quit(0)
