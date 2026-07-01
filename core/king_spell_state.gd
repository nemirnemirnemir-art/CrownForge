extends Node

const CharacterCreationSpellCatalogScript := preload("res://scripts/ui/spells/CharacterCreationSpellCatalog.gd")
const SpellAvailabilityCheckerScript := preload("res://core/king_spell/SpellAvailabilityChecker.gd")
const SpellUpgradeServiceScript := preload("res://core/king_spell/SpellUpgradeService.gd")

const MAX_ACTIVE_UPGRADE_LEVEL := SpellUpgradeServiceScript.MAX_ACTIVE_UPGRADE_LEVEL

var selected_active_spell_id: String = ""
var selected_passive_spell_id: String = ""
var active_cooldowns: Dictionary = {}
var used_passives: Dictionary = {}
var active_upgrade_level: int = 0
var productivity_bonus_multiplier: float = 0.0
var productivity_bonus_time_left: float = 0.0
var chopped_tree_count: int = 0
var bosses_killed_count: int = 0

var _availability_checker: RefCounted = SpellAvailabilityCheckerScript.new()
var _upgrade_service: RefCounted = SpellUpgradeServiceScript.new()

func begin_run_from_character_creation(character_creation_state: Variant = null) -> void:
	var resolved_state: Object = _resolve_character_creation_state(character_creation_state)
	selected_active_spell_id = _read_string_property(resolved_state, "selected_active_spell_id")
	selected_passive_spell_id = _read_string_property(resolved_state, "selected_passive_spell_id")
	active_cooldowns.clear()
	used_passives.clear()
	active_upgrade_level = 0
	productivity_bonus_multiplier = 0.0
	productivity_bonus_time_left = 0.0
	chopped_tree_count = 0
	bosses_killed_count = 0

func clear_selected_spells() -> void:
	selected_active_spell_id = ""
	selected_passive_spell_id = ""
	active_upgrade_level = 0
	chopped_tree_count = 0
	bosses_killed_count = 0

func reset_runtime_state() -> void:
	active_cooldowns.clear()
	used_passives.clear()
	active_upgrade_level = 0
	productivity_bonus_multiplier = 0.0
	productivity_bonus_time_left = 0.0
	chopped_tree_count = 0
	bosses_killed_count = 0

func set_active_cooldown(spell_id: String, duration_sec: float) -> void:
	active_cooldowns[String(spell_id)] = maxf(0.0, duration_sec)

func get_active_cooldown(spell_id: String) -> float:
	var target_spell_id := String(spell_id)
	var resolved := {target_spell_id: float(active_cooldowns.get(target_spell_id, 0.0))}
	var artifact_core := _get_singleton("ArtifactCore")
	if artifact_core != null and artifact_core.has_method("get_active_cooldowns_with_artifact_modifiers"):
		var modified: Variant = artifact_core.call("get_active_cooldowns_with_artifact_modifiers", resolved)
		if modified is Dictionary:
			return float((modified as Dictionary).get(target_spell_id, resolved[target_spell_id]))
	return float(resolved.get(target_spell_id, 0.0))

func reduce_all_active_cooldowns_flat(amount_sec: float) -> void:
	if amount_sec <= 0.0:
		return
	for spell_id in active_cooldowns.keys():
		var next_value := maxf(0.0, float(active_cooldowns.get(spell_id, 0.0)) - amount_sec)
		active_cooldowns[spell_id] = next_value

func tick_cooldowns(delta: float) -> void:
	if delta <= 0.0:
		return
	for spell_id in active_cooldowns.keys():
		var next_value := maxf(0.0, float(active_cooldowns.get(spell_id, 0.0)) - delta)
		active_cooldowns[spell_id] = next_value
	if productivity_bonus_time_left > 0.0:
		productivity_bonus_time_left = maxf(0.0, productivity_bonus_time_left - delta)
		if productivity_bonus_time_left <= 0.0:
			productivity_bonus_multiplier = 0.0

func apply_productivity_bonus(multiplier: float, duration_sec: float) -> void:
	productivity_bonus_multiplier = maxf(productivity_bonus_multiplier, multiplier)
	productivity_bonus_time_left = maxf(productivity_bonus_time_left, duration_sec)

func get_productivity_bonus_multiplier() -> float:
	if productivity_bonus_time_left <= 0.0:
		return 0.0
	return productivity_bonus_multiplier

func register_tree_chopped(count: int = 1) -> void:
	if count <= 0:
		return
	chopped_tree_count += count

func register_boss_killed(count: int = 1) -> void:
	if count <= 0:
		return
	bosses_killed_count += count

func can_activate_active_ability(ability_id: String) -> bool:
	if get_active_cooldown(ability_id) > 0.0:
		return false
	return _availability_checker.can_activate_active_ability(
		ability_id,
		active_upgrade_level,
		_get_singleton("EconomyCore"),
		_get_singleton("ResourceCore"),
		_get_singleton("Corpse"),
		_get_singleton("HeroCore")
	)

func get_active_ability_cost(ability_id: String) -> Dictionary:
	return _availability_checker.get_active_ability_cost(ability_id, active_upgrade_level)

func get_active_ability_resource_status(ability_id: String) -> Dictionary:
	return _availability_checker.get_active_ability_resource_status(
		ability_id,
		active_upgrade_level,
		_get_singleton("EconomyCore"),
		_get_singleton("ResourceCore")
	)

func can_afford_active_ability(ability_id: String) -> bool:
	return _availability_checker.can_afford_active_ability(
		ability_id,
		active_upgrade_level,
		_get_singleton("EconomyCore"),
		_get_singleton("ResourceCore")
	)

func get_active_ability_unavailability_reason(ability_id: String) -> String:
	if get_active_cooldown(ability_id) > 0.0:
		return "On cooldown."
	return _availability_checker.get_active_ability_unavailability_reason(
		ability_id,
		active_upgrade_level,
		_get_singleton("EconomyCore"),
		_get_singleton("ResourceCore"),
		_get_singleton("Corpse"),
		_get_singleton("HeroCore")
	)

func can_activate_passive_ability(ability_id: String) -> bool:
	return _availability_checker.can_activate_passive_ability(
		ability_id,
		_get_passive_requirement_state(),
		_get_singleton("CastleCore"),
		_get_singleton("MoraleSystem"),
		_availability_checker.get_default_passive_requirements()
	)

func get_passive_ability_unavailability_reason(ability_id: String) -> String:
	return _availability_checker.get_passive_ability_unavailability_reason(
		ability_id,
		_get_passive_requirement_state(),
		_get_singleton("CastleCore"),
		_get_singleton("MoraleSystem"),
		_availability_checker.get_default_passive_requirements()
	)

func spend_active_ability_cost(ability_id: String) -> bool:
	return _availability_checker.spend_active_ability_cost(
		ability_id,
		active_upgrade_level,
		_get_singleton("EconomyCore"),
		_get_singleton("ResourceCore")
	)

func mark_passive_used(spell_id: String) -> void:
	used_passives[String(spell_id)] = true

func is_passive_used(spell_id: String) -> bool:
	return bool(used_passives.get(String(spell_id), false))

func can_upgrade_active_spells() -> bool:
	return _upgrade_service.can_upgrade_active_spells(active_upgrade_level, MAX_ACTIVE_UPGRADE_LEVEL)

func get_next_upgrade_cost() -> Dictionary:
	return _upgrade_service.get_next_upgrade_cost(active_upgrade_level, MAX_ACTIVE_UPGRADE_LEVEL, _upgrade_service.get_active_upgrade_costs())

func try_purchase_active_upgrade() -> bool:
	var result: Dictionary = _upgrade_service.try_purchase_active_upgrade(
		active_upgrade_level,
		MAX_ACTIVE_UPGRADE_LEVEL,
		_upgrade_service.get_active_upgrade_costs(),
		_get_singleton("EconomyCore"),
		_get_singleton("ResourceCore")
	)
	if not bool(result.get("purchased", false)):
		return false
	active_upgrade_level = int(result.get("next_level", active_upgrade_level))
	return true


func _resolve_character_creation_state(explicit_state: Variant = null) -> Object:
	if explicit_state != null:
		return explicit_state as Object
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree == null or scene_tree.root == null:
		return null
	return scene_tree.root.get_node_or_null("/root/CharacterCreationState")


func _get_singleton(singleton_name: String) -> Node:
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree == null or scene_tree.root == null:
		return null
	return scene_tree.root.get_node_or_null("/root/%s" % singleton_name)


func _read_string_property(source: Object, property_name: String) -> String:
	if source == null:
		return ""
	var value: Variant = source.get(property_name)
	if value == null:
		return ""
	return String(value)


func _get_passive_requirement_state() -> Dictionary:
	return {
		"chopped_tree_count": chopped_tree_count,
		"bosses_killed_count": bosses_killed_count,
	}
