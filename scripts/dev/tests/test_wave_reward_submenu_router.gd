extends SceneTree

const ROUTER_PATH := "res://scripts/ui/rewards/modules/WaveRewardSubmenuRouter.gd"


class FakeEconomyCore:
	extends Node

	var add_gold_calls: Array[float] = []

	func add_gold(amount: float) -> void:
		add_gold_calls.append(amount)


class FakeMenuHost:
	extends Control

	var _waiting_for_submenu: bool = false
	var _submenu_node: Control = null
	var _submenu_wait_elapsed: float = 99.0
	var recover_reasons: Array[String] = []
	var debug_contexts: Array[String] = []

	func _init() -> void:
		visible = true

	func recover_from_wait(reason: String) -> void:
		recover_reasons.append(reason)
		_waiting_for_submenu = false
		_submenu_node = null
		_submenu_wait_elapsed = 0.0
		visible = true

	func debug_dump(context: String) -> void:
		debug_contexts.append(context)


class FakeGameScene:
	extends Node

	var open_calls: Array[String] = []
	var reward_menu_levy_barracks: Control = Control.new()
	var reward_menu_base_production: Control = Control.new()
	var reward_menu_established_production: Control = Control.new()
	var reward_menu_kingdom_infrastructure: Control = Control.new()
	var reward_menu_resources: Control = Control.new()
	var reward_menu_trader: Control = Control.new()
	var reward_menu_artifacts: Control = Control.new()
	var reward_menu_building_upgrades: Control = Control.new()
	var reward_menu_troop_bonuses: Control = Control.new()
	var reward_menu_spells: Control = Control.new()
	var reward_menu_legendary_spells: Control = Control.new()
	var prophecy_menu: Control = Control.new()

	func _init() -> void:
		reward_menu_levy_barracks.name = "LevyMenu"
		reward_menu_base_production.name = "BaseProductionMenu"
		reward_menu_established_production.name = "EstablishedProductionMenu"
		reward_menu_kingdom_infrastructure.name = "InfrastructureMenu"
		reward_menu_resources.name = "ResourceMenu"
		reward_menu_trader.name = "TraderMenu"
		reward_menu_artifacts.name = "ArtifactMenu"
		reward_menu_building_upgrades.name = "BuildingUpgradeMenu"
		reward_menu_troop_bonuses.name = "TroopTrainingMenu"
		reward_menu_spells.name = "SpellMenu"
		reward_menu_legendary_spells.name = "LegendarySpellMenu"
		prophecy_menu.name = "ProphecyMenu"

	func open_reward_menu_levy_barracks() -> void:
		open_calls.append("open_reward_menu_levy_barracks")

	func open_reward_menu_base_production() -> void:
		open_calls.append("open_reward_menu_base_production")

	func open_reward_menu_established_production() -> void:
		open_calls.append("open_reward_menu_established_production")

	func open_reward_menu_advanced_production() -> void:
		open_calls.append("open_reward_menu_advanced_production")

	func open_reward_menu_kingdom_infrastructure() -> void:
		open_calls.append("open_reward_menu_kingdom_infrastructure")

	func open_reward_menu_prophecy() -> void:
		open_calls.append("open_reward_menu_prophecy")

	func open_reward_menu_resources(amount: int) -> void:
		open_calls.append("open_reward_menu_resources:%d" % amount)

	func open_reward_menu_trader() -> void:
		open_calls.append("open_reward_menu_trader")

	func open_reward_menu_artifacts() -> void:
		open_calls.append("open_reward_menu_artifacts")

	func open_reward_menu_building_upgrades() -> void:
		open_calls.append("open_reward_menu_building_upgrades")

	func open_reward_menu_troop_bonuses() -> void:
		open_calls.append("open_reward_menu_troop_bonuses")

	func open_reward_menu_veteran_barracks() -> void:
		open_calls.append("open_reward_menu_veteran_barracks")

	func open_reward_menu_elite_barracks() -> void:
		open_calls.append("open_reward_menu_elite_barracks")

	func open_reward_menu_spells() -> void:
		open_calls.append("open_reward_menu_spells")

	func open_reward_menu_legendary_spells() -> void:
		open_calls.append("open_reward_menu_legendary_spells")


func _init() -> void:
	call_deferred("_run_test")


func _assert(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_wave_reward_submenu_router] %s" % message)
	quit(1)
	return false


func _run_test() -> void:
	var router_script := load(ROUTER_PATH)
	if not _assert(router_script != null, "failed to load WaveRewardSubmenuRouter.gd"):
		return

	var router = router_script.new()
	if not _assert(router != null, "failed to instantiate WaveRewardSubmenuRouter"):
		return

	var game_scene := FakeGameScene.new()
	game_scene.add_to_group("game_scene")
	get_root().add_child(game_scene)

	var economy_core := FakeEconomyCore.new()
	economy_core.name = "EconomyCore"
	get_root().add_child(economy_core)

	var cases: Array[Dictionary] = [
		{"menu_type": "levy", "amount": 0, "expected_call": "open_reward_menu_levy_barracks", "expected_node": game_scene.reward_menu_levy_barracks},
		{"menu_type": "production", "amount": 0, "expected_call": "open_reward_menu_base_production", "expected_node": game_scene.reward_menu_base_production},
		{"menu_type": "production_established", "amount": 0, "expected_call": "open_reward_menu_established_production", "expected_node": game_scene.reward_menu_established_production},
		{"menu_type": "production_advanced", "amount": 0, "expected_call": "open_reward_menu_advanced_production", "expected_node": game_scene.reward_menu_established_production},
		{"menu_type": "infrastructure", "amount": 0, "expected_call": "open_reward_menu_kingdom_infrastructure", "expected_node": game_scene.reward_menu_kingdom_infrastructure},
		{"menu_type": "prophecy", "amount": 0, "expected_call": "open_reward_menu_prophecy", "expected_node": game_scene.prophecy_menu},
		{"menu_type": "resource", "amount": 45, "expected_call": "open_reward_menu_resources:45", "expected_node": game_scene.reward_menu_resources},
		{"menu_type": "trader", "amount": 0, "expected_call": "open_reward_menu_trader", "expected_node": game_scene.reward_menu_trader},
		{"menu_type": "artifact", "amount": 0, "expected_call": "open_reward_menu_artifacts", "expected_node": game_scene.reward_menu_artifacts},
		{"menu_type": "building_upgrade", "amount": 0, "expected_call": "open_reward_menu_building_upgrades", "expected_node": game_scene.reward_menu_building_upgrades},
		{"menu_type": "troop_training", "amount": 0, "expected_call": "open_reward_menu_troop_bonuses", "expected_node": game_scene.reward_menu_troop_bonuses},
		{"menu_type": "veteran", "amount": 0, "expected_call": "open_reward_menu_veteran_barracks", "expected_node": game_scene.reward_menu_levy_barracks},
		{"menu_type": "elite", "amount": 0, "expected_call": "open_reward_menu_elite_barracks", "expected_node": game_scene.reward_menu_levy_barracks},
		{"menu_type": "spell", "amount": 0, "expected_call": "open_reward_menu_spells", "expected_node": game_scene.reward_menu_spells},
		{"menu_type": "legendary_spell", "amount": 0, "expected_call": "open_reward_menu_legendary_spells", "expected_node": game_scene.reward_menu_legendary_spells},
	]

	for entry in cases:
		var host := FakeMenuHost.new()
		game_scene.open_calls.clear()
		router.call(
			"open",
			String(entry["menu_type"]),
			int(entry["amount"]),
			self,
			host,
			Callable(host, "recover_from_wait"),
			Callable(host, "debug_dump")
		)

		if not _assert(not host.visible, "%s must hide the parent reward menu" % entry["menu_type"]):
			return
		if not _assert(host._waiting_for_submenu, "%s must keep submenu waiting state enabled" % entry["menu_type"]):
			return
		if not _assert(is_equal_approx(host._submenu_wait_elapsed, 0.0), "%s must reset submenu wait timer" % entry["menu_type"]):
			return
		if not _assert(host._submenu_node == entry["expected_node"], "%s must attach the same submenu node as before" % entry["menu_type"]):
			return
		if not _assert(game_scene.open_calls == [String(entry["expected_call"])], "%s must call the same GameScene opener" % entry["menu_type"]):
			return
		if not _assert(host.recover_reasons.is_empty(), "%s should not trigger submenu recovery on success" % entry["menu_type"]):
			return
		if not _assert(host.debug_contexts == ["open_submenu %s" % String(entry["menu_type"])], "%s must keep debug dump context" % entry["menu_type"]):
			return

	var unknown_host := FakeMenuHost.new()
	router.call(
		"open",
		"unknown_menu",
		0,
		self,
		unknown_host,
		Callable(unknown_host, "recover_from_wait"),
		Callable(unknown_host, "debug_dump")
	)
	if not _assert(unknown_host.recover_reasons == ["unknown submenu type"], "unknown submenu type must fail safely via recovery callback"):
		return
	if not _assert(unknown_host.visible, "unknown submenu type must restore menu visibility"):
		return
	if not _assert(not unknown_host._waiting_for_submenu, "unknown submenu type must not leave waiting state enabled"):
		return
	if not _assert(unknown_host._submenu_node == null, "unknown submenu type must not keep dangling submenu reference"):
		return
	if not _assert(economy_core.add_gold_calls.is_empty(), "submenu router must not execute reward side effects"):
		return

	var missing_tree_host := FakeMenuHost.new()
	router.call(
		"open",
		"trader",
		0,
		null,
		missing_tree_host,
		Callable(missing_tree_host, "recover_from_wait"),
		Callable(missing_tree_host, "debug_dump")
	)
	if not _assert(missing_tree_host.recover_reasons == ["missing scene tree"], "missing SceneTree must recover submenu wait immediately"):
		return
	if not _assert(missing_tree_host.visible, "missing SceneTree must leave the parent menu visible"):
		return
	if not _assert(not missing_tree_host._waiting_for_submenu, "missing SceneTree must not leave waiting state enabled"):
		return
	if not _assert(missing_tree_host._submenu_node == null, "missing SceneTree must not keep a submenu reference"):
		return

	var missing_game_scene_host := FakeMenuHost.new()
	var tree_without_game_scene := SceneTree.new()
	router.call(
		"open",
		"trader",
		0,
		tree_without_game_scene,
		missing_game_scene_host,
		Callable(missing_game_scene_host, "recover_from_wait"),
		Callable(missing_game_scene_host, "debug_dump")
	)
	if not _assert(missing_game_scene_host.recover_reasons == ["missing game_scene"], "missing game_scene must recover submenu wait immediately"):
		return
	if not _assert(missing_game_scene_host.visible, "missing game_scene must leave the parent menu visible"):
		return
	if not _assert(not missing_game_scene_host._waiting_for_submenu, "missing game_scene must not leave waiting state enabled"):
		return
	if not _assert(missing_game_scene_host._submenu_node == null, "missing game_scene must not keep a submenu reference"):
		return

	print("[test_wave_reward_submenu_router] PASS")
	quit(0)
