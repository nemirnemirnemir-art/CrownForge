extends RefCounted

var _slot: Node = null
var _config: BuildingConfig = null
var _timer: float = 0.0
var _is_producing: bool = false
var _fortification_charges: int = 0
var _fortification_bonus_hp: int = 0
var _applied_fortification_bonus_hp: int = 0

const FORTIFICATION_CHARGES_PER_HP := 5
const FORTIFICATION_MAX_BONUS_HP := 100

func initialize(slot: Node, config: BuildingConfig) -> void:
	_slot = slot
	_config = config
	_timer = 0.0
	_is_producing = false
	_fortification_charges = 0
	_fortification_bonus_hp = 0
	_applied_fortification_bonus_hp = 0

func tick(delta: float) -> Dictionary:
	if _config == null:
		return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0}
	var cycle: float = _get_effective_cycle_time()
	
	if not _is_producing:
		if _config.consumes.size() > 0:
			if not _config.can_produce():
				return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": cycle}
			_config.consume_inputs()
		_is_producing = true
		_timer = 0.0
	
	_timer += delta
	var progress_ratio: float = max(0.0, (cycle - _timer) / cycle)
	var completed: bool = false
	
	if _timer >= cycle:
		_timer = 0.0
		_is_producing = false
		completed = true
		_on_cycle_completed()
	
	return {"progress_ratio": progress_ratio, "is_producing": _is_producing, "completed": completed, "cycle_time": cycle}

func _on_cycle_completed() -> void:
	if CastleCore and CastleCore.has_method("heal"):
		CastleCore.heal(1)
	if _has_upgrade("brick_factory:1"):
		_process_fortifications()

func get_runtime_state() -> Dictionary:
	return {
		"timer": _timer,
		"is_producing": _is_producing,
		"fortification_charges": _fortification_charges,
		"fortification_bonus_hp": _fortification_bonus_hp,
	}

func load_runtime_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	_timer = maxf(0.0, float(state.get("timer", 0.0)))
	_is_producing = bool(state.get("is_producing", false))
	_fortification_charges = max(0, int(state.get("fortification_charges", 0)))
	_fortification_bonus_hp = clampi(int(state.get("fortification_bonus_hp", 0)), 0, FORTIFICATION_MAX_BONUS_HP)
	if CastleCore and CastleCore.has_method("add_bonus_max_hp") and _fortification_bonus_hp > _applied_fortification_bonus_hp:
		var missing_bonus := _fortification_bonus_hp - _applied_fortification_bonus_hp
		_applied_fortification_bonus_hp = _fortification_bonus_hp
		CastleCore.add_bonus_max_hp(missing_bonus)

func _process_fortifications() -> void:
	if CastleCore == null or not CastleCore.has_method("get_effective_max_hp"):
		return
	if CastleCore.current_hp < CastleCore.get_effective_max_hp():
		return
	if _fortification_bonus_hp >= FORTIFICATION_MAX_BONUS_HP:
		return
	_fortification_charges += 1
	while _fortification_charges >= FORTIFICATION_CHARGES_PER_HP and _fortification_bonus_hp < FORTIFICATION_MAX_BONUS_HP:
		_fortification_charges -= FORTIFICATION_CHARGES_PER_HP
		_fortification_bonus_hp += 1
		_applied_fortification_bonus_hp += 1
		if CastleCore.has_method("add_bonus_max_hp"):
			CastleCore.add_bonus_max_hp(1)

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

func _get_effective_cycle_time() -> float:
	var speed_mult := 1.0
	if _has_upgrade("brick_factory:0"):
		speed_mult *= 2.0
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
	return max(0.001, float(_config.cycle_time) / speed_mult)
