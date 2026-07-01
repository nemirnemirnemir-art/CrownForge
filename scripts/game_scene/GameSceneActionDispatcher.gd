extends RefCounted
class_name GameSceneActionDispatcher

## Routes encounter UI actions and delegates wave/encounter signal handling for GameScene.
## Signal handler methods here mirror GameScene's private handlers so the thin wrappers
## in GameScene can delegate all logic here.

var _scene = null
var _reward_dispatcher = null


func initialize(scene, reward_dispatcher = null) -> void:
	_scene = scene
	_reward_dispatcher = reward_dispatcher


# --- Wave signal handlers ---

func on_wave_spawned(wave_number: int) -> void:
	print("[GameScene] Wave %d spawned, heroes will engage in 5 seconds" % wave_number)
	if _scene._heroes_manager:
		_scene._heroes_manager.on_wave_spawned(wave_number)


func on_wave_completed(wave_number: int) -> void:
	print("[GameScene] Wave %d completed! Showing rewards..." % wave_number)
	if _scene._wave_flow_manager:
		_scene._wave_flow_manager.on_wave_completed(wave_number)
	elif _scene.wave_reward_menu == null:
		print("[GameScene] ERROR: WaveRewardMenu not found!")


func on_wave_reward_menu_closed() -> void:
	if _scene._wave_flow_manager:
		_scene._wave_flow_manager.on_wave_reward_menu_closed()
	if _scene._encounter_flow_manager:
		_scene._encounter_flow_manager.on_reward_menu_visibility_changed()


# --- Prophecy signal handlers ---

func on_prophecy_confirmed(selected_waves: Array) -> void:
	if _scene._encounter_flow_manager:
		_scene._encounter_flow_manager.on_prophecy_confirmed(selected_waves)


func on_prophecy_batch_finished() -> void:
	if _scene._wave_flow_manager:
		_scene._wave_flow_manager.on_prophecy_batch_finished()


func try_open_encounter_after_prophecy() -> bool:
	if _scene._encounter_flow_manager:
		return _scene._encounter_flow_manager.try_open_encounter_after_prophecy()
	return false


# --- Encounter signal handlers ---

func on_encounter_option_selected(encounter_id: String, option_id: String) -> void:
	if _scene._encounter_flow_manager and not _scene._encounter_flow_manager.on_encounter_option_selected(encounter_id, option_id):
		push_warning("[GameScene] Encounter option failed: %s/%s" % [encounter_id, option_id])


func on_encounter_closed() -> void:
	if _scene._encounter_flow_manager:
		_scene._encounter_flow_manager.on_encounter_closed()


func execute_encounter_ui_actions(actions: Array) -> void:
	if _scene._encounter_flow_manager:
		_scene._encounter_flow_manager.execute_encounter_ui_actions(actions)


func on_encounter_reward_menu_visibility_changed() -> void:
	if _scene._encounter_flow_manager:
		_scene._encounter_flow_manager.on_reward_menu_visibility_changed()


func is_any_encounter_reward_menu_visible() -> bool:
	if _scene._encounter_flow_manager:
		return _scene._encounter_flow_manager.is_any_encounter_reward_menu_visible()
	return false


func open_next_encounter_ui_action() -> void:
	if _scene._encounter_flow_manager:
		_scene._encounter_flow_manager.open_next_encounter_ui_action()


func connect_encounter_reward_menu_signals() -> void:
	var reward_menus: Array[Control] = [
		_scene.reward_menu_base_production,
		_scene.reward_menu_established_production,
		_scene.reward_menu_kingdom_infrastructure,
		_scene.reward_menu_levy_barracks,
		_scene.reward_menu_artifacts,
		_scene.reward_menu_troop_bonuses,
		_scene.reward_menu_building_upgrades,
		_scene.reward_menu_spells,
		_scene.reward_menu_legendary_spells,
	]
	if _scene._encounter_flow_manager:
		_scene._encounter_flow_manager.bind_reward_menus(
			reward_menus,
			Callable(self, "on_encounter_reward_menu_visibility_changed")
		)


# --- Encounter UI action router ---

func run_encounter_ui_action(action_id: String) -> bool:
	var rd = _reward_dispatcher if _reward_dispatcher else _scene
	if action_id == "open_reward_menu_base_production":
		rd.enqueue_base_production_reward()
		return false
	if action_id == "open_reward_menu_established_production":
		rd.enqueue_established_production_reward()
		return false
	if action_id == "open_reward_menu_advanced_production":
		rd.enqueue_advanced_production_reward()
		return false
	if action_id == "open_reward_menu_levy_barracks":
		rd.enqueue_levy_barracks_reward()
		return false
	if action_id == "open_reward_menu_veteran_barracks":
		rd.enqueue_veteran_barracks_reward()
		return false
	if action_id == "open_reward_menu_elite_barracks":
		rd.enqueue_elite_barracks_reward()
		return false
	if action_id == "open_reward_menu_kingdom_infrastructure":
		rd.enqueue_kingdom_infrastructure_reward()
		return false
	if action_id == "open_reward_menu_artifacts":
		rd.enqueue_artifact_reward()
		return false
	if action_id == "open_reward_menu_spells":
		rd.open_reward_menu_spells()
		return _scene.reward_menu_spells != null and _scene.reward_menu_spells.visible
	if action_id == "open_reward_menu_legendary_spells":
		rd.open_reward_menu_legendary_spells()
		return _scene.reward_menu_legendary_spells != null and _scene.reward_menu_legendary_spells.visible
	if action_id == "open_reward_menu_building_upgrades":
		rd.enqueue_building_upgrade_reward()
		return false
	if action_id == "open_reward_menu_troop_bonuses":
		rd.enqueue_troop_bonus_reward()
		return false
	if action_id.begins_with("spawn_enemy:"):
		var parts := action_id.split(":", false)
		if parts.size() == 3 and _scene._waves_manager and _scene._waves_manager.has_method("debug_spawn_enemy_id"):
			_scene._waves_manager.debug_spawn_enemy_id(String(parts[1]), int(parts[2]))
		return false
	push_warning("[GameScene] Unknown encounter UI action: %s" % action_id)
	return false
