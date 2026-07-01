extends RefCounted
class_name GameSceneRewardDispatcher

## Consolidates all reward-menu opening and reward-enqueueing logic for GameScene.
## Accesses the parent scene via _scene to read node/manager references.

const ArtifactSpellRewardsScript = preload("res://core/artifacts/ArtifactSpellRewards.gd")

var _scene = null


func initialize(scene) -> void:
	_scene = scene


# --- Open reward menus ---

func open_reward_menu_base_production() -> void:
	if _scene._reward_menus_manager:
		_scene._reward_menus_manager.open_base_production()


func open_reward_menu_established_production() -> void:
	if _scene.reward_menu_established_production:
		_scene.reward_menu_established_production.building_category = int(BuildingConfig.BuildingCategory.ESTABLISHED_PRODUCTION)
		_scene.reward_menu_established_production.menu_title = "Choose established production building"
		if not _scene.reward_menu_established_production.visible:
			_scene.reward_menu_established_production.open()


func open_reward_menu_advanced_production() -> void:
	if _scene.reward_menu_established_production:
		_scene.reward_menu_established_production.building_category = int(BuildingConfig.BuildingCategory.ADVANCED_PRODUCTION)
		_scene.reward_menu_established_production.menu_title = "Choose advanced production building"
		if not _scene.reward_menu_established_production.visible:
			_scene.reward_menu_established_production.open()


func open_reward_menu_kingdom_infrastructure() -> void:
	if _scene.reward_menu_kingdom_infrastructure and not _scene.reward_menu_kingdom_infrastructure.visible:
		_scene.reward_menu_kingdom_infrastructure.open()


func open_reward_menu_levy_barracks() -> void:
	if _scene.reward_menu_levy_barracks:
		_scene.reward_menu_levy_barracks.building_category = int(BuildingConfig.BuildingCategory.LEVY_BARRACKS)
		_scene.reward_menu_levy_barracks.menu_title = "Choose a levy barracks building"
		if _scene._reward_menus_manager:
			_scene._reward_menus_manager.open_levy_barracks()


func open_reward_menu_veteran_barracks() -> void:
	if _scene.reward_menu_levy_barracks:
		_scene.reward_menu_levy_barracks.building_category = int(BuildingConfig.BuildingCategory.VETERAN_BARRACKS)
		_scene.reward_menu_levy_barracks.menu_title = "Choose a veteran barracks building"
		if _scene._reward_menus_manager:
			_scene._reward_menus_manager.open_levy_barracks()


func open_reward_menu_elite_barracks() -> void:
	if _scene.reward_menu_levy_barracks:
		_scene.reward_menu_levy_barracks.building_category = int(BuildingConfig.BuildingCategory.ELITE_BARRACKS)
		_scene.reward_menu_levy_barracks.menu_title = "Choose an elite barracks building"
		if _scene._reward_menus_manager:
			_scene._reward_menus_manager.open_levy_barracks()


func open_reward_menu_artifacts(offered_count: int = 2, legendary_only: bool = false) -> void:
	if _scene._reward_menus_manager:
		_scene._reward_menus_manager.open_artifacts(offered_count, legendary_only)


func open_reward_menu_troop_bonuses() -> void:
	if _scene._reward_menus_manager:
		_scene._reward_menus_manager.open_troop_bonuses()


func open_reward_menu_building_upgrades() -> void:
	if _scene._reward_menus_manager:
		_scene._reward_menus_manager.open_building_upgrades()


func open_reward_menu_resources(amount: int = 0) -> void:
	if _scene._reward_menus_manager:
		_scene._reward_menus_manager.open_resources(amount)


func open_reward_menu_spells(offered_count: int = 2, legendary_only: bool = false) -> void:
	if _scene._reward_menus_manager:
		_scene._reward_menus_manager.open_spells(offered_count, legendary_only)


func open_reward_menu_legendary_spells(offered_count: int = 2) -> void:
	if _scene._reward_menus_manager:
		_scene._reward_menus_manager.open_legendary_spells(offered_count)


func open_reward_menu_trader() -> void:
	if _scene._reward_menus_manager:
		_scene._reward_menus_manager.open_trader()


# --- Enqueue rewards ---

func enqueue_pending_reward(reward: Dictionary) -> void:
	if _scene._pending_rewards_manager:
		_scene._pending_rewards_manager.enqueue_reward(reward)


func enqueue_resource_choice_reward(amount: int, count: int = 1) -> void:
	if _scene._pending_rewards_manager == null:
		return
	if amount <= 0:
		return
	for i in range(max(0, count)):
		_scene._pending_rewards_manager.enqueue_reward({
			"type": "resource_choice",
			"amount": amount,
		})


func enqueue_spell_grant_reward(spell_id: String, count: int = 1) -> void:
	if _scene._pending_rewards_manager == null:
		return
	var safe_spell_id := String(spell_id).strip_edges()
	if safe_spell_id == "":
		return
	for i in range(max(0, count)):
		_scene._pending_rewards_manager.enqueue_reward({
			"type": "spell_grant",
			"spell_id": safe_spell_id,
		})


func enqueue_spell_choice_reward(offered_count: int = 2, legendary_only: bool = false, count: int = 1) -> void:
	if _scene._pending_rewards_manager == null:
		return
	var safe_offered_count: int = max(1, offered_count)
	for i in range(max(0, count)):
		_scene._pending_rewards_manager.enqueue_reward({
			"type": "spell_choice",
			"offered_count": safe_offered_count,
			"legendary_only": legendary_only,
		})


func enqueue_established_production_reward() -> void:
	if _scene._pending_rewards_manager:
		_scene._pending_rewards_manager.enqueue_reward({"type": "established_production_choice"})


func enqueue_base_production_reward() -> void:
	if _scene._pending_rewards_manager:
		_scene._pending_rewards_manager.enqueue_reward({"type": "base_production_choice"})


func enqueue_advanced_production_reward() -> void:
	if _scene._pending_rewards_manager:
		_scene._pending_rewards_manager.enqueue_reward({"type": "advanced_production_choice"})


func enqueue_kingdom_infrastructure_reward() -> void:
	if _scene._pending_rewards_manager:
		_scene._pending_rewards_manager.enqueue_reward({"type": "kingdom_infrastructure_choice"})


func enqueue_levy_barracks_reward() -> void:
	if _scene._pending_rewards_manager:
		_scene._pending_rewards_manager.enqueue_reward({"type": "levy_barracks_choice"})


func enqueue_veteran_barracks_reward() -> void:
	if _scene._pending_rewards_manager:
		_scene._pending_rewards_manager.enqueue_reward({"type": "veteran_barracks_choice"})


func enqueue_elite_barracks_reward() -> void:
	if _scene._pending_rewards_manager:
		_scene._pending_rewards_manager.enqueue_reward({"type": "elite_barracks_choice"})


func enqueue_artifact_reward() -> void:
	if _scene._pending_rewards_manager:
		_scene._pending_rewards_manager.enqueue_reward({"type": "artifact_choice"})


func enqueue_building_upgrade_reward() -> void:
	if _scene._pending_rewards_manager:
		_scene._pending_rewards_manager.enqueue_reward({"type": "building_upgrade_choice"})


func enqueue_troop_bonus_reward() -> void:
	if _scene._pending_rewards_manager:
		_scene._pending_rewards_manager.enqueue_reward({"type": "troop_bonus_choice"})


# --- Pending reward gate ---

func can_open_pending_reward() -> bool:
	var modal_nodes: Array = [
		_scene.reward_menu_base_production,
		_scene.reward_menu_established_production,
		_scene.reward_menu_kingdom_infrastructure,
		_scene.reward_menu_levy_barracks,
		_scene.reward_menu_artifacts,
		_scene.reward_menu_troop_bonuses,
		_scene.reward_menu_building_upgrades,
		_scene.reward_menu_resources,
		_scene.reward_menu_spells,
		_scene.reward_menu_legendary_spells,
		_scene.reward_menu_trader,
		_scene.wave_reward_menu,
		_scene.prophecy_menu,
		_scene.encounter_menu,
	]
	for node in modal_nodes:
		if node and node.visible:
			return false
	return true


func open_pending_reward(reward: Dictionary) -> bool:
	var reward_type := String(reward.get("type", ""))
	match reward_type:
		"base_production_choice":
			if _scene.reward_menu_base_production == null or _scene.reward_menu_base_production.visible:
				return false
			open_reward_menu_base_production()
			return _scene.reward_menu_base_production != null and _scene.reward_menu_base_production.visible
		"resource_choice":
			var amount := int(reward.get("amount", 0))
			if amount <= 0 or _scene.reward_menu_resources == null or _scene.reward_menu_resources.visible:
				return false
			open_reward_menu_resources(amount)
			return _scene.reward_menu_resources != null and _scene.reward_menu_resources.visible
		"established_production_choice":
			if _scene.reward_menu_established_production == null or _scene.reward_menu_established_production.visible:
				return false
			open_reward_menu_established_production()
			return _scene.reward_menu_established_production.visible
		"advanced_production_choice":
			if _scene.reward_menu_established_production == null or _scene.reward_menu_established_production.visible:
				return false
			open_reward_menu_advanced_production()
			return _scene.reward_menu_established_production.visible
		"kingdom_infrastructure_choice":
			if _scene.reward_menu_kingdom_infrastructure == null or _scene.reward_menu_kingdom_infrastructure.visible:
				return false
			open_reward_menu_kingdom_infrastructure()
			return _scene.reward_menu_kingdom_infrastructure.visible
		"levy_barracks_choice":
			if _scene.reward_menu_levy_barracks == null or _scene.reward_menu_levy_barracks.visible:
				return false
			open_reward_menu_levy_barracks()
			return _scene.reward_menu_levy_barracks.visible
		"veteran_barracks_choice":
			if _scene.reward_menu_levy_barracks == null or _scene.reward_menu_levy_barracks.visible:
				return false
			open_reward_menu_veteran_barracks()
			return _scene.reward_menu_levy_barracks.visible
		"elite_barracks_choice":
			if _scene.reward_menu_levy_barracks == null or _scene.reward_menu_levy_barracks.visible:
				return false
			open_reward_menu_elite_barracks()
			return _scene.reward_menu_levy_barracks.visible
		"artifact_choice":
			var artifact_offered_count: int = max(1, int(reward.get("offered_count", 2)))
			var artifact_legendary_only := bool(reward.get("legendary_only", false))
			if _scene.reward_menu_artifacts == null or _scene.reward_menu_artifacts.visible:
				return false
			open_reward_menu_artifacts(artifact_offered_count, artifact_legendary_only)
			return _scene.reward_menu_artifacts != null and _scene.reward_menu_artifacts.visible
		"spell_grant":
			var spell_id := String(reward.get("spell_id", "")).strip_edges()
			if spell_id == "":
				return false
			ArtifactSpellRewardsScript.add_spell_with_panel_fallback(spell_id, 1)
			return true
		"spell_choice":
			var offered_count: int = max(1, int(reward.get("offered_count", 2)))
			var legendary_only := bool(reward.get("legendary_only", false))
			if legendary_only:
				if _scene.reward_menu_legendary_spells == null or _scene.reward_menu_legendary_spells.visible:
					return false
				open_reward_menu_legendary_spells(offered_count)
				return _scene.reward_menu_legendary_spells.visible
			if _scene.reward_menu_spells == null or _scene.reward_menu_spells.visible:
				return false
			open_reward_menu_spells(offered_count, false)
			return _scene.reward_menu_spells.visible
		"building_upgrade_choice":
			if _scene.reward_menu_building_upgrades == null or _scene.reward_menu_building_upgrades.visible:
				return false
			open_reward_menu_building_upgrades()
			return _scene.reward_menu_building_upgrades.visible
		"troop_bonus_choice":
			if _scene.reward_menu_troop_bonuses == null or _scene.reward_menu_troop_bonuses.visible:
				return false
			open_reward_menu_troop_bonuses()
			return _scene.reward_menu_troop_bonuses.visible
	return false


func open_reward_menu_prophecy() -> void:
	if _scene._wave_flow_manager and _scene._wave_flow_manager.has_method("consume_pending_open_prophecy"):
		_scene._wave_flow_manager.consume_pending_open_prophecy()
	if _scene._reward_menus_manager and _scene._pause_state_manager:
		var opened = _scene._reward_menus_manager.open_prophecy(_scene._pause_state_manager, _scene._pending_open_prophecy)
		if opened:
			_scene._pending_open_prophecy = false
