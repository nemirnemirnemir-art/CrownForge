extends SceneTree

const BoostScript := preload("res://core/building_upgrade/BuildingUpgradeProductionBoost.gd")
const BonusScript := preload("res://core/building_upgrade/BuildingUpgradeProductionBonus.gd")
const BridgeScript := preload("res://core/artifacts/ArtifactExternalMultiplierBridge.gd")

var _failed: bool = false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_building_upgrade_system_hooks] %s" % message)
	quit(1)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	# --- Test 1: PRODUCTION_BOOST_MAP has 12 entries ---
	var boost_map_size := BoostScript.PRODUCTION_BOOST_MAP.size()
	if boost_map_size != 12:
		_fail("PRODUCTION_BOOST_MAP expected 12, got %d" % boost_map_size)
		return

	# --- Test 2: BONUS_MAP has 6 entries ---
	var bonus_map_size := BonusScript.BONUS_MAP.size()
	if bonus_map_size != 6:
		_fail("BONUS_MAP expected 6, got %d" % bonus_map_size)
		return

	# --- Test 3: EFFICIENT_PROCESSING_MAP has 2 entries ---
	var ep_map_size := BoostScript.EFFICIENT_PROCESSING_MAP.size()
	if ep_map_size != 2:
		_fail("EFFICIENT_PROCESSING_MAP expected 2, got %d" % ep_map_size)
		return

	# --- Test 4: BuildingUpgradeCore autoload has new morale/spell methods ---
	var core: Node = get_root().get_node_or_null("BuildingUpgradeCore")
	if core == null:
		_fail("BuildingUpgradeCore autoload not found")
		return
	var required_methods: Array[String] = [
		"get_vineyard_passive_morale_bonus",
		"get_market_active_morale_bonus",
		"get_tavern_morale_bonus",
		"get_crystal_mine_spell_damage_multiplier",
		"get_production_speed_multiplier",
		"process_production_bonuses",
		"get_neighbour_boost_multiplier",
		"get_efficient_processing_multiplier",
		"get_troop_inspiration_damage_multiplier",
		"get_troop_inspiration_hp_multiplier",
	]
	for method_name: String in required_methods:
		if not core.has_method(method_name):
			_fail("BuildingUpgradeCore missing method: %s" % method_name)
			return

	# --- Test 5: Production boost returns 1.0 for unknown building ---
	var no_upgrade := func(_bid: String, _uid: String) -> bool: return false
	var mult := BoostScript.get_production_multiplier("unknown_building", no_upgrade)
	if absf(mult - 1.0) > 0.001:
		_fail("expected 1.0 for unknown building, got %f" % mult)
		return

	# --- Test 6: Efficient processing returns 1 by default ---
	var ep := BoostScript.get_efficient_processing_multiplier("forge", no_upgrade)
	if ep != 1:
		_fail("expected ep=1 for forge without upgrade, got %d" % ep)
		return

	# --- Test 7: Efficient processing returns 2 when upgrade active ---
	var has_forge := func(_bid: String, _uid: String) -> bool: return true
	var ep2 := BoostScript.get_efficient_processing_multiplier("forge", has_forge)
	if ep2 != 2:
		_fail("expected ep=2 for forge with upgrade, got %d" % ep2)
		return

	# --- Test 8: ArtifactExternalMultiplierBridge has spell damage bridge ---
	var bridge := BridgeScript.new()
	if not bridge.has_method("apply_spell_damage_bridge"):
		_fail("BridgeScript missing apply_spell_damage_bridge")
		return

	# --- Test 9: Crystal mine spell damage defaults to 1.0 without upgrade ---
	var crystal_mult := float(core.call("get_crystal_mine_spell_damage_multiplier"))
	if absf(crystal_mult - 1.0) > 0.001:
		_fail("crystal_mine spell damage expected 1.0 without upgrade, got %f" % crystal_mult)
		return

	# --- Test 10: Morale methods return 0 without upgrades ---
	var vineyard_morale := int(core.call("get_vineyard_passive_morale_bonus"))
	if vineyard_morale != 0:
		_fail("vineyard morale expected 0 without upgrade, got %d" % vineyard_morale)
		return
	var market_morale := int(core.call("get_market_active_morale_bonus"))
	if market_morale != 0:
		_fail("market morale expected 0 without upgrade, got %d" % market_morale)
		return
	var tavern_morale := int(core.call("get_tavern_morale_bonus"))
	if tavern_morale != 0:
		_fail("tavern morale expected 0 without upgrade, got %d" % tavern_morale)
		return

	print("[test_building_upgrade_system_hooks] PASS (10 checks)")
	quit(0)
