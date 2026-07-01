extends RefCounted
class_name WaveRewardSubmenuRouter

func open(menu_type: String, amount: int, tree: SceneTree, menu: Control, recover_from_wait: Callable, debug_dump: Callable) -> void:
	if tree == null:
		print("[WaveRewardMenu] ERROR: SceneTree not available while opening submenu")
		recover_from_wait.call("missing scene tree")
		return
	var game_scene := tree.get_first_node_in_group("game_scene")
	if game_scene == null:
		print("[WaveRewardMenu] ERROR: GameScene not found!")
		recover_from_wait.call("missing game_scene")
		return

	menu.visible = false
	menu.set("_waiting_for_submenu", true)
	menu.set("_submenu_wait_elapsed", 0.0)
	debug_dump.call("open_submenu %s" % menu_type)

	var handled := _open_known_submenu(menu_type, amount, game_scene, menu, recover_from_wait)
	if not handled:
		recover_from_wait.call("unknown submenu type")


func _open_known_submenu(menu_type: String, amount: int, game_scene: Node, menu: Control, recover_from_wait: Callable) -> bool:
	match menu_type:
		"levy":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_levy_barracks", "reward_menu_levy_barracks", "levy submenu missing")
		"production":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_base_production", "reward_menu_base_production", "production submenu missing")
		"production_established":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_established_production", "reward_menu_established_production", "established production submenu missing")
		"production_advanced":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_advanced_production", "reward_menu_established_production", "advanced production submenu missing")
		"infrastructure":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_kingdom_infrastructure", "reward_menu_kingdom_infrastructure", "infrastructure submenu missing")
		"prophecy":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_prophecy", "prophecy_menu", "prophecy submenu missing")
		"resource":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_resources", "reward_menu_resources", "resource submenu missing", [amount])
		"trader":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_trader", "reward_menu_trader", "trader submenu missing")
		"artifact":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_artifacts", "reward_menu_artifacts", "artifact submenu missing")
		"building_upgrade":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_building_upgrades", "reward_menu_building_upgrades", "building upgrade submenu missing")
		"troop_training":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_troop_bonuses", "reward_menu_troop_bonuses", "troop training submenu missing")
		"veteran":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_veteran_barracks", "reward_menu_levy_barracks", "veteran barracks submenu missing")
		"elite":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_elite_barracks", "reward_menu_levy_barracks", "elite barracks submenu missing")
		"spell":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_spells", "reward_menu_spells", "spells submenu missing")
		"legendary_spell":
			return _open_submenu(game_scene, menu, recover_from_wait, "open_reward_menu_legendary_spells", "reward_menu_legendary_spells", "legendary spells submenu missing")
	return false


func _open_submenu(game_scene: Node, menu: Control, recover_from_wait: Callable, opener_method: StringName, submenu_property: StringName, missing_reason: String, opener_args: Array = []) -> bool:
	if not game_scene.has_method(opener_method):
		recover_from_wait.call(missing_reason)
		return true

	var submenu_node := game_scene.get(String(submenu_property)) as Control
	if submenu_node == null:
		recover_from_wait.call(missing_reason)
		return true

	menu.set("_submenu_node", submenu_node)
	if opener_args.is_empty():
		game_scene.call(String(opener_method))
	else:
		game_scene.callv(String(opener_method), opener_args)
	return true
