extends SceneTree

const WaveTimerControllerScript := preload("res://scripts/game_scene/modules/WaveTimerController.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var controller = WaveTimerControllerScript.new()
	if controller == null:
		push_error("[test_gamescenewaves_wave_timer_controller] failed to instantiate helper")
		quit(1)
		return

	if absf(controller.get_wave_interval_for_number(0, -1, -1) - 100.0) > 0.01:
		push_error("[test_gamescenewaves_wave_timer_controller] first wave interval mismatch")
		quit(1)
		return
	if absf(controller.get_wave_interval_for_number(6, 6, -1) - 60.0) > 0.01:
		push_error("[test_gamescenewaves_wave_timer_controller] trader wave interval mismatch")
		quit(1)
		return
	if absf(controller.get_wave_interval_for_number(7, 6, -1) - 90.0) > 0.01:
		push_error("[test_gamescenewaves_wave_timer_controller] post trader interval mismatch")
		quit(1)
		return
	if absf(controller.get_wave_interval_for_number(9, -1, 9) - 90.0) > 0.01:
		push_error("[test_gamescenewaves_wave_timer_controller] explicit post-trader first wave mismatch")
		quit(1)
		return

	var prophecy_preview: Dictionary = controller.build_prophecy_marker_payload(
		2,
		[FakePattern.new("wall_buster", 4)],
		[
			{"type": 0, "amount": 10},
			{"type": 5, "amount": 1},
			{"type": 2, "amount": 1},
			{"type": 2, "amount": 1},
			{"type": 9, "amount": 1},
			{"type": 13, "amount": 1},
			{"type": 15, "amount": 1},
		],
		Callable(self, "_aggregate_mob_counts")
	)
	if String(prophecy_preview.get("flag_label", "")) != "P2":
		push_error("[test_gamescenewaves_wave_timer_controller] prophecy marker label mismatch")
		quit(1)
		return
	var prophecy_counts: Dictionary = prophecy_preview.get("mob_counts", {})
	if int(prophecy_counts.get("wall_buster", 0)) != 4:
		push_error("[test_gamescenewaves_wave_timer_controller] prophecy marker must expose real guard mob counts")
		quit(1)
		return
	var prophecy_rewards: Array = prophecy_preview.get("rewards", [])
	if prophecy_rewards.size() != 7:
		push_error("[test_gamescenewaves_wave_timer_controller] prophecy marker must expose real reward bundle")
		quit(1)
		return

	var boss_preview: Dictionary = controller.build_boss_preview_payload([
		FakePattern.new("goblin_giant", 2, "goblin_shaman", 3)
	], Callable(self, "_aggregate_mob_counts"))
	if String(boss_preview.get("flag_label", "")) != "B":
		push_error("[test_gamescenewaves_wave_timer_controller] boss marker label mismatch")
		quit(1)
		return

	print("[test_gamescenewaves_wave_timer_controller] PASS")
	quit(0)


class FakePattern:
	extends RefCounted

	var mob_1_id: String
	var mob_1_count: int
	var mob_2_enabled: bool
	var mob_2_id: String
	var mob_2_count: int
	var reward_1_type: int = 0
	var reward_1_amount: int = 10
	var reward_2_enabled: bool = false
	var reward_2_type: int = 0
	var reward_2_amount: int = 0

	func _init(m1: String, c1: int, m2: String = "", c2: int = 0) -> void:
		mob_1_id = m1
		mob_1_count = c1
		mob_2_id = m2
		mob_2_count = c2
		mob_2_enabled = m2 != "" and c2 > 0


func _aggregate_mob_counts(patterns: Array) -> Dictionary:
	var out: Dictionary = {}
	for pattern in patterns:
		if pattern == null:
			continue
		out[String(pattern.mob_1_id)] = int(out.get(String(pattern.mob_1_id), 0)) + int(pattern.mob_1_count)
		if bool(pattern.mob_2_enabled):
			out[String(pattern.mob_2_id)] = int(out.get(String(pattern.mob_2_id), 0)) + int(pattern.mob_2_count)
	return out
