extends SceneTree

const WAVE_REWARD_MENU_SCENE := preload("res://scenes/ui/rewards/WaveRewardMenu.tscn")
const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")

var _closed_count: int = 0


class FakeTickManager:
	extends Node

	var speed_scale: float = 2.5

	func pause() -> void:
		speed_scale = 0.0

	func set_speed(value: float) -> void:
		speed_scale = value


class FakeGameScene:
	extends Node

	var open_calls: Array[String] = []
	var reward_menu_trader: Control = Control.new()

	func _init() -> void:
		reward_menu_trader.name = "TraderMenu"
		reward_menu_trader.visible = false

	func open_reward_menu_trader() -> void:
		open_calls.append("open_reward_menu_trader")
		reward_menu_trader.visible = true


func _init() -> void:
	call_deferred("_run_test")


func _assert(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_wave_reward_menu_interaction] %s" % message)
	quit(1)
	return false


func _find_card(menu: WaveRewardMenu, reward_type: String) -> WaveRewardCard:
	if menu.cards_container == null:
		return null
	for child in menu.cards_container.get_children():
		var card := child as WaveRewardCard
		if card != null and card.reward_type == reward_type:
			return card
	return null


func _on_menu_closed() -> void:
	_closed_count += 1


func _run_test() -> void:
	var tick_manager := get_root().get_node_or_null("TickManager")
	if tick_manager == null:
		tick_manager = FakeTickManager.new()
		tick_manager.name = "TickManager"
		get_root().add_child(tick_manager)

	var previous_tick_speed: float = 0.0
	if tick_manager != null:
		previous_tick_speed = float(tick_manager.get("speed_scale"))

	var game_scene := FakeGameScene.new()
	game_scene.name = "FakeGameScene"
	game_scene.add_to_group("game_scene")
	get_root().add_child(game_scene)

	var menu := WAVE_REWARD_MENU_SCENE.instantiate() as WaveRewardMenu
	if not _assert(menu != null, "failed to instantiate WaveRewardMenu"):
		return
	get_root().add_child(menu)

	_closed_count = 0
	menu.closed.connect(Callable(self, "_on_menu_closed"))

	var rewards: Array = [
		{"type": ProphecyPatternScript.RewardType.DENARII, "amount": 25},
		{"custom_id": "trader"},
	]
	menu.open(rewards)
	await process_frame

	if not _assert(menu.visible, "menu must become visible after open"):
		return
	if not _assert(menu.cards_container.get_child_count() == 2, "menu must build both requested reward cards"):
		return
	if not _assert(paused, "opening reward menu must pause the SceneTree"):
		return
	if not _assert(is_equal_approx(float(tick_manager.get("speed_scale")), 0.0), "opening reward menu must stop tick speed"):
		return

	var trader_card := _find_card(menu, "trader")
	if not _assert(trader_card != null, "trader card must be present for submenu coverage"):
		return
	trader_card._on_claim_pressed()
	await process_frame

	if not _assert(game_scene.open_calls == ["open_reward_menu_trader"], "submenu reward must call the trader opener through the router"):
		return
	if not _assert(not menu.visible, "menu must hide while submenu is open"):
		return
	if not _assert(bool(menu.get("_waiting_for_submenu")), "submenu reward must keep waiting state enabled"):
		return
	if not _assert(menu.get("_submenu_node") == game_scene.reward_menu_trader, "menu must track the opened submenu node"):
		return
	if not _assert(paused, "submenu-open path must keep the SceneTree paused"):
		return
	if not _assert(is_equal_approx(float(tick_manager.get("speed_scale")), 0.0), "submenu-open path must keep TickManager paused"):
		return
	if not _assert(menu.cards_container.get_child_count() == 1, "submenu claim must remove the claimed card from the menu"):
		return
	if not _assert(_closed_count == 0, "menu must stay open overall while another reward remains"):
		return

	game_scene.reward_menu_trader.visible = false
	await process_frame

	if not _assert(menu.visible, "menu must reappear after submenu closes when rewards remain"):
		return
	if not _assert(not bool(menu.get("_waiting_for_submenu")), "submenu recovery must clear waiting state"):
		return
	if not _assert(paused, "menu must remain paused after submenu closes if rewards remain"):
		return
	if not _assert(is_equal_approx(float(tick_manager.get("speed_scale")), 0.0), "TickManager must stay paused until the last card is claimed"):
		return

	var denarii_card := _find_card(menu, "denarii:25")
	if not _assert(denarii_card != null, "denarii card must remain claimable after submenu recovery"):
		return
	denarii_card._on_claim_pressed()
	await process_frame

	if not _assert(menu.cards_container.get_child_count() == 0, "final immediate claim must remove the last card"):
		return
	if not _assert(not menu.visible, "menu must close after the last remaining reward is claimed"):
		return
	if not _assert(not paused, "closing the final reward flow must restore SceneTree pause state"):
		return
	if not _assert(is_equal_approx(float(tick_manager.get("speed_scale")), previous_tick_speed), "TickManager speed must return to its pre-menu value"):
		return
	if not _assert(_closed_count == 1, "menu must emit closed exactly once after all rewards are claimed (got %d)" % _closed_count):
		return

	print("[test_wave_reward_menu_interaction] PASS")
	quit(0)
