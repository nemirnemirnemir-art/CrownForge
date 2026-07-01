extends RefCounted
class_name SpellAvailabilityChecker

const CharacterCreationSpellCatalogScript := preload("res://scripts/ui/spells/CharacterCreationSpellCatalog.gd")

const DEFAULT_PASSIVE_REQUIREMENTS := {
	"lumberjack_tree_requirement": 10,
	"reward_boss_requirement": 1,
	"good_reward_boss_requirement": 2,
	"spicy_boys_morale_requirement": 70,
}


func get_default_passive_requirements() -> Dictionary:
	return DEFAULT_PASSIVE_REQUIREMENTS.duplicate(true)


func can_activate_active_ability(ability_id: String, active_upgrade_level: int, economy_core: Variant, resource_core: Variant, corpse_source: Variant, hero_core: Variant) -> bool:
	return get_active_ability_unavailability_reason(ability_id, active_upgrade_level, economy_core, resource_core, corpse_source, hero_core) == ""


func get_active_ability_cost(ability_id: String, active_upgrade_level: int) -> Dictionary:
	var normalized_id := String(ability_id).strip_edges().to_lower()
	if normalized_id == "":
		return {}
	var resource_id := CharacterCreationSpellCatalogScript.get_spell_cost_resource_id(normalized_id)
	var amount := CharacterCreationSpellCatalogScript.get_spell_cost(normalized_id, active_upgrade_level)
	if resource_id == "" or amount <= 0:
		return {}
	return {resource_id: amount}


func get_active_ability_resource_status(ability_id: String, active_upgrade_level: int, economy_core: Variant, resource_core: Variant) -> Dictionary:
	var cost := get_active_ability_cost(ability_id, active_upgrade_level)
	if cost.is_empty():
		return {}
	var resource_id := String(cost.keys()[0])
	var required := int(cost.get(resource_id, 0))
	var owned := 0
	if resource_id == "gold":
		owned = int(economy_core.get_gold()) if economy_core != null else 0
	else:
		owned = int(resource_core.get_resource(resource_id)) if resource_core != null else 0
	return {
		"resource_id": resource_id,
		"required": required,
		"owned": owned,
	}


func can_afford_active_ability(ability_id: String, active_upgrade_level: int, economy_core: Variant, resource_core: Variant) -> bool:
	var status := get_active_ability_resource_status(ability_id, active_upgrade_level, economy_core, resource_core)
	if status.is_empty():
		return true
	return int(status.get("owned", 0)) >= int(status.get("required", 0))


func get_active_ability_unavailability_reason(ability_id: String, active_upgrade_level: int, economy_core: Variant, resource_core: Variant, corpse_source: Variant, hero_core: Variant) -> String:
	if not can_afford_active_ability(ability_id, active_upgrade_level, economy_core, resource_core):
		var status := get_active_ability_resource_status(ability_id, active_upgrade_level, economy_core, resource_core)
		var resource_id := String(status.get("resource_id", ""))
		return "Requires %d %s (%d/%d)." % [
			int(status.get("required", 0)),
			resource_id.replace("_", " "),
			int(status.get("owned", 0)),
			int(status.get("required", 0))
		]
	match String(ability_id):
		"resurrection":
			if corpse_source == null or corpse_source.active_corpses.is_empty():
				return "Requires at least 1 corpse on the battlefield."
		"training":
			if hero_core == null or hero_core.get_active_heroes().is_empty():
				return "Requires at least 1 allied unit on the battlefield."
	return ""


func can_activate_passive_ability(ability_id: String, state: Dictionary, castle_core: Variant, morale_system: Variant, requirements: Dictionary) -> bool:
	return get_passive_ability_unavailability_reason(ability_id, state, castle_core, morale_system, requirements) == ""


func get_passive_ability_unavailability_reason(ability_id: String, state: Dictionary, castle_core: Variant, morale_system: Variant, requirements: Dictionary) -> String:
	var chopped_tree_count := int(state.get("chopped_tree_count", 0))
	var bosses_killed_count := int(state.get("bosses_killed_count", 0))
	var lumberjack_tree_requirement := int(requirements.get("lumberjack_tree_requirement", 0))
	var reward_boss_requirement := int(requirements.get("reward_boss_requirement", 0))
	var good_reward_boss_requirement := int(requirements.get("good_reward_boss_requirement", 0))
	var spicy_boys_morale_requirement := int(requirements.get("spicy_boys_morale_requirement", 0))

	match String(ability_id):
		"lumberjack":
			if chopped_tree_count < lumberjack_tree_requirement:
				return "Requires %d chopped trees (%d/%d)." % [lumberjack_tree_requirement, chopped_tree_count, lumberjack_tree_requirement]
		"reward":
			if bosses_killed_count < reward_boss_requirement:
				return "Requires %d boss kill (%d/%d)." % [reward_boss_requirement, bosses_killed_count, reward_boss_requirement]
		"good_reward":
			if bosses_killed_count < good_reward_boss_requirement:
				return "Requires %d boss kills (%d/%d)." % [good_reward_boss_requirement, bosses_killed_count, good_reward_boss_requirement]
		"last_chance":
			if castle_core == null:
				return "Castle state unavailable."
			var max_hp := float(castle_core.get_effective_max_hp())
			if max_hp <= 0.0:
				return "Castle state unavailable."
			var hp_ratio := float(castle_core.current_hp) / max_hp
			if hp_ratio > 0.3:
				return "Requires castle HP at or below 30%%."
		"spells_for_work":
			if bosses_killed_count < reward_boss_requirement:
				return "Requires %d boss kill (%d/%d)." % [reward_boss_requirement, bosses_killed_count, reward_boss_requirement]
		"spicy_boys":
			if morale_system == null or morale_system.get_total_morale() < spicy_boys_morale_requirement:
				var morale := 0
				if morale_system != null:
					morale = int(morale_system.get_total_morale())
				return "Requires %d morale (%d/%d)." % [spicy_boys_morale_requirement, morale, spicy_boys_morale_requirement]
	return ""


func spend_active_ability_cost(ability_id: String, active_upgrade_level: int, economy_core: Variant, resource_core: Variant) -> bool:
	var status := get_active_ability_resource_status(ability_id, active_upgrade_level, economy_core, resource_core)
	if status.is_empty():
		return true
	var resource_id := String(status.get("resource_id", ""))
	var required := int(status.get("required", 0))
	if required <= 0:
		return true
	if resource_id == "gold":
		return economy_core != null and economy_core.spend_gold(float(required))
	return resource_core != null and resource_core.consume_resource(resource_id, required)
