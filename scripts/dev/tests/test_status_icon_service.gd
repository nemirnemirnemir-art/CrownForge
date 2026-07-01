extends SceneTree


func _init() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	call_deferred("_run_test", root)


func _run_test(root: Node2D) -> void:
	# ── Test 1: Add single icon ──────────────────────────────────────────
	var target := Node2D.new()
	root.add_child(target)

	await process_frame
	await process_frame

	var icon := StatusIconService.add_status_icon(
		target,
		"res://assets/vfx/spells/Frailty.png",
		"TestIcon1",
		-55.0,
	)

	if icon == null:
		push_error("[test_status_icon_service] add_status_icon returned null")
		quit(1)
		return

	if not (icon is Sprite2D):
		push_error("[test_status_icon_service] expected Sprite2D, got %s" % icon.get_class())
		quit(1)
		return

	if icon.get_parent() != target:
		push_error("[test_status_icon_service] icon parent should be target")
		quit(1)
		return

	if not icon.has_meta("status_icon") or not bool(icon.get_meta("status_icon")):
		push_error("[test_status_icon_service] icon missing status_icon meta")
		quit(1)
		return

	print("[test_status_icon_service] PASS test 1 – add single icon")

	# ── Test 2: Reflow with multiple icons ───────────────────────────────
	var target2 := Node2D.new()
	root.add_child(target2)

	await process_frame

	var icon_a := StatusIconService.add_status_icon(
		target2,
		"res://assets/vfx/spells/Frailty.png",
		"IconA",
		-55.0,
	)
	var icon_b := StatusIconService.add_status_icon(
		target2,
		"res://assets/vfx/spells/Frailty.png",
		"IconB",
		-55.0,
	)

	if icon_a == null or icon_b == null:
		push_error("[test_status_icon_service] failed to add two icons for reflow test")
		quit(1)
		return

	StatusIconService.reflow_status_icons(target2)

	# With 2 icons and spacing 42.0:
	#   total_width = (2 - 1) * 42.0 = 42.0
	#   icon_a.x = -42.0 * 0.5 + 0 * 42.0 = -21.0
	#   icon_b.x = -42.0 * 0.5 + 1 * 42.0 =  21.0
	var expected_a_x := -21.0
	var expected_b_x := 21.0

	if abs(icon_a.position.x - expected_a_x) > 0.01:
		push_error("[test_status_icon_service] icon_a.x expected %.1f, got %.3f" % [expected_a_x, icon_a.position.x])
		quit(1)
		return

	if abs(icon_b.position.x - expected_b_x) > 0.01:
		push_error("[test_status_icon_service] icon_b.x expected %.1f, got %.3f" % [expected_b_x, icon_b.position.x])
		quit(1)
		return

	print("[test_status_icon_service] PASS test 2 – reflow positions correct")

	# ── Test 3: Remove icon ──────────────────────────────────────────────
	var target3 := Node2D.new()
	root.add_child(target3)

	await process_frame

	var icon_to_remove := StatusIconService.add_status_icon(
		target3,
		"res://assets/vfx/spells/Frailty.png",
		"RemoveMe",
		-55.0,
	)

	if icon_to_remove == null:
		push_error("[test_status_icon_service] failed to add icon for remove test")
		quit(1)
		return

	StatusIconService.remove_status_icon(target3, weakref(icon_to_remove))

	# queue_free is deferred, so wait a frame for it to process
	await process_frame

	if is_instance_valid(icon_to_remove):
		push_error("[test_status_icon_service] icon should have been freed after remove")
		quit(1)
		return

	print("[test_status_icon_service] PASS test 3 – remove icon freed")

	# ── All passed ───────────────────────────────────────────────────────
	print("[test_status_icon_service] PASS")
	quit(0)
