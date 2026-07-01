extends SceneTree

const DebugProphecyTabScript := preload("res://scripts/ui/debug/modules/DebugProphecyTab.gd")


class CountingWalker:
	extends RefCounted

	var labels: Array[String] = []
	var counts: Dictionary = {}

	func walk(node: Node) -> void:
		if node is Label:
			var text := String((node as Label).text)
			labels.append(text)
			counts[text] = int(counts.get(text, 0)) + 1
		elif node is Button:
			var button_text := String((node as Button).text)
			labels.append(button_text)
			counts[button_text] = int(counts.get(button_text, 0)) + 1
		for child in node.get_children():
			walk(child)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var tab = DebugProphecyTabScript.new()
	if tab == null:
		push_error("[test_debug_prophecy_tab] failed to instantiate DebugProphecyTab")
		quit(1)
		return

	var root := Control.new()
	get_root().add_child(root)
	tab.build_ui(root)

	var walker := CountingWalker.new()
	walker.walk(root)

	_assert_has_text(walker.labels, "PROPHECY 1")
	_assert_has_text(walker.labels, "PROPHECY 4")
	_assert_has_text(walker.labels, "Sequence: P1 1 2 3 T")
	_assert_has_text(walker.labels, "Sequence: P4 1 2 3 B")
	_assert_has_text(walker.labels, "EASY (6)")
	_assert_has_text(walker.labels, "MID (6)")
	_assert_has_text(walker.labels, "HARD (6)")
	if int(walker.counts.get("EASY (6)", 0)) != 4:
		push_error("[test_debug_prophecy_tab] expected EASY (6) banner 4 times, got %d" % int(walker.counts.get("EASY (6)", 0)))
		quit(1)
		return
	if int(walker.counts.get("MID (6)", 0)) != 4:
		push_error("[test_debug_prophecy_tab] expected MID (6) banner 4 times, got %d" % int(walker.counts.get("MID (6)", 0)))
		quit(1)
		return
	if int(walker.counts.get("HARD (6)", 0)) != 4:
		push_error("[test_debug_prophecy_tab] expected HARD (6) banner 4 times, got %d" % int(walker.counts.get("HARD (6)", 0)))
		quit(1)
		return
	_assert_has_text(walker.labels, "Goblin Bandit x4")
	_assert_has_text(walker.labels, "Goblin Bandit x1 + Goblin Crossbowman x1")
	_assert_has_text(walker.labels, "Goblin Giant x4")

	print("[test_debug_prophecy_tab] PASS")
	quit(0)


func _assert_has_text(texts: Array[String], expected: String) -> void:
	for text in texts:
		if text == expected:
			return
	push_error("[test_debug_prophecy_tab] missing text: %s in %s" % [expected, str(texts)])
	quit(1)
