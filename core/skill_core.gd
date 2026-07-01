extends Node
## SkillCore autoload singleton
## Manages active skills, mana, and skill effects.
## Refactored to use SkillInstance for state management.

const API_VERSION := 2

## Signals
signal skill_activated(skill_id: String, duration: float)
signal skill_ended(skill_id: String)
# Legacy signals
@warning_ignore("UNUSED_SIGNAL")
signal skill1_toggled(active: bool) 

## Constants
const MAGE_TOWER_ID: String = "mage_tower"

const BASE_CRIT_CHANCE: float = 0.0
const SKILL3_CRIT_CHANCE: float = 0.25
const CRIT_DAMAGE_MULTIPLIER: float = 2.0

const GENERIC_SKILL_DURATION: float = 30.0

# Skill IDs
enum SkillID {
	AUTO_CLICKER = 1,
	DOUBLE_DAMAGE = 2,
	CRIT_ROULETTE = 3,
	GOLD_DIGGER = 4,
	HEAVY_POCKETS = 5,
	HEAL_SUPPLY = 6,
	MEGA_CLICKS = 8,
	DOUBLE_EFFECT = 9,
	RELOAD = 10
}

# Skill Configs (Cost, Duration, Cooldown)
const SKILL_CONFIG = {
	1: { "name": "auto_clicker", "cost": 100.0, "dur": 30.0 },
	2: { "name": "double_damage", "cost": 100.0, "dur": 30.0 },
	3: { "name": "crit_roulette", "cost": 100.0, "dur": 30.0 },
	4: { "name": "gold_digger", "cost": 100.0, "dur": 30.0 },
	5: { "name": "heavy_pockets", "cost": 100.0, "dur": 30.0 },
	6: { "name": "heal_supply", "cost": 100.0, "dur": 30.0 },
	8: { "name": "mega_clicks", "cost": 100.0, "dur": 30.0 },
	9: { "name": "double_effect", "cost": 100.0, "dur": 30.0, "cd": 3600.0 },
	10: { "name": "reload", "cost": 100.0, "dur": 0.0, "cd": 3600.0 }
}

# Effect Constants
const SKILL1_AUTOCLICK_INTERVAL: float = 0.5
const SKILL2_ALL_DAMAGE_MULT: float = 1.25
const SKILL4_GOLD_DIGGER_FRACTION: float = 0.10
const SKILL5_MOB_GOLD_MULT: float = 2.0
const SKILL6_HEAL_FRACTION_PER_SEC: float = 0.10
const SKILL8_CLICK_DAMAGE_MULT: float = 3.0
const SKILL9_NEXT_EFFECT_MULT: float = 2.0

## State
var _skills: Dictionary = {} # int -> SkillInstance
var _double_effect_pending: bool = false
var _last_skill_used_index: int = 0
var _effects: SkillEffects

# Special State for Skill 1
var _skill1_autoclick_hits: int = 1
# Special State for Skill 6
var _skill6_heal_tick_timer: float = 0.0

func _ready() -> void:
	_effects = SkillEffects.new()
	_effects.init(self)
	_initialize_skills()

func _initialize_skills() -> void:
	for id in SKILL_CONFIG:
		var cfg = SKILL_CONFIG[id]
		var cd = cfg.get("cd", 0.0)
		var s = SkillInstance.new(self, id, cfg.name, cfg.cost, cfg.dur, cd)
		s.ended.connect(_on_skill_ended.bind(id))
		s.activated.connect(_on_skill_activated.bind(id))
		_skills[id] = s

func _process(delta: float) -> void:
	# mana system removed

	# Process all skills
	for s in _skills.values():
		s.process(delta)
		
	# Special Tick Logic for Heal (Skill 6)
	if _skills.has(6) and _skills[6].active:
		_skill6_heal_tick_timer -= delta
		if _skill6_heal_tick_timer <= 0.0:
			_skill6_heal_tick_timer = 1.0
			_heal_battle_heroes_tick()

## === PUBLIC API ===

# Activation Wrappers (Backward Compatibility)
func activate_skill1() -> void: _try_activate_skill(1)
func activate_skill2() -> void: _try_activate_skill(2)
func activate_skill3() -> void: _try_activate_skill(3)
func activate_skill4() -> void: _try_activate_skill(4)
func activate_skill5() -> void: _try_activate_skill(5)
func activate_skill6() -> void: _try_activate_skill(6)
func activate_skill7() -> void: pass # Empty
func activate_skill8() -> void: _try_activate_skill(8)
func activate_skill9() -> void: _try_activate_skill(9)
func activate_skill10() -> void: _try_activate_skill(10)

func _try_activate_skill(id: int) -> void:
	if not _skills.has(id): return
	var s: SkillInstance = _skills[id]
	
	if not s.can_activate(_mage_tower_level()):
		return
		
	# Special Pre-Activation Logic
	if id == 10:
		_apply_reload_last_skill()
		# Skill 10 consumes mana via activate(), but functionality is instant
		
	if s.activate(_consume_next_effect_multiplier):
		_last_skill_used_index = id
		
		# Special Post-Activation Logic
		if id == 9:
			_double_effect_pending = true
		if id == 1:
			_skill1_autoclick_hits = max(1, int(round(s.effect_multiplier)))
			EventBus.skill1_toggled.emit(true) # Legacy signal
		if id == 6:
			_skill6_heal_tick_timer = 1.0

func _on_skill_activated(duration: float, id: int) -> void:
	skill_activated.emit(_skills[id].name, duration)

func _on_skill_ended(id: int) -> void:
	skill_ended.emit(_skills[id].name)
	if id == 1:
		_skill1_autoclick_hits = 1
		EventBus.skill1_toggled.emit(false)
	if id == 9:
		_double_effect_pending = false

## Getters
func is_skill_active(id: int) -> bool:
	return _skills.has(id) and _skills[id].active

func is_skill1_active() -> bool: return is_skill_active(1)

func get_skill_duration_seconds(id: int) -> float:
	return _skills[id].duration if _skills.has(id) else 0.0

func get_skill_active_remaining(id: int) -> float:
	return _skills[id].timer if _skills.has(id) else 0.0

func get_skill_cooldown_total(id: int) -> float:
	return _skills[id].cooldown if _skills.has(id) else 0.0

func get_skill_cooldown_remaining(id: int) -> float:
	return _skills[id].get_cooldown_remaining() if _skills.has(id) else 0.0
## Effects
func get_global_damage_multiplier() -> float:
	var mult := 1.0
	if is_skill_active(2):
		# +25% base, scaled by effect mutiplier
		mult *= (1.0 + (0.25 * _skills[2].effect_multiplier))
	if BuildingUpgradeCore and BuildingUpgradeCore.has_method("get_buddhist_temple_troop_damage_multiplier"):
		mult *= float(BuildingUpgradeCore.get_buddhist_temple_troop_damage_multiplier())
	return mult

func get_damage_multiplier() -> float:
	var mult := get_global_damage_multiplier()
	if is_skill_active(8):
		mult *= (SKILL8_CLICK_DAMAGE_MULT * _skills[8].effect_multiplier)
	return mult

func get_autoclick_damage_multiplier() -> float:
	return get_global_damage_multiplier()

func get_gold_gain_multiplier() -> float:
	var mult := 1.0
	if is_skill_active(5):
		mult *= (1.0 + (1.0 * _skills[5].effect_multiplier))
	return mult

func get_crit_chance() -> float:
	var chance := BASE_CRIT_CHANCE
	if is_skill_active(3):
		chance += (SKILL3_CRIT_CHANCE * _skills[3].effect_multiplier)
	return clamp(chance, 0.0, 1.0)

func get_gold_digger_fraction() -> float:
	if not is_skill_active(4): return 0.0
	return clamp(SKILL4_GOLD_DIGGER_FRACTION * _skills[4].effect_multiplier, 0.0, 1.0)

func try_apply_gold_digger_on_click(target: Node) -> void:
	_effects.try_apply_gold_digger_on_click(target)

func get_crit_damage_multiplier() -> float:
	return CRIT_DAMAGE_MULTIPLIER

func roll_crit() -> bool:
	var chance := get_crit_chance()
	if chance <= 0.0: return false
	return randf() < chance

## Internal Logic
func _mage_tower_level() -> int:
	return TownCore.get_building_level(MAGE_TOWER_ID) if TownCore else 0

func _mage_tower_unlocked() -> bool:
	return _mage_tower_level() >= 1

func _consume_next_effect_multiplier() -> float:
	if not _double_effect_pending:
		return 1.0
	_double_effect_pending = false
	# Determine if we should consume the Double Effect active state?
	# In original code: "if skill9_active: skill9_active = false..."
	if is_skill_active(9):
		_skills[9].force_end()
	return SKILL9_NEXT_EFFECT_MULT

func _apply_reload_last_skill() -> void:
	var idx := _last_skill_used_index
	if idx <= 0: return

	# Reset Cooldown for 9/10
	if idx == 9 or idx == 10:
		if _skills.has(idx):
			_skills[idx].reset_cooldown() 
		return

	# End active skill
	if _skills.has(idx):
		_skills[idx].force_end()

func _heal_battle_heroes_tick() -> void:
	_effects.heal_battle_heroes_tick()

func get_skill1_autoclick_hits() -> int:
	return _skill1_autoclick_hits

# Debug
func debug_reset_all_skill_cooldowns() -> void:
	for s in _skills.values():
		s.reset_cooldown()
		s.force_end()

## Save/Load
func get_save_data() -> Dictionary:
	var skill_data = {}
	for id in _skills:
		skill_data[id] = _skills[id].get_save_data()
	return {
		"skills": skill_data
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("skills") and data["skills"] is Dictionary:
		var sd = data["skills"]
		for id in sd:
			id = int(id) # JSON keys are strings
			if _skills.has(id):
				_skills[id].load_save_data(sd[str(id)])

