extends SceneTree

const MarketUIScene := preload("res://scenes/ui/town/MarketUI.tscn")
const ResearchUIScene := preload("res://scenes/ui/town/ResearchTableUI.tscn")

var _failed := false

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_kingdom_infrastructure_ui_contracts] %s" % message)
	quit(1)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var market_ui := MarketUIScene.instantiate()
	if market_ui == null:
		_fail("MarketUI scene must instantiate")
		return
	get_root().add_child(market_ui)
	await process_frame

	var market_title := market_ui.get_node_or_null("Panel/Margin/VBox/Title") as Label
	if market_title == null:
		_fail("MarketUI must use panel-based selector layout with a Title label")
		return
	if market_title.text != "Market":
		_fail("MarketUI title must be 'Market', got '%s'" % market_title.text)
		return

	var market_row := market_ui.get_node_or_null("Panel/Margin/VBox/OptionsRow") as HBoxContainer
	if market_row == null:
		_fail("MarketUI must expose a horizontal OptionsRow inside the panel layout")
		return
	if market_row.get_child_count() != 4:
		_fail("MarketUI must expose 4 trade choices without furniture, got %d" % market_row.get_child_count())
		return

	var research_ui := ResearchUIScene.instantiate()
	if research_ui == null:
		_fail("ResearchTableUI scene must instantiate")
		return
	get_root().add_child(research_ui)
	await process_frame

	var title := research_ui.get_node_or_null("Panel/Margin/VBox/Title") as Label
	if title == null:
		_fail("ResearchTableUI must expose a Title label")
		return
	if title.text != "Research":
		_fail("Research selector title must default to generic 'Research', got '%s'" % title.text)
		return

	if not research_ui.has_method("set_title"):
		_fail("ResearchTableUI must support dynamic titles for Research Laboratory")
		return
	research_ui.call("set_title", "Research Laboratory")
	if title.text != "Research Laboratory":
		_fail("ResearchTableUI.set_title must update the visible title")
		return

	print("[test_kingdom_infrastructure_ui_contracts] PASS")
	quit(0)
