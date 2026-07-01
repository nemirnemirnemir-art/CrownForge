extends RefCounted
class_name MapSlotMarket

## Market trading logic helper for MapSlot
## Handles resource-to-gold conversion timing and completion

signal trade_completed(resource_id: String, gold_amount: int)

var _active_resource: String = ""
var _is_trading: bool = false
var _trade_timer: float = 0.0

const CYCLE_TIME: float = 1.0
const TRADE_RATES := {
	"wheat": {"id": "gold", "amount": 1},
	"iron_ore": {"id": "gold", "amount": 1},
	"flour": {"id": "gold", "amount": 3},
	"steel": {"id": "gold", "amount": 3}
}

const EXTENDED_TRADE_RATES := {
	"clay": {"id": "gold", "amount": 1},
	"grapes": {"id": "gold", "amount": 1},
	"crystal": {"id": "gold", "amount": 1},
}

func _get_autoload(name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(name)

func set_active_resource(resource_id: String) -> void:
	_active_resource = resource_id
	_is_trading = false
	_trade_timer = 0.0

func get_active_resource() -> String:
	return _active_resource

func tick(delta: float) -> Dictionary:
	## Returns: {"progress_ratio": float, "is_trading": bool, "completed": bool}
	
	if _active_resource == "":
		return {"progress_ratio": 0.0, "is_trading": false, "completed": false}
	
	if not _is_trading:
		# Check if we have what we need to sell
		var resource_core := _get_autoload("ResourceCore")
		if resource_core and int(resource_core.call("get_resource", _active_resource)) >= 1:
			resource_core.call("consume_resource", _active_resource, 1)
			_is_trading = true
			_trade_timer = 0.0
	
	if _is_trading:
		var cycle := _get_effective_cycle_time()
		_trade_timer += delta
		var progress_ratio = max(0.0, (cycle - _trade_timer) / cycle)
		
		if _trade_timer >= cycle:
			_complete_trade()
			_is_trading = false
			_trade_timer = 0.0
			return {"progress_ratio": 0.0, "is_trading": false, "completed": true}
		
		return {"progress_ratio": progress_ratio, "is_trading": true, "completed": false}
	
	return {"progress_ratio": 0.0, "is_trading": false, "completed": false}

func _complete_trade() -> void:
	if not has_trade_rate(_active_resource):
		return

	var rate := get_trade_rate(_active_resource)
	if int(rate.amount) <= 0:
		return
	if String(rate.id) == "gold":
		var economy_core := _get_autoload("EconomyCore")
		if economy_core and economy_core.has_method("add_gold"):
			economy_core.call("add_gold", float(rate.amount))
			trade_completed.emit(String(rate.id), int(rate.amount))
		return
	var resource_core := _get_autoload("ResourceCore")
	if resource_core:
		resource_core.call("add_resource", String(rate.id), int(rate.amount))
		trade_completed.emit(String(rate.id), int(rate.amount))

func reset() -> void:
	_active_resource = ""
	_is_trading = false
	_trade_timer = 0.0

func has_trade_rate(resource_id: String) -> bool:
	return not get_trade_rate(resource_id).is_empty()

func get_trade_rate(resource_id: String) -> Dictionary:
	var normalized_id := String(resource_id).strip_edges().to_lower()
	if TRADE_RATES.has(normalized_id):
		return (TRADE_RATES[normalized_id] as Dictionary).duplicate()
	if _has_extended_market_trades() and EXTENDED_TRADE_RATES.has(normalized_id):
		return (EXTENDED_TRADE_RATES[normalized_id] as Dictionary).duplicate()
	return {}

func _get_effective_cycle_time() -> float:
	var speed_mult := 1.0
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var artifact_core := tree.root.get_node_or_null("ArtifactCore")
		if artifact_core != null and artifact_core.has_method("get_resource_production_speed_multiplier"):
			speed_mult *= float(artifact_core.call("get_resource_production_speed_multiplier"))
	var morale_system := _get_autoload("MoraleSystem")
	if morale_system:
		speed_mult *= (1.0 + float(morale_system.call("get_productivity_modifier")))
	var king_spell_state := _get_autoload("KingSpellState")
	if king_spell_state:
		speed_mult *= (1.0 + float(king_spell_state.call("get_productivity_bonus_multiplier")))
	if speed_mult <= 0.0:
		speed_mult = 0.0001
	return max(0.01, CYCLE_TIME / speed_mult)

func _has_extended_market_trades() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	var artifact_core := tree.root.get_node_or_null("ArtifactCore")
	if artifact_core == null or not artifact_core.has_method("has_extended_market_trades"):
		return false
	return bool(artifact_core.call("has_extended_market_trades"))
