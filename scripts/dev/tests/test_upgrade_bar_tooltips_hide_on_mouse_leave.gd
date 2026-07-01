extends SceneTree

const PopulationBarScene := preload("res://scenes/ui/hud/PopulationBar.tscn")
const GazeUpgradeBarScene := preload("res://scenes/ui/gaze/GazeUpgradeBar.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_upgrade_bar_tooltips_hide_on_mouse_leave] %s" % message)
	quit(1)


func _run_test() -> void:
	await _test_population_bar()
	if _failed:
		return
	await _test_gaze_bar()
	if _failed:
		return
	print("[test_upgrade_bar_tooltips_hide_on_mouse_leave] PASS")
	quit(0)


func _test_population_bar() -> void:
	var bar := PopulationBarScene.instantiate() as Control
	if bar == null:
		_fail("failed to instantiate PopulationBar")
		return
	get_root().add_child(bar)
	await process_frame

	var tooltip := bar.get_node_or_null("HoverRegion/PopulationTooltip") as Control
	if tooltip == null:
		_fail("PopulationBar missing tooltip panel")
		return

	bar.call("_on_hover_entered")
	await process_frame
	if not tooltip.visible:
		_fail("PopulationBar tooltip must show on hover")
		return

	bar.call("_on_hover_exited")
	bar.call("_process", 0.2)
	await process_frame
	if tooltip.visible:
		_fail("PopulationBar tooltip must hide after mouse leaves")
		return

	bar.queue_free()
	await process_frame


func _test_gaze_bar() -> void:
	var bar := GazeUpgradeBarScene.instantiate() as Control
	if bar == null:
		_fail("failed to instantiate GazeUpgradeBar")
		return
	get_root().add_child(bar)
	await process_frame

	var tooltip := bar.get_node_or_null("HoverRegion/GazeTooltip") as Control
	if tooltip == null:
		_fail("GazeUpgradeBar missing tooltip panel")
		return

	bar.call("_on_hover_entered")
	await process_frame
	if not tooltip.visible:
		_fail("GazeUpgradeBar tooltip must show on hover")
		return

	bar.call("_on_hover_exited")
	bar.call("_process", 0.2)
	await process_frame
	if tooltip.visible:
		_fail("GazeUpgradeBar tooltip must hide after mouse leaves")
		return

	bar.queue_free()
	await process_frame
