extends Node
## EconomyCore - Autoload singleton (no class_name needed)

const API_VERSION := 1

## State
var _current_gold: float = 0.0
var _current_stars: int = 0
var _upgrade_level: int = 0
var _test_base_damage_bonus: float = 0.0
var _current_forge_cores: int = 0

## Constants
const UPGRADE_BASE_PRICE: float = 10.0
const UPGRADE_SCALE_FACTOR: float = 1.5
const UPGRADE_DAMAGE_PER_LEVEL: float = 0.1
const PRESTIGE_STAGE_DIVISOR: int = 50

## === PUBLIC API ===

func get_gold() -> float:
	return _current_gold

func get_stars() -> int:
	return _current_stars

func get_upgrade_level() -> int:
	return _upgrade_level

func can_afford(cost: float) -> bool:
	return _current_gold >= cost

func add_gold(amount: float) -> void:
	if amount < 0.0:
		amount = 0.0
	var delta = amount
	_current_gold += amount
	if EventBus:
		EventBus.gold_changed.emit(_current_gold, delta)
	# ✅ Auto-save when gold changes
	if SaveCore:
		SaveCore.request_save()

func spend_gold(amount: float) -> bool:
	if not can_afford(amount):
		return false
	_current_gold -= amount
	EventBus.gold_changed.emit(_current_gold, -amount)
	# ✅ Auto-save when spending gold
	if SaveCore:
		SaveCore.request_save()
	return true

func add_stars(amount: int) -> void:
	if amount < 0:
		amount = 0
	_current_stars += amount
	EventBus.stars_changed.emit(_current_stars)
	# ✅ Auto-save when stars change
	if SaveCore:
		SaveCore.request_save()

## === Forge Cores ===

func get_forge_cores() -> int:
	return _current_forge_cores

func can_afford_forge_cores(cost: int) -> bool:
	if cost <= 0:
		return true
	return _current_forge_cores >= cost

func add_forge_cores(amount: int) -> void:
	if amount <= 0:
		return
	_current_forge_cores += amount
	if EventBus:
		EventBus.forge_cores_changed.emit(_current_forge_cores, amount)
	if SaveCore:
		SaveCore.request_save()

func spend_forge_cores(cost: int) -> bool:
	if cost <= 0:
		return true
	if _current_forge_cores < cost:
		return false
	_current_forge_cores -= cost
	if EventBus:
		EventBus.forge_cores_changed.emit(_current_forge_cores, -cost)
	if SaveCore:
		SaveCore.request_save()
	return true

## Upgrade Click Damage
func get_click_damage() -> float:
	var base = get_base_damage()
	var mult = get_upgrade_multiplier()
	var stars = get_stars()
	var skill_multiplier: float = 1.0
	if is_instance_valid(SkillCore):
		skill_multiplier = SkillCore.get_damage_multiplier()
	var click_bonus: float = 0.0
	if TownCore:
		click_bonus = TownCore.get_click_damage_bonus()
	
	return DamageCalculator.calculate_click_damage(base, mult, stars, skill_multiplier, click_bonus)

func get_upgrade_price() -> float:
	return UPGRADE_BASE_PRICE * pow(UPGRADE_SCALE_FACTOR, _upgrade_level)

func can_afford_upgrade() -> bool:
	return can_afford(get_upgrade_price())

func purchase_upgrade() -> bool:
	var price = get_upgrade_price()
	if spend_gold(price):
		_upgrade_level += 1
		# ✅ Auto-save when purchasing upgrade (spend_gold already saves, but just in case)
		if SaveCore:
			SaveCore.request_save()
		return true
	return false

func get_upgrade_multiplier() -> float:
	return 1.0 + (UPGRADE_DAMAGE_PER_LEVEL * _upgrade_level)

## Test Base Damage (for debug/testing)
func add_test_base_damage(amount: float) -> void:
	if amount < 0.0:
		amount = 0.0
	_test_base_damage_bonus += amount

func get_base_damage() -> float:
	return 1.0 + _test_base_damage_bonus

## Prestige
func prestige() -> void:
	_current_gold = 0.0
	_upgrade_level = 0
	EventBus.gold_changed.emit(_current_gold, 0)
	EventBus.prestige_triggered.emit()

func reset_progress() -> void:
	_current_gold = 0.0
	_current_stars = 0
	_upgrade_level = 0
	_current_forge_cores = 0
	if EventBus:
		EventBus.gold_changed.emit(_current_gold, 0.0)
		EventBus.stars_changed.emit(_current_stars)
		if EventBus.has_signal("forge_cores_changed"):
			EventBus.forge_cores_changed.emit(_current_forge_cores, 0)

## === SAVE/LOAD ===

func get_save_data() -> Dictionary:
	return {
		"gold": _current_gold,
		"stars": _current_stars,
		"upgrade_level": _upgrade_level,
		# test_base_damage_bonus is not saved - this is a debug/testing feature
		"forge_cores": _current_forge_cores
	}

func load_save_data(data: Dictionary) -> void:
	_current_gold = data.get("gold", 0.0)
	_current_stars = data.get("stars", 0)
	_upgrade_level = data.get("upgrade_level", 0)
	# test_base_damage_bonus is not loaded - this is a debug/testing feature and always resets
	_test_base_damage_bonus = 0.0
	_current_forge_cores = int(data.get("forge_cores", 0))
	
	# Emit updates after load
	EventBus.gold_changed.emit(_current_gold, 0)
	EventBus.stars_changed.emit(_current_stars)
	EventBus.forge_cores_changed.emit(_current_forge_cores, 0)
