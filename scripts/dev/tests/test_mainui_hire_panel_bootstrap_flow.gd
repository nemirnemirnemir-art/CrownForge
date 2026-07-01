extends SceneTree

const FlowScript := preload("res://scripts/ui/hud/MainUIHirePanelBootstrapFlow.gd")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var flow = FlowScript.new()
	if flow == null:
		push_error("[test_mainui_hire_panel_bootstrap_flow] failed to instantiate helper")
		quit(1)
		return

	var hire_panel := Control.new()
	hire_panel.visible = true
	hire_panel.process_mode = Node.PROCESS_MODE_INHERIT
	flow.apply_initial_state(hire_panel)
	if hire_panel.visible or hire_panel.process_mode != Node.PROCESS_MODE_DISABLED:
		push_error("[test_mainui_hire_panel_bootstrap_flow] hire panel bootstrap state mismatch")
		quit(1)
		return

	flow.apply_initial_state(null)

	print("[test_mainui_hire_panel_bootstrap_flow] PASS")
	quit(0)
