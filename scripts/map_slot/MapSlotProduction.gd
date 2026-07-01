extends RefCounted
class_name MapSlotProduction

## Production logic helper for MapSlot
## Handles resource/unit production timing, consumption, and completion

const PopulationBattlefieldQueryScript := preload("res://core/population/PopulationBattlefieldQuery.gd")
const BuildingUpgradeCostModifierScript := preload("res://core/building_upgrade/BuildingUpgradeCostModifier.gd")
const ArtifactWorkingBuildingFlowScript := preload("res://core/artifacts/ArtifactWorkingBuildingFlow.gd")
const ArtifactBuildingLifecycleBonusesScript := preload("res://core/artifacts/ArtifactBuildingLifecycleBonuses.gd")
const POSITION_BUCKET_TOLERANCE := 4.0

signal production_completed(outputs: Array)
signal hero_produced(hero_id: String)

var _is_producing: bool = false
var _production_timer: float = 0.0
var _current_cycle: float = 1.0
var _remaining_durability: int = -1
var _current_seal_modifier: float = 0.0
var _slot_index: int = -1
var _building_id: String = ""
var _battlefield_query: RefCounted = PopulationBattlefieldQueryScript.new()
var _artifact_working_building_flow: RefCounted = ArtifactWorkingBuildingFlowScript.new()
var _artifact_building_lifecycle_bonuses: RefCounted = ArtifactBuildingLifecycleBonusesScript.new()

# Unit tracking for military buildings
var _produced_hero_ids: Array[String] = []

func _get_autoload(name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(name)

func initialize(cycle_time: float, durability: int = -1, slot_index: int = -1, building_id: String = "") -> void:
	_current_cycle = cycle_time
	_remaining_durability = durability
	_slot_index = slot_index
	_building_id = String(building_id).strip_edges().to_lower()
	_is_producing = false
	_production_timer = 0.0
	_produced_hero_ids.clear()
	_current_seal_modifier = 0.0

func set_seal_modifier(mod: float) -> void:
	_current_seal_modifier = mod

func tick(delta: float, building_id: String, config: BuildingConfig = null) -> Dictionary:
	## Main tick function - returns progress info
	## Returns: {"progress_ratio": float, "is_producing": bool, "completed": bool}
	_building_id = String(building_id).strip_edges().to_lower()
	
	if config:
		return _tick_new(delta, config)
	
	return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0}

func _tick_new(delta: float, config: BuildingConfig) -> Dictionary:
	## Production using BuildingConfig system
	_sync_produced_heroes()

	var speed_mult := 1.0
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var artifact_core := tree.root.get_node_or_null("ArtifactCore")
		if artifact_core != null:
			if config.building_type == BuildingConfig.BuildingType.RESOURCE and artifact_core.has_method("get_resource_production_speed_multiplier"):
				speed_mult = float(artifact_core.call("get_resource_production_speed_multiplier"))
			elif config.building_type == BuildingConfig.BuildingType.MILITARY and artifact_core.has_method("get_unit_production_speed_multiplier"):
				speed_mult = float(artifact_core.call("get_unit_production_speed_multiplier"))
	
	# Apply SEAL MODIFIER
	speed_mult *= (1.0 + _current_seal_modifier)

	# Apply MORALE MODIFIER (building productivity)
	var morale_system := _get_autoload("MoraleSystem")
	if morale_system:
		speed_mult *= (1.0 + float(morale_system.call("get_productivity_modifier")))
	var king_spell_state := _get_autoload("KingSpellState")
	if king_spell_state:
		speed_mult *= (1.0 + float(king_spell_state.call("get_productivity_bonus_multiplier")))
	var building_upgrade_core := _get_autoload("BuildingUpgradeCore")
	if building_upgrade_core != null and building_upgrade_core.has_method("get_concert_slot_production_speed_multiplier"):
		speed_mult *= float(building_upgrade_core.call("get_concert_slot_production_speed_multiplier", _slot_index))
	# Building upgrade production speed boost (vineyard:1, market:1, sawmill:0, etc.)
	if building_upgrade_core != null and building_upgrade_core.has_method("get_production_speed_multiplier"):
		speed_mult *= float(building_upgrade_core.call("get_production_speed_multiplier", _building_id))
	if building_upgrade_core != null and building_upgrade_core.has_method("get_neighbour_boost_multiplier"):
		speed_mult *= _get_neighbour_boost_multiplier(building_upgrade_core)

	if speed_mult <= 0.0:
		speed_mult = 0.0001
	var cycle := config.cycle_time / speed_mult
	
	# Check military building limits
	if config.building_type == BuildingConfig.BuildingType.MILITARY:
		var max_units_limit := int(config.max_units)
		var artifact_core := _get_autoload("ArtifactCore")
		if artifact_core != null and artifact_core.has_method("get_military_building_unit_limit"):
			max_units_limit = int(artifact_core.call("get_military_building_unit_limit", config, max_units_limit))
		elif _artifact_building_lifecycle_bonuses != null and _artifact_building_lifecycle_bonuses.has_method("get_military_building_unit_limit"):
			var active_artifacts := _get_active_artifacts()
			max_units_limit = int(_artifact_building_lifecycle_bonuses.call("get_military_building_unit_limit", active_artifacts, config, max_units_limit))
		var capacity_bonus := 0
		if building_upgrade_core != null and building_upgrade_core.has_method("get_capacity_bonus"):
			capacity_bonus = int(building_upgrade_core.call("get_capacity_bonus", _building_id))
		if _produced_hero_ids.size() >= max_units_limit + capacity_bonus:
			_is_producing = false
			return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": cycle}
		
		# Unit limit applies to battlefield only. In Barracks/ToCapacity, allow producing reserves.
		var mode := 1
		var hero_core := _get_autoload("HeroCore")
		if hero_core and hero_core.has_method("get_troop_spawn_mode"):
			mode = int(hero_core.call("get_troop_spawn_mode"))
		var population_core := _get_autoload("PopulationCore")
		if population_core and hero_core and mode == int(hero_core.get("TROOP_SPAWN_MODE_BATTLEFIELD")):
			if not _battlefield_query.has_field_capacity(hero_core, population_core):
				_is_producing = false
				return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": cycle}
	
	# Special buildings don't auto-produce
	if config.building_type == BuildingConfig.BuildingType.SPECIAL:
		return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": cycle}
	
	if not _is_producing:
		# Check if we can start production
		if config.consumes.size() > 0:
			# Efficient processing: forge:0/mill:0 double input+output
			var ep_core := _get_autoload("BuildingUpgradeCore")
			var ep_extra := 0
			if ep_core != null and ep_core.has_method("get_efficient_processing_multiplier"):
				ep_extra = int(ep_core.call("get_efficient_processing_multiplier", _building_id)) - 1
			# Cost discount for "cheaper production" upgrades
			var cost_mult := 1.0
			if ep_core != null and ep_core.has_method("get_cost_multiplier"):
				cost_mult = float(ep_core.call("get_cost_multiplier", _building_id))
			# Lion circus versatility: +100% production cost (stacks multiplicatively)
			if _building_id == "lion_circus" and ep_core != null and ep_core.has_method("get_lion_circus_cost_multiplier"):
				cost_mult *= float(ep_core.call("get_lion_circus_cost_multiplier"))
			var resource_core := _get_autoload("ResourceCore")
			var use_cost_modifier := not is_equal_approx(cost_mult, 1.0) and resource_core != null
			var can_start := false
			if use_cost_modifier:
				can_start = BuildingUpgradeCostModifierScript.can_produce_discounted(config.consumes, cost_mult, resource_core)
			else:
				can_start = config.can_produce()
			if can_start:
				if use_cost_modifier:
					BuildingUpgradeCostModifierScript.consume_inputs_discounted(config.consumes, cost_mult, resource_core)
				else:
					config.consume_inputs()
				# Extra consumption for efficient processing (best-effort)
				for _extra_consume in range(ep_extra):
					if use_cost_modifier:
						if BuildingUpgradeCostModifierScript.can_produce_discounted(config.consumes, cost_mult, resource_core):
							BuildingUpgradeCostModifierScript.consume_inputs_discounted(config.consumes, cost_mult, resource_core)
					else:
						if config.can_produce():
							config.consume_inputs()
				_is_producing = true
				_production_timer = 0.0
		else:
			# No input required - always producing
			_is_producing = true
	
	if _is_producing:
		_production_timer += delta
		_process_artifact_working_tick(delta)
		var progress_ratio = 1.0 if cycle <= 0 else max(0.0, (cycle - _production_timer) / cycle)
		
		if _production_timer >= cycle:
			_complete_production_new(config)
			_is_producing = false
			_production_timer = 0.0
			return {"progress_ratio": 0.0, "is_producing": false, "completed": true, "cycle_time": cycle}
		
		return {"progress_ratio": progress_ratio, "is_producing": true, "completed": false, "cycle_time": cycle}
	
	return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": cycle}


func _process_artifact_working_tick(delta: float) -> void:
	if delta <= 0.0:
		return
	var artifact_core := _get_autoload("ArtifactCore")
	if artifact_core != null and artifact_core.has_method("on_working_building_tick"):
		artifact_core.call("on_working_building_tick", delta, _building_id, _slot_index)
		return
	if _artifact_working_building_flow == null:
		return
	if _artifact_working_building_flow.has_method("process_working_tick"):
		_artifact_working_building_flow.call("process_working_tick", delta, _building_id, _slot_index)

func _complete_production_new(config: BuildingConfig) -> void:
	if config.building_type == BuildingConfig.BuildingType.RESOURCE:
		config.produce_outputs()
		# Efficient processing: produce extra outputs for forge:0/mill:0
		var ep_upgrade_core := _get_autoload("BuildingUpgradeCore")
		var ep_mult := 1
		if ep_upgrade_core != null and ep_upgrade_core.has_method("get_efficient_processing_multiplier"):
			ep_mult = int(ep_upgrade_core.call("get_efficient_processing_multiplier", _building_id))
		if ep_mult > 1:
			for _extra_i in range(ep_mult - 1):
				config.produce_outputs()
		# Emit outputs for animation (adjusted for efficient processing)
		var outputs: Array = []
		for prod in config.produces:
			outputs.append({"resource_id": prod.resource_id, "amount": prod.amount * ep_mult})
		production_completed.emit(outputs)
		var artifact_core := _get_autoload("ArtifactCore")
		if artifact_core != null and artifact_core.has_method("on_resource_production_completed"):
			artifact_core.call("on_resource_production_completed", _building_id, outputs, ep_mult)
		# Bonus resource rolls on cycle completion (gold_mine:0, wheat_field:1, etc.)
		if ep_upgrade_core != null and ep_upgrade_core.has_method("process_production_bonuses"):
			var resource_core_node := _get_autoload("ResourceCore")
			var castle_core_node := _get_autoload("CastleCore")
			var add_res_func := func(res_id: String, amount: int) -> void:
				if resource_core_node and resource_core_node.has_method("add_resource"):
					resource_core_node.call("add_resource", res_id, amount)
			var repair_func := func(amount: int) -> void:
				if castle_core_node and castle_core_node.has_method("heal"):
					castle_core_node.call("heal", amount)
			var _bonus_results: Array[Dictionary] = ep_upgrade_core.call("process_production_bonuses", _building_id, add_res_func, repair_func)
	
	elif config.building_type == BuildingConfig.BuildingType.MILITARY:
		var hero_core := _get_autoload("HeroCore")
		if config.produced_unit_id != "" and hero_core:
			# Mega militia: resolve whether to swap unit_id
			var actual_unit_id: String = config.produced_unit_id
			var upgrade_core := _get_autoload("BuildingUpgradeCore")
			if upgrade_core != null and upgrade_core.has_method("resolve_mega_militia_unit"):
				actual_unit_id = String(upgrade_core.call("resolve_mega_militia_unit", _building_id, config.produced_unit_id))
			_ensure_produced_unit_template(actual_unit_id)
			if not hero_core.hero_created.is_connected(_on_hero_hired):
				hero_core.hero_created.connect(_on_hero_hired)
			
			var new_id: String = String(hero_core.call("hire_hero_copy", actual_unit_id))
			if new_id != "":
				hero_core.call("update_hero", new_id, {
					"produced_by_building_id": config.building_id,
					"produced_by_building_type": int(config.building_type),
					"produced_by_slot_index": _slot_index
				})
				# Spawn mode handling
				var mode: int = int(hero_core.call("get_troop_spawn_mode")) if hero_core.has_method("get_troop_spawn_mode") else 1
				var population_core := _get_autoload("PopulationCore")
				var battlefield_has_space: bool = _battlefield_query.has_field_capacity(hero_core, population_core)
				var should_deploy := false
				if int(mode) == int(hero_core.get("TROOP_SPAWN_MODE_BATTLEFIELD")):
					should_deploy = battlefield_has_space
				elif int(mode) == int(hero_core.get("TROOP_SPAWN_MODE_BARRACKS")):
					should_deploy = false
				elif int(mode) == int(hero_core.get("TROOP_SPAWN_MODE_TO_CAPACITY")):
					should_deploy = battlefield_has_space
				if should_deploy:
					hero_core.call("add_to_squad", new_id)
				# Post-production events: giants_bedding resource grants, ram twins extra unit
				_process_military_production_event(config, hero_core, actual_unit_id)
			
			if hero_core.hero_created.is_connected(_on_hero_hired):
				hero_core.hero_created.disconnect(_on_hero_hired)
	
	# Handle durability
	if _remaining_durability > 0:
		_remaining_durability -= 1

func _process_military_production_event(config: BuildingConfig, hero_core: Node, produced_unit_id: String) -> void:
	## Post-production event hook: giants_bedding resource grants, ram twins extra unit.
	var upgrade_core := _get_autoload("BuildingUpgradeCore")
	if upgrade_core == null or not upgrade_core.has_method("process_military_production_event"):
		return
	var resource_core := _get_autoload("ResourceCore")
	var add_res_func := func(res_id: String, amount: int) -> void:
		if resource_core and resource_core.has_method("add_resource"):
			resource_core.call("add_resource", res_id, amount)
	var hire_extra_func := func(unit_id: String) -> String:
		if hero_core == null:
			return ""
		_ensure_produced_unit_template(unit_id)
		var extra_id: String = String(hero_core.call("hire_hero_copy", unit_id))
		if extra_id != "":
			hero_core.call("update_hero", extra_id, {
				"produced_by_building_id": config.building_id,
				"produced_by_building_type": int(config.building_type),
				"produced_by_slot_index": _slot_index
			})
		return extra_id
	var _events: Array[Dictionary] = upgrade_core.call(
		"process_military_production_event",
		String(config.building_id).strip_edges().to_lower(),
		produced_unit_id,
		add_res_func,
		hire_extra_func
	)

func _ensure_produced_unit_template(base_unit_id: String) -> void:
	var hero_core := _get_autoload("HeroCore")
	if hero_core == null:
		return

	var base_id := String(base_unit_id).strip_edges().to_lower()
	if base_id == "":
		return

	var hero_query: Variant = hero_core.get("query")
	if hero_query and hero_query.has_method("has_hero") and bool(hero_query.call("has_hero", base_id)):
		return

	var display_name := base_id.capitalize()
	if hero_core.has_method("ensure_hero_template"):
		hero_core.call("ensure_hero_template", base_id, display_name)
		return

	if hero_core.has_method("create_hero"):
		hero_core.call("create_hero", base_id, display_name, base_id, 0.0)

func _on_hero_hired(hero_id: String, _data: Dictionary) -> void:
	_produced_hero_ids.append(hero_id)
	hero_produced.emit(hero_id)
	var artifact_core := _get_autoload("ArtifactCore")
	if artifact_core != null and artifact_core.has_method("on_unit_created"):
		artifact_core.call("on_unit_created")

func on_hero_died(hero_id: String) -> void:
	if _produced_hero_ids.has(hero_id):
		_produced_hero_ids.erase(hero_id)

func _sync_produced_heroes() -> void:
	var hero_core := _get_autoload("HeroCore")
	if hero_core == null:
		return
	if _slot_index >= 0 and _building_id != "":
		var rebuilt_ids: Array[String] = []
		for hero_value in hero_core.get("heroes").values():
			if not (hero_value is Dictionary):
				continue
			var hero_data := hero_value as Dictionary
			if bool(hero_data.get("isDead", false)):
				continue
			if String(hero_data.get("produced_by_building_id", "")).to_lower() != _building_id:
				continue
			if int(hero_data.get("produced_by_slot_index", -1)) != _slot_index:
				continue
			var hero_id := String(hero_data.get("id", ""))
			if hero_id == "":
				continue
			rebuilt_ids.append(hero_id)
		_produced_hero_ids = rebuilt_ids
		return
	if _produced_hero_ids.is_empty():
		return
	for i in range(_produced_hero_ids.size() - 1, -1, -1):
		var hero_id := _produced_hero_ids[i]
		var heroes: Dictionary = hero_core.get("heroes")
		if not heroes.has(hero_id):
			_produced_hero_ids.remove_at(i)
			continue
		var hero_data: Variant = heroes.get(hero_id, {})
		if hero_data is Dictionary and bool((hero_data as Dictionary).get("isDead", false)):
			_produced_hero_ids.remove_at(i)

func get_unit_count() -> int:
	return _produced_hero_ids.size()

func get_durability() -> int:
	return _remaining_durability

func is_producing() -> bool:
	return _is_producing

func recover_runtime_state(config: BuildingConfig) -> Dictionary:
	if config == null:
		return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0}
	_production_timer = maxf(0.0, _production_timer)
	return _tick_new(0.0, config)

func export_runtime_state() -> Dictionary:
	_sync_produced_heroes()
	return {
		"is_producing": _is_producing,
		"production_timer": _production_timer,
		"current_cycle": _current_cycle,
		"remaining_durability": _remaining_durability,
		"current_seal_modifier": _current_seal_modifier,
		"produced_hero_ids": _produced_hero_ids.duplicate(),
	}

func import_runtime_state(state: Dictionary, new_slot_index: int, building_id: String) -> void:
	_slot_index = new_slot_index
	_building_id = String(building_id).strip_edges().to_lower()
	_is_producing = bool(state.get("is_producing", _is_producing))
	_production_timer = float(state.get("production_timer", _production_timer))
	_current_cycle = float(state.get("current_cycle", _current_cycle))
	_remaining_durability = int(state.get("remaining_durability", _remaining_durability))
	_current_seal_modifier = float(state.get("current_seal_modifier", _current_seal_modifier))
	var produced_ids: Variant = state.get("produced_hero_ids", [])
	if produced_ids is Array:
		_produced_hero_ids = []
		for hero_id in produced_ids:
			_produced_hero_ids.append(String(hero_id))
	_transfer_hero_ownership(new_slot_index, _building_id)
	_sync_produced_heroes()

func _transfer_hero_ownership(new_slot_index: int, building_id: String) -> void:
	var hero_core := _get_autoload("HeroCore")
	if hero_core == null:
		return
	for hero_id in _produced_hero_ids:
		if not hero_core.has_method("get_hero") or not hero_core.has_method("update_hero"):
			break
		var hero_data: Variant = hero_core.call("get_hero", hero_id)
		if not (hero_data is Dictionary):
			continue
		var hero := hero_data as Dictionary
		if hero.is_empty() or bool(hero.get("isDead", false)):
			continue
		hero_core.call("update_hero", hero_id, {
			"produced_by_building_id": building_id,
			"produced_by_slot_index": new_slot_index,
		})

func reset() -> void:
	_is_producing = false
	_production_timer = 0.0
	_building_id = ""
	_produced_hero_ids.clear()


func _get_neighbour_boost_multiplier(building_upgrade_core: Node) -> float:
	var slot_context := _build_slot_grid_context()
	if slot_context.is_empty():
		return 1.0
	return float(building_upgrade_core.call(
		"get_neighbour_boost_multiplier",
		slot_context.get("slot_grid_pos", Vector2i.ZERO),
		slot_context.get("all_slots_by_grid_pos", {})
	))


func _build_slot_grid_context() -> Dictionary:
	if _slot_index < 0:
		return {}
	var map_layout := _get_map_layout()
	if map_layout == null:
		return {}
	var raw_slots: Variant = map_layout.get("slots")
	if not (raw_slots is Array):
		return {}

	var slots: Array = raw_slots
	var unique_x: Array[float] = []
	var unique_y: Array[float] = []
	var slot_buckets: Array[Dictionary] = []
	var target_slot: Node2D = null

	for slot_value in slots:
		var slot := slot_value as Node2D
		if slot == null:
			continue
		var bucket_x := _bucket_position(slot.position.x)
		var bucket_y := _bucket_position(slot.position.y)
		_append_unique_bucket(unique_x, bucket_x)
		_append_unique_bucket(unique_y, bucket_y)
		slot_buckets.append({
			"slot": slot,
			"bucket_x": bucket_x,
			"bucket_y": bucket_y,
		})
		var raw_slot_index: Variant = slot.get("slot_index")
		if raw_slot_index != null and int(raw_slot_index) == _slot_index:
			target_slot = slot

	if target_slot == null:
		return {}

	unique_x.sort()
	unique_y.sort()

	var all_slots_by_grid_pos: Dictionary = {}
	var slot_grid_pos := Vector2i(-1, -1)
	for slot_entry: Dictionary in slot_buckets:
		var slot := slot_entry.get("slot", null) as Node2D
		if slot == null:
			continue
		var column_index := unique_x.find(float(slot_entry.get("bucket_x", 0.0)))
		var row_index := unique_y.find(float(slot_entry.get("bucket_y", 0.0)))
		if column_index < 0 or row_index < 0:
			continue
		var grid_pos := Vector2i(column_index, row_index)
		var raw_building_id: Variant = slot.get("current_building_id")
		all_slots_by_grid_pos[grid_pos] = {
			"building_id": String(raw_building_id if raw_building_id != null else "").strip_edges().to_lower(),
			"is_vzor_active": _is_slot_effectively_vzor_active(slot),
		}
		if slot == target_slot:
			slot_grid_pos = grid_pos

	if slot_grid_pos.x < 0 or slot_grid_pos.y < 0:
		return {}
	return {
		"slot_grid_pos": slot_grid_pos,
		"all_slots_by_grid_pos": all_slots_by_grid_pos,
	}


func _get_map_layout() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var game_scene := tree.get_first_node_in_group("game_scene")
	if game_scene == null:
		game_scene = tree.current_scene
	if game_scene == null:
		return null
	var raw_map_layout: Node = game_scene.get("map_layout_node")
	if raw_map_layout != null:
		return raw_map_layout
	return game_scene.get_node_or_null("WorldYSort/MapContainer/MapLayout")


func _get_active_artifacts() -> Dictionary:
	var artifact_core := _get_autoload("ArtifactCore")
	if artifact_core == null or not artifact_core.has_method("get_active_ids"):
		return {}
	var active: Dictionary = {}
	for artifact_id in artifact_core.call("get_active_ids"):
		active[String(artifact_id)] = true
	return active


func _is_slot_effectively_vzor_active(slot: Node) -> bool:
	if slot.has_method("is_effectively_vzor_active"):
		return bool(slot.call("is_effectively_vzor_active"))
	return false


func _append_unique_bucket(values: Array[float], bucket: float) -> void:
	for existing in values:
		if is_equal_approx(existing, bucket):
			return
	values.append(bucket)


func _bucket_position(value: float) -> float:
	return snappedf(value, POSITION_BUCKET_TOLERANCE)
