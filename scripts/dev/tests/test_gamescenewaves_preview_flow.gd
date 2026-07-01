extends SceneTree

const WavePreviewFlowScript := preload("res://scripts/game_scene/modules/WavePreviewFlow.gd")


class FakeWaveTimer:
	extends RefCounted

	var set_calls: Array = []
	var clear_calls: Array[int] = []

	func set_wave_preview(wave_number: int, payload: Dictionary) -> void:
		set_calls.append([wave_number, payload.duplicate(true)])

	func clear_wave_preview(wave_number: int) -> void:
		clear_calls.append(wave_number)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = WavePreviewFlowScript.new()
	if flow == null:
		push_error("[test_gamescenewaves_preview_flow] failed to instantiate helper")
		quit(1)
		return

	var timer := FakeWaveTimer.new()
	var queue := [{"id": "p1"}, {"id": "p2"}]
	var display_slots := [1, 2]
	var preview_builder := func(pattern, display_number: int) -> Dictionary:
		return {"id": pattern["id"], "display": display_number, "flag_label": str(display_number)}
	var intro_builder := func(prophecy_level: int) -> Dictionary:
		return {"flag_label": "P%d" % prophecy_level}
	var trader_builder := func() -> Dictionary:
		return {"custom_id": "trader", "flag_label": "T"}
	var boss_builder := func() -> Dictionary:
		return {"flag_label": "B"}

	flow.update_wave_timer_previews(timer, 2, true, false, 1, queue, 0, display_slots, 0, true, false, preview_builder, intro_builder, trader_builder, boss_builder)
	if timer.set_calls.size() != 5:
		push_error("[test_gamescenewaves_preview_flow] expected intro + two prophecy previews + trader + next prophecy marker")
		quit(1)
		return
	if int(timer.set_calls[0][0]) != 3 or int(timer.set_calls[1][0]) != 4 or int(timer.set_calls[2][0]) != 5 or int(timer.set_calls[3][0]) != 6 or int(timer.set_calls[4][0]) != 7:
		push_error("[test_gamescenewaves_preview_flow] absolute preview numbering mismatch")
		quit(1)
		return
	if String(timer.set_calls[0][1].get("flag_label", "")) != "P1" or String(timer.set_calls[1][1].get("flag_label", "")) != "1" or String(timer.set_calls[2][1].get("flag_label", "")) != "2" or String(timer.set_calls[3][1].get("flag_label", "")) != "T" or String(timer.set_calls[4][1].get("flag_label", "")) != "P2":
		push_error("[test_gamescenewaves_preview_flow] expected preview labels P1,1,2,T,P2, got %s" % str(timer.set_calls))
		quit(1)
		return

	timer.set_calls.clear()
	flow.update_wave_timer_previews(timer, 0, true, true, 1, [], 0, [], 0, false, false, preview_builder, intro_builder, trader_builder, boss_builder)
	if timer.set_calls.size() != 5:
		push_error("[test_gamescenewaves_preview_flow] expected startup labels P1,1,2,3,P2")
		quit(1)
		return
	var startup_labels := []
	for call in timer.set_calls:
		startup_labels.append(String(call[1].get("flag_label", "")))
	if str(startup_labels) != str(["P1", "1", "2", "3", "P2"]):
		push_error("[test_gamescenewaves_preview_flow] startup prophecy labels mismatch: %s" % str(startup_labels))
		quit(1)
		return

	timer.set_calls.clear()
	flow.update_wave_timer_previews(timer, 5, false, false, 4, [{"id": "a"}, {"id": "b"}, {"id": "c"}], 0, [1, 2, 3], 0, false, true, preview_builder, intro_builder, trader_builder, boss_builder)
	if timer.set_calls.size() != 4:
		push_error("[test_gamescenewaves_preview_flow] expected three prophecy previews and one boss preview")
		quit(1)
		return
	if String(timer.set_calls[0][1].get("flag_label", "")) != "1" or String(timer.set_calls[1][1].get("flag_label", "")) != "2" or String(timer.set_calls[2][1].get("flag_label", "")) != "3" or String(timer.set_calls[3][1].get("flag_label", "")) != "B":
		push_error("[test_gamescenewaves_preview_flow] expected preview labels 1,2,3,B, got %s" % str(timer.set_calls))
		quit(1)
		return

	timer.set_calls.clear()
	flow.update_wave_timer_previews(timer, 8, false, true, 4, [], 0, [], 0, false, true, preview_builder, intro_builder, trader_builder, boss_builder)
	if timer.set_calls.size() != 5:
		push_error("[test_gamescenewaves_preview_flow] expected startup labels P4,1,2,3,B")
		quit(1)
		return
	var p4_startup_labels := []
	for call in timer.set_calls:
		p4_startup_labels.append(String(call[1].get("flag_label", "")))
	if str(p4_startup_labels) != str(["P4", "1", "2", "3", "B"]):
		push_error("[test_gamescenewaves_preview_flow] startup prophecy 4 labels mismatch: %s" % str(p4_startup_labels))
		quit(1)
		return

	flow.clear_future_wave_previews(timer, 5)
	if timer.clear_calls.size() != 6:
		push_error("[test_gamescenewaves_preview_flow] expected 6 preview clears")
		quit(1)
		return

	print("[test_gamescenewaves_preview_flow] PASS")
	quit(0)
