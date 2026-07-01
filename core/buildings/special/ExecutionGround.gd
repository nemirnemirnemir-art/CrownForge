extends RefCounted

const EXECUTION_CYCLE_SEC := 8.0
const GLOBAL_COOLDOWN_SEC := 2.0

var _slot: Node = null
var _config: BuildingConfig = null
var _timer: float = 0.0
var _is_producing: bool = false
var _cooldown_timer: float = 0.0
var _pending_hero_id: String = ""
var _troop_inspiration_applied: bool = false

func initialize(slot: Node, config: BuildingConfig) -> void:
	_slot = slot
	_config = config
	_timer = 0.0
	_is_producing = false
	_cooldown_timer = 0.0
	_pending_hero_id = ""
	_troop_inspiration_applied = false

func tick(delta: float) -> Dictionary:
	if _config == null:
		return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0}
	var cycle: float = _get_effective_cycle_time(EXECUTION_CYCLE_SEC)
	if _cooldown_timer > 0.0:
		_cooldown_timer = maxf(0.0, _cooldown_timer - delta)
		return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": cycle}
	if not _is_producing:
		_pending_hero_id = _find_reserve_grunt_hero_id()
		if _pending_hero_id == "":
			return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": cycle}
		_is_producing = true
		_timer = 0.0
	_timer += delta
	var progress_ratio: float = maxf(0.0, (cycle - _timer) / cycle)
	var completed: bool = false
	if _timer >= cycle:
		_timer = 0.0
		_is_producing = false
		completed = true
		_on_cycle_completed()
	return {"progress_ratio": progress_ratio, "is_producing": _is_producing, "completed": completed, "cycle_time": cycle}

func _on_cycle_completed() -> void:
	var hero_id := _pending_hero_id
	_pending_hero_id = ""
	if hero_id == "":
		_cooldown_timer = GLOBAL_COOLDOWN_SEC
		return
	if HeroCore == null or not HeroCore.query or not HeroCore.query.has_hero(hero_id):
		_cooldown_timer = GLOBAL_COOLDOWN_SEC
		return
	HeroCore.remove_hero(hero_id)
	var reward_amount := 1.0
	if _has_upgrade("execution_ground:0"):
		reward_amount += 2.0
	if EconomyCore and EconomyCore.has_method("add_gold"):
		EconomyCore.add_gold(reward_amount)
	_apply_troop_inspiration_bonus_if_needed()
	_cooldown_timer = GLOBAL_COOLDOWN_SEC

func _find_reserve_grunt_hero_id() -> String:
	if HeroCore == null or HeroCore.query == null:
		return ""
	for hero_value in HeroCore.heroes.values():
		if not (hero_value is Dictionary):
			continue
		var hero := hero_value as Dictionary
		if not bool(hero.get("is_hired", false)) or bool(hero.get("isDead", false)):
			continue
		if bool(hero.get("is_summon", false)):
			continue
		if bool(hero.get("isActive", false)):
			continue
		var hero_id := String(hero.get("id", ""))
		if hero_id == "":
			continue
		if not _is_grunt_hero(hero_id):
			continue
		return hero_id
	return ""

func _is_grunt_hero(hero_id: String) -> bool:
	if hero_id == "":
		return false
	var icon_id := String(HeroCore.query.get_hero_icon_id(hero_id)).to_lower()
	if icon_id == "":
		return false
	if TroopBonusCore and TroopBonusCore.has_method("get_unit_classes"):
		var classes: Array = TroopBonusCore.get_unit_classes(icon_id)
		return classes.has(UnitConfig.UnitClass.GRUNT)
	return icon_id == "grunt"

func _apply_troop_inspiration_bonus_if_needed() -> void:
	if _troop_inspiration_applied:
		return
	if not _has_upgrade("execution_ground:1"):
		return
	if TroopBonusCore == null or not TroopBonusCore.has_method("add_bonus_percent"):
		return
	TroopBonusCore.add_bonus_percent(int(UnitConfig.UnitClass.GRUNT), int(TroopBonusCore.BonusStat.HP), 0.10)
	TroopBonusCore.add_bonus_percent(int(UnitConfig.UnitClass.GRUNT), int(TroopBonusCore.BonusStat.DAMAGE), 0.10)
	_troop_inspiration_applied = true

func get_runtime_state() -> Dictionary:
	return {
		"timer": _timer,
		"is_producing": _is_producing,
		"cooldown_timer": _cooldown_timer,
		"pending_hero_id": _pending_hero_id,
		"troop_inspiration_applied": _troop_inspiration_applied,
	}

func load_runtime_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	_timer = maxf(0.0, float(state.get("timer", 0.0)))
	_is_producing = bool(state.get("is_producing", false))
	_cooldown_timer = maxf(0.0, float(state.get("cooldown_timer", 0.0)))
	_pending_hero_id = String(state.get("pending_hero_id", ""))
	_troop_inspiration_applied = bool(state.get("troop_inspiration_applied", false))
	# Backward compat: if the old synthetic upgrade ID exists, treat inspiration as already applied
	if not _troop_inspiration_applied:
		var slot_index := _get_slot_index()
		if slot_index >= 0 and BuildingUpgradeCore and BuildingUpgradeCore.has_method("get_upgrades"):
			var upgrades: Array = BuildingUpgradeCore.get_upgrades(slot_index)
			if upgrades.has("execution_ground:1:applied"):
				_troop_inspiration_applied = true

func _has_upgrade(upgrade_id: String) -> bool:
	if BuildingUpgradeCore == null or not BuildingUpgradeCore.has_method("has_upgrade"):
		return false
	var slot_index := _get_slot_index()
	if slot_index < 0:
		return false
	return bool(BuildingUpgradeCore.has_upgrade(slot_index, upgrade_id))

func _get_slot_index() -> int:
	if _slot == null or not is_instance_valid(_slot):
		return -1
	return int(_slot.get("slot_index"))

func _get_effective_cycle_time(base_cycle: float) -> float:
	var speed_mult := 1.0
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var artifact_core := tree.root.get_node_or_null("ArtifactCore")
		if artifact_core != null and artifact_core.has_method("get_resource_production_speed_multiplier"):
			speed_mult *= float(artifact_core.call("get_resource_production_speed_multiplier"))
	if MoraleSystem:
		speed_mult *= (1.0 + MoraleSystem.get_productivity_modifier())
	if KingSpellState:
		speed_mult *= (1.0 + KingSpellState.get_productivity_bonus_multiplier())
	if speed_mult <= 0.0:
		speed_mult = 0.0001
	return maxf(0.001, base_cycle / speed_mult)
