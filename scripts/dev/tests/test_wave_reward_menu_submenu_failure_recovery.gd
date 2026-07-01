extends SceneTree

const WAVE_REWARD_MENU_SCENE := preload("res://scenes/ui/rewards/WaveRewardMenu.tscn")

var _closed_count: int = 0


class FakeTickManager:
	extends Node

	var speed_scale: float = 1.75

	func pause() -> void:
		speed_scale = 0.0

	func set_speed(value: float) -> void:
		speed_scale = value


func _init() -> void:
	call_deferred("_run_test")


func _assert(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_wave_reward_menu_submenu_failure_recovery] %s" % message)
	quit(1)
	return false


func _on_menu_closed() -> void:
	_closed_count += 1


func _run_test() -> void:
	var tick_manager := get_root().get_node_or_null("TickManager")
	if tick_manager == null:
		tick_manager = FakeTickManager.new()
		tick_manager.name = "TickManager"
		get_root().add_child(tick_manager)

	var previous_tick_speed := float(tick_manager.get("speed_scale"))
	var menu := WAVE_REWARD_MENU_SCENE.instantiate() as WaveRewardMenu
	if not _assert(menu != null, "failed to instantiate WaveRewardMenu"):
		return
	get_root().add_child(menu)

	_closed_count = 0
	menu.closed.connect(Callable(self, "_on_menu_closed"))
	menu.open([{"custom_id": "trader"}])
	await process_frame

	if not _assert(menu.visible, "menu must open before claiming the submenu reward"):
		return
	if not _assert(menu.cards_container.get_child_count() == 1, "menu must build the single submenu reward card"):
		return
	if not _assert(paused, "opening reward menu must pause the SceneTree"):
		return
	if not _assert(is_equal_approx(float(tick_manager.get("speed_scale")), 0.0), "opening reward menu must pause TickManager"):
		return

	var trader_card := menu.cards_container.get_child(0) as WaveRewardCard
	if not _assert(trader_card != null and trader_card.reward_type == "trader", "single reward must be the trader submenu card"):
		return
	trader_card._on_claim_pressed()
	await process_frame

	if not _assert(menu.cards_container.get_child_count() == 0, "claiming the last submenu reward must remove the card"):
		return
	if not _assert(not bool(menu.get("_waiting_for_submenu")), "failed submenu open must clear waiting state"):
		return
	if not _assert(menu.get("_submenu_node") == null, "failed submenu open must not keep a submenu reference"):
		return
	if not _assert(not menu.visible, "failed submenu open on the last reward must close the menu"):
		return
	if not _assert(not paused, "failed submenu open on the last reward must restore SceneTree pause state"):
		return
	if not _assert(is_equal_approx(float(tick_manager.get("speed_scale")), previous_tick_speed), "failed submenu open on the last reward must restore TickManager speed"):
		return
	if not _assert(_closed_count == 1, "failed submenu open on the last reward must emit closed exactly once"):
		return

	print("[test_wave_reward_menu_submenu_failure_recovery] PASS")
	quit(0)
