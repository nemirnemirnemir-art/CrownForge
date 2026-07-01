## Manages the battle phase: spawns units from both boards, runs combat, detects winner.
extends Node2D

const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")
const UnitScript = preload("res://scripts/dev/ten_kings/TenKingsUnit.gd")
const AttackEffectScript = preload("res://scripts/dev/ten_kings/TenKingsAttackEffect.gd")
const ProjectileEffectScene = preload("res://scenes/dev/ten_kings/effects/TenKingsProjectileEffect.tscn")
const CastleImpactScene = preload("res://scenes/dev/ten_kings/effects/TenKingsCastleImpact.tscn")
const CrowdBuilderScript = preload("res://scripts/dev/ten_kings/TenKingsCrowdBuilder.gd")
const CrowdRuntimeScript = preload("res://scripts/dev/ten_kings/TenKingsCrowdRuntime.gd")
const CrowdRendererScript = preload("res://scripts/dev/ten_kings/TenKingsCrowdRenderer.gd")
const BattleDebugScript = preload("res://scripts/dev/ten_kings/TenKingsBattleDebug.gd")


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal battle_started
signal battle_ended(winner_side: int)


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const _ARENA_HALF_WIDTH: float = 350.0
const _ARENA_HEIGHT: float = 400.0
const _MELEE_X: float = 350.0
const _RANGED_X: float = 300.0
const _BUILDING_X: float = 250.0
const _DEPLOY_DURATION: float = 0.55
const _CROWD_DEPLOY_DURATION: float = 3.0
const _CHASE_DURATION: float = 2.0
const _PROXIMITY_THRESHOLD: float = 45.0
const _SIEGE_CONTACT_DISTANCE: float = 28.0

## Cards that are NOT spawned as battle units (support / non-combat).
const _NON_COMBAT_CARDS: Array[StringName] = [
	&"farm", &"blacksmith", &"wildcard", &"steel_coat",
]


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _player_units: Array = []
var _ai_units: Array = []
var _is_active: bool = false
var _battle_container: Node2D = null
var _deploy_tween: Tween = null
var _chase_phase: bool = false
var _chase_timer: float = 0.0
var _winner_side: int = -1
var _effect_container: Node2D = null
var _field_result_locked: bool = false
var _losing_castle: Node2D = null  # DEPRECATED: kept for compatibility, always null now
var _arena_anchors: Dictionary = {}
var _arena_geometry: RefCounted = null
## Fixed structures that attack from board positions (Castle, Scout Tower).
## Each entry: {card_id: StringName, position: Vector2, level: int, attack_dmg: float, attack_cd: float, attack_range: float, cooldown_timer: float, side: int}
var _player_fixed_structures: Array = []
var _ai_fixed_structures: Array = []

## If true, use 1:1 crowd battle mode instead of stack-based actors.
var use_crowd_mode: bool = true
var _using_crowd_battle: bool = false
var _crowd_builder: RefCounted = null
var _crowd_runtime: Node = null
var _crowd_renderer: Node2D = null
var _crowd_deploy_tween: Tween = null
var _battle_debug: RefCounted = null

## Player castle fire mode: "auto" (default) or "manual".
## When "auto", castle auto-targets nearest valid enemy.
## When "manual", player must click to fire at ground position.
## AI castle is always automatic (no mode control).
var player_castle_fire_mode: String = "auto"

## Cooldown tracker for manual castle fire to prevent spam.
var _player_castle_manual_cooldown: float = 0.0

## Per-slot damage tracking: Dict[int, Dict[Vector2i, int]]
## Keyed by side (0=player, 1=ai), then by slot position, value is total damage.
var _slot_damage_totals: Dictionary = {
	0: {},  # Player side
	1: {}   # AI side
}


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns true if player castle is in automatic fire mode.
func is_player_castle_auto_fire() -> bool:
	return player_castle_fire_mode == "auto"


## Request a manual castle fire at a ground position.
## Only works if player_castle_fire_mode is "manual" and cooldown is ready.
## Returns true if the fire request was accepted.
func request_manual_castle_fire(target_pos: Vector2) -> bool:
	if player_castle_fire_mode != "manual":
		return false
	if not _is_active:
		return false
	if _player_castle_manual_cooldown > 0.0:
		return false
	
	# Find the player castle in fixed structures
	var castle_structure: Dictionary = {}
	for structure in _player_fixed_structures:
		if structure.get("card_id") == CardLib.CARD_CASTLE:
			castle_structure = structure
			break
	
	if castle_structure.is_empty():
		return false
	
	# Apply cooldown
	_player_castle_manual_cooldown = castle_structure.get("attack_cd", 1.0)
	
	# Fire at ground position (splash damage will be applied)
	_perform_castle_ground_fire(castle_structure, target_pos)
	return true


## Returns the remaining cooldown time for the player castle manual fire.
func get_player_castle_cooldown_remaining() -> float:
	return _player_castle_manual_cooldown


## Returns true if the player castle manual fire cooldown is ready (= 0).
func is_player_castle_cooldown_ready() -> bool:
	return _player_castle_manual_cooldown <= 0.0


## Get total damage dealt to a specific slot.
## side: 0 = player, 1 = ai
## slot_pos: The slot position (e.g., Vector2i(1, 1))
func get_slot_damage_total(side: int, slot_pos: Vector2i) -> int:
	if not _slot_damage_totals.has(side):
		return 0
	var side_totals = _slot_damage_totals[side]
	if not side_totals.has(slot_pos):
		return 0
	return side_totals[slot_pos]


## Record damage for a slot (internal method called during battle).
func _record_slot_damage(side: int, slot_pos: Vector2i, damage: int) -> void:
	if not _slot_damage_totals.has(side):
		_slot_damage_totals[side] = {}
	if not _slot_damage_totals[side].has(slot_pos):
		_slot_damage_totals[side][slot_pos] = 0
	_slot_damage_totals[side][slot_pos] += damage


## Clear all damage totals (called at start of next battle).
func _clear_damage_totals() -> void:
	_slot_damage_totals[0].clear()
	_slot_damage_totals[1].clear()


func set_arena_anchors(anchors: Dictionary) -> void:
	_arena_anchors = anchors


func set_arena_geometry(geometry: RefCounted) -> void:
	_arena_geometry = geometry


func get_debug_helper() -> RefCounted:
	return _battle_debug


func get_formation_x_for_unit_type(side: int, is_ranged: bool, is_building: bool) -> float:
	# Use anchor positions if available, otherwise fall back to defaults
	var sign_x: float = -1.0 if side == 0 else 1.0

	if is_building:
		var key: String = "player_back" if side == 0 else "ai_back"
		var anchor: Variant = _arena_anchors.get(key)
		if anchor is Vector2:
			return anchor.x
		return sign_x * _BUILDING_X

	if is_ranged:
		var key: String = "player_ranged" if side == 0 else "ai_ranged"
		var anchor: Variant = _arena_anchors.get(key)
		if anchor is Vector2:
			return anchor.x
		return sign_x * _RANGED_X

	# Melee
	var key: String = "player_front" if side == 0 else "ai_front"
	var anchor: Variant = _arena_anchors.get(key)
	if anchor is Vector2:
		return anchor.x
	return sign_x * _MELEE_X


func get_castle_contact_position(side: int) -> Vector2:
	var key: String = "player_castle_contact" if side == 0 else "ai_castle_contact"
	var anchor: Variant = _arena_anchors.get(key)
	if anchor is Vector2:
		return anchor
	# Fallback: far left/right
	var sign_x: float = -1.0 if side == 0 else 1.0
	return Vector2(sign_x * _ARENA_HALF_WIDTH, 0)


func start_battle(player: RefCounted, ai_player: RefCounted, player_origins: Dictionary = {}, ai_origins: Dictionary = {}) -> void:
	print("[BattleManager] start_battle called, crowd_mode: ", use_crowd_mode)
	cleanup()
	_battle_debug = BattleDebugScript.new()
	_battle_debug.call("reset")
	var player_board: RefCounted = _get_player_board(player)
	var ai_board: RefCounted = _get_player_board(ai_player)
	if player_board == null or ai_board == null:
		print("[BattleManager] ERROR: player_board or ai_board is null")
		return

	# Reset steel-coat block availability before battle.
	player_board.call("reset_steel_coat_blocks")
	ai_board.call("reset_steel_coat_blocks")

	# Clear damage totals from previous battle
	_clear_damage_totals()

	_battle_container = Node2D.new()
	_battle_container.name = "BattleUnits"
	add_child(_battle_container)
	print("[BattleManager] Created BattleUnits container, parent: ", get_parent().name if get_parent() else "NO PARENT")
	_ensure_effect_container()

	if use_crowd_mode and _arena_geometry != null:
		_start_crowd_battle(player_board, ai_board, player_origins, ai_origins)
	else:
		_start_stack_battle(player, ai_player, player_origins, ai_origins)


## Start battle using new 1:1 crowd system.
func _start_crowd_battle(player_board: RefCounted, ai_board: RefCounted, player_origins: Dictionary = {}, ai_origins: Dictionary = {}) -> void:
	print("[BattleManager] Starting CROWD battle mode")
	_using_crowd_battle = true
	
	# Initialize crowd builder
	_crowd_builder = CrowdBuilderScript.new()
	_crowd_builder.reset_id_counter()
	
	# Expand stacks to soldiers and fixed structures
	var player_result: Dictionary = _crowd_builder.expand_stacks_to_soldiers(player_board, 0, _arena_geometry, player_origins)
	var enemy_result: Dictionary = _crowd_builder.expand_stacks_to_soldiers(ai_board, 1, _arena_geometry, ai_origins)
	
	var player_soldiers: Array = player_result.get("soldiers", [])
	var enemy_soldiers: Array = enemy_result.get("soldiers", [])
	_player_fixed_structures = player_result.get("fixed_structures", [])
	_ai_fixed_structures = enemy_result.get("fixed_structures", [])
	
	print("[BattleManager] Crowd battle: %d player soldiers, %d enemy soldiers" % [player_soldiers.size(), enemy_soldiers.size()])
	print("[BattleManager] Fixed structures: %d player, %d AI" % [_player_fixed_structures.size(), _ai_fixed_structures.size()])
	_emit_crowd_battle_start_summary(player_soldiers, enemy_soldiers)
	
	# Initialize crowd runtime
	_crowd_runtime = CrowdRuntimeScript.new()
	_crowd_runtime.name = "CrowdRuntime"
	_battle_container.add_child(_crowd_runtime)
	_crowd_runtime.call("set_debug_helper", _battle_debug)
	_crowd_runtime.setup(player_soldiers, enemy_soldiers)
	_crowd_runtime.battle_ended.connect(_on_crowd_battle_ended)
	_crowd_runtime.soldier_attack_performed.connect(_on_crowd_attack_performed)
	
	# Initialize crowd renderer
	_crowd_renderer = CrowdRendererScript.new()
	_crowd_renderer.name = "CrowdRenderer"
	_battle_container.add_child(_crowd_renderer)
	_crowd_renderer.setup(_crowd_runtime)
	
	_begin_crowd_deploy()


func _on_crowd_battle_ended(winner_team: int) -> void:
	print("[BattleManager] Crowd battle ended, winner_team: ", winner_team)
	_is_active = false
	_winner_side = winner_team
	battle_ended.emit(_winner_side)


func _on_crowd_attack_performed(attacker_id: int, target_id: int, damage: float) -> void:
	# Spawn attack effect for ranged units
	if _crowd_runtime == null:
		return
	
	var attacker: Dictionary = _crowd_runtime.get_soldier(attacker_id)
	var target: Dictionary = _crowd_runtime.get_soldier(target_id)
	
	if attacker.is_empty() or target.is_empty():
		return
	
	# Record damage for source slot
	if attacker.has("source_slot") and attacker.has("team"):
		_record_slot_damage(attacker["team"], attacker["source_slot"], int(damage))
	
	# Only spawn projectile effects for ranged units
	if attacker.get("is_ranged", false):
		var effect_parent := _ensure_effect_container()
		if effect_parent:
			var unit_type: StringName = attacker.get("unit_type", &"soldier")
			_spawn_projectile_effect(effect_parent, unit_type, attacker["position"], target["position"])



## Start battle using old stack-based actor system.
func _start_stack_battle(player: RefCounted, ai_player: RefCounted, player_origins: Dictionary, ai_origins: Dictionary) -> void:
	print("[BattleManager] Starting STACK battle mode (legacy)")
	_using_crowd_battle = false
	
	print("[BattleManager] Spawning player units...")
	_player_units = _spawn_units_for_side(player, 0, player_origins)
	print("[BattleManager] Player units spawned: ", _player_units.size())
	
	print("[BattleManager] Spawning AI units...")
	_ai_units = _spawn_units_for_side(ai_player, 1, ai_origins)
	print("[BattleManager] AI units spawned: ", _ai_units.size())
	
	print("[BattleManager] Fixed structures - player: ", _player_fixed_structures.size(), " ai: ", _ai_fixed_structures.size())

	var player_targets = _build_formation_targets(_player_units, 0)
	var ai_targets = _build_formation_targets(_ai_units, 1)
	_apply_fallback_spawn_positions(_player_units, player_targets, player_origins)
	_apply_fallback_spawn_positions(_ai_units, ai_targets, ai_origins)

	_is_active = false
	_chase_phase = false
	_chase_timer = 0.0
	_winner_side = -1
	_field_result_locked = false
	_losing_castle = null
	_using_crowd_battle = false
	print("[BattleManager] Calling _begin_deploy...")
	_begin_deploy(player_targets, ai_targets)


func cleanup() -> void:
	if _deploy_tween and is_instance_valid(_deploy_tween):
		_deploy_tween.kill()
		_deploy_tween = null
	
	# Cleanup crowd system
	if _crowd_renderer and is_instance_valid(_crowd_renderer):
		_crowd_renderer.cleanup()
		_crowd_renderer = null
	if _crowd_runtime and is_instance_valid(_crowd_runtime):
		_crowd_runtime.stop()
		_crowd_runtime = null
	_crowd_builder = null
	_battle_debug = null
	
	if _battle_container and is_instance_valid(_battle_container):
		_battle_container.queue_free()
		_battle_container = null
	_effect_container = null
	_player_units.clear()
	_ai_units.clear()
	_player_fixed_structures.clear()
	_ai_fixed_structures.clear()
	if _crowd_deploy_tween != null:
		_crowd_deploy_tween.kill()
		_crowd_deploy_tween = null
	_is_active = false
	_chase_phase = false
	_chase_timer = 0.0
	_winner_side = -1
	_field_result_locked = false
	_losing_castle = null


func get_surviving_units(side: int) -> Array:
	var source: Array = []
	if side == 0:
		source = _player_units
	else:
		source = _ai_units
	var alive: Array = []
	for u: Node2D in source:
		if u and is_instance_valid(u) and _unit_is_alive(u):
			alive.append(u)
	return alive


# ---------------------------------------------------------------------------
# Spawning
# ---------------------------------------------------------------------------

func _spawn_units_for_side(player: RefCounted, side: int, origin_map: Dictionary) -> Array:
	var units: Array = []
	var board: RefCounted = _get_player_board(player)
	if board == null:
		print("[BattleManager] ERROR: board is null for side ", side)
		return units
	var occupied: Array = board.call("get_occupied_slots")
	print("[BattleManager] Side ", side, " occupied slots: ", occupied)

	for pos: Vector2i in occupied:
		var slot_data: RefCounted = board.call("get_slot_data", pos)
		if slot_data == null:
			print("[BattleManager]   Slot ", pos, " has null data, skipping")
			continue
		var cid: StringName = _get_slot_card_id(slot_data)
		print("[BattleManager]   Slot ", pos, " card: ", cid)
		if cid in _NON_COMBAT_CARDS:
			print("[BattleManager]     Skipping non-combat card: ", cid)
			continue

		# Check if this card spawns in arena (troops only) or is a fixed structure.
		if not CardLib.spawns_in_arena(cid):
			print("[BattleManager]     Card does not spawn in arena: ", cid)
			# Fixed structure (Castle, Scout Tower) - track for fixed fire support.
			if CardLib.is_stationary_combat(cid):
				var structure_data: Dictionary = _build_fixed_structure_data(cid, slot_data, side, origin_map.get(pos, Vector2.ZERO))
				structure_data["slot_pos"] = pos  # Store the source slot position
				print("[BattleManager]     Added as fixed structure: ", cid)
				if side == 0:
					_player_fixed_structures.append(structure_data)
				else:
					_ai_fixed_structures.append(structure_data)
			continue

		print("[BattleManager]     Creating unit for troop: ", cid)
		var unit := UnitScript.new()
		_battle_container.add_child(unit)
		unit.call(
			"setup",
			cid,
			_get_slot_level(slot_data),
			side,
			_get_slot_extra_units(slot_data),
			_get_slot_smith_bonus(slot_data),
			_get_slot_steel_coat_stacks(slot_data)
		)
		_connect_unit_signals(unit)

		unit.set_meta("board_pos", pos)

		var origin = origin_map.get(pos, Vector2.ZERO)
		if origin is Vector2:
			unit.position = origin
		print("[BattleManager]     Unit created at position: ", unit.position, " visible: ", unit.visible)

		units.append(unit as Node2D)
	return units


func _build_fixed_structure_data(card_id: StringName, slot_data: RefCounted, side: int, origin: Vector2) -> Dictionary:
	var level: int = _get_slot_level(slot_data)
	var stats: Dictionary = CardLib.get_stats_for_level(card_id, level)
	var attack_dmg: float = stats.get("dmg", 10.0)
	var hits_per_second: float = float(stats.get("hps", 1.0))
	var attack_cd: float = 1.0 / hits_per_second if hits_per_second > 0.0 else 1.0
	var attack_range: float = float(stats.get("attack_range", 400.0))
	return {
		"card_id": card_id,
		"position": _get_fixed_structure_origin(card_id, side, origin),
		"level": level,
		"attack_dmg": attack_dmg,
		"attack_cd": attack_cd,
		"attack_range": attack_range,
		"cooldown_timer": 0.0,
		"side": side,
	}


func _get_fixed_structure_origin(card_id: StringName, side: int, origin: Vector2) -> Vector2:
	if origin != Vector2.ZERO:
		return origin
	if card_id == CardLib.CARD_CASTLE:
		return get_castle_contact_position(side)
	return Vector2(get_formation_x_for_unit_type(side, false, true), 0.0)


func _connect_unit_signals(unit: Node2D) -> void:
	if unit == null:
		return
	var attack_callable := Callable(self, "_on_unit_attack_performed")
	if unit.has_signal("attack_performed") and not unit.is_connected("attack_performed", attack_callable):
		unit.connect("attack_performed", attack_callable)


# ---------------------------------------------------------------------------
# Formation positioning
# ---------------------------------------------------------------------------

func _build_formation_targets(units: Array, side: int) -> Dictionary:
	var melee: Array = []
	var ranged: Array = []
	var buildings: Array = []
	var targets := {}

	for u: Node2D in units:
		if _unit_is_building(u):
			buildings.append(u)
		elif _unit_is_ranged(u):
			ranged.append(u)
		else:
			melee.append(u)

	# Use anchor-based positions
	var melee_x: float = get_formation_x_for_unit_type(side, false, false)
	var ranged_x: float = get_formation_x_for_unit_type(side, true, false)
	var building_x: float = get_formation_x_for_unit_type(side, false, true)

	_build_vertical_targets(melee, melee_x, targets)
	_build_vertical_targets(ranged, ranged_x, targets)
	_build_vertical_targets(buildings, building_x, targets)
	return targets


func _build_vertical_targets(units: Array, x_pos: float, targets: Dictionary) -> void:
	var count: int = units.size()
	if count == 0:
		return
	var spacing: float = minf(60.0, _ARENA_HEIGHT / float(count + 1))
	var start_y: float = -spacing * float(count - 1) * 0.5

	for i: int in range(count):
		var u: Node2D = units[i]
		targets[u] = Vector2(x_pos, start_y + spacing * float(i))


func _begin_deploy(player_targets: Dictionary, ai_targets: Dictionary) -> void:
	print("[BattleManager] _begin_deploy called")
	var all_targets := {}
	all_targets.merge(player_targets)
	all_targets.merge(ai_targets)

	print("[BattleManager] Total targets: ", all_targets.size())
	for unit in all_targets.keys():
		print("[BattleManager]   Unit deploy target: ", unit.name if unit else "null", " -> ", all_targets[unit])

	if all_targets.is_empty():
		print("[BattleManager] WARNING: No targets to deploy, calling _finish_deploy immediately")
		_finish_deploy()
		return

	_deploy_tween = create_tween()
	_deploy_tween.set_parallel(true)
	for unit in all_targets.keys():
		var target = all_targets[unit]
		if not (unit is Node2D) or not (target is Vector2):
			continue
		_deploy_tween.tween_property(unit, "position", target, _DEPLOY_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_deploy_tween.finished.connect(_finish_deploy)
	print("[BattleManager] Deploy tween started")


func _apply_fallback_spawn_positions(units: Array, targets: Dictionary, origin_map: Dictionary) -> void:
	for unit: Node2D in units:
		var board_pos = unit.get_meta("board_pos", null)
		if board_pos != null and origin_map.has(board_pos):
			continue
		var target = targets.get(unit, unit.position)
		if target is Vector2:
			unit.position = target


func _finish_deploy() -> void:
	print("[BattleManager] _finish_deploy called")
	_deploy_tween = null
	_assign_targets()

	print("[BattleManager] Starting units advancing...")
	for u: Node2D in _player_units:
		print("[BattleManager]   Player unit: ", u.name, " pos: ", u.position)
		u.call("start_advancing")
	for u: Node2D in _ai_units:
		print("[BattleManager]   AI unit: ", u.name, " pos: ", u.position)
		u.call("start_advancing")

	_is_active = true
	print("[BattleManager] Battle is now active, emitting battle_started")
	battle_started.emit()


# ---------------------------------------------------------------------------
# Target assignment
# ---------------------------------------------------------------------------

func _assign_targets() -> void:
	for u: Node2D in _player_units:
		if _unit_is_alive(u) and not _unit_has_live_target(u):
			var t: Node2D = _find_nearest_enemy(u, _ai_units)
			if t:
				u.call("set_target", t)

	for u: Node2D in _ai_units:
		if _unit_is_alive(u) and not _unit_has_live_target(u):
			var t: Node2D = _find_nearest_enemy(u, _player_units)
			if t:
				u.call("set_target", t)


func _find_nearest_enemy(unit: Node2D, enemies: Array) -> Node2D:
	var best: Node2D = null
	var best_dist: float = INF
	# First pass: prefer non-indestructible targets.
	for e: Node2D in enemies:
		if not _unit_is_alive(e) or _unit_is_indestructible(e):
			continue
		var d: float = unit.global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	# Fallback: indestructible targets (towers/castle) only if nothing else alive.
	if best == null:
		for e: Node2D in enemies:
			if not _unit_is_alive(e):
				continue
			var d: float = unit.global_position.distance_to(e.global_position)
			if d < best_dist:
				best_dist = d
				best = e
	return best


# ---------------------------------------------------------------------------
# Process loop
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _is_active:
		return

	# Update manual castle fire cooldown
	if _player_castle_manual_cooldown > 0.0:
		_player_castle_manual_cooldown = maxf(_player_castle_manual_cooldown - delta, 0.0)

	if _using_crowd_battle:
		_process_crowd_fixed_structure_attacks(delta)
		return

	if _chase_phase:
		_process_chase_phase(delta)
		_process_fixed_structure_attacks(delta)
		return

	# Retarget units whose target died.
	_assign_targets()

	# Check proximity → transition to fighting.
	_check_fighting_transitions()

	# Process fixed structure attacks (Castle, Scout Tower).
	_process_fixed_structure_attacks(delta)

	# Check if battle should end.
	_check_battle_end()


func _begin_crowd_deploy() -> void:
	_is_active = false
	_update_crowd_deploy_progress(0.0)
	if _crowd_deploy_tween != null:
		_crowd_deploy_tween.kill()
	_crowd_deploy_tween = create_tween()
	_crowd_deploy_tween.tween_method(_update_crowd_deploy_progress, 0.0, 1.0, _CROWD_DEPLOY_DURATION)
	_crowd_deploy_tween.finished.connect(_finish_crowd_deploy)


func _update_crowd_deploy_progress(progress: float) -> void:
	if _crowd_runtime != null:
		for soldier in _crowd_runtime.player_soldiers:
			_apply_deploy_position(soldier, progress)
		for soldier in _crowd_runtime.enemy_soldiers:
			_apply_deploy_position(soldier, progress)
	for structure in _player_fixed_structures:
		_apply_deploy_position(structure, progress)
	for structure in _ai_fixed_structures:
		_apply_deploy_position(structure, progress)


func _apply_deploy_position(entry: Dictionary, progress: float) -> void:
	var deploy_origin: Vector2 = entry.get("deploy_origin", entry.get("position", Vector2.ZERO))
	var formation_position: Vector2 = entry.get("formation_position", entry.get("position", Vector2.ZERO))
	entry["position"] = deploy_origin.lerp(formation_position, progress)


func _finish_crowd_deploy() -> void:
	_crowd_deploy_tween = null
	_update_crowd_deploy_progress(1.0)
	if _crowd_runtime != null:
		_crowd_runtime.start()
	_is_active = true
	battle_started.emit()


func _check_fighting_transitions() -> void:
	var all_units: Array = _player_units + _ai_units
	for u: Node2D in all_units:
		if not _unit_is_alive(u):
			continue
		if _unit_is_advancing(u):
			var target_node: Node2D = _unit_get_target(u)
			if target_node and _unit_is_alive(target_node):
				var dist: float = u.global_position.distance_to(target_node.global_position)
				if dist <= _unit_get_attack_range(u) + _PROXIMITY_THRESHOLD:
					u.call("start_fighting")


func _check_battle_end() -> void:
	if _field_result_locked:
		return

	var player_troops_alive: int = _count_alive_troops(_player_units)
	var ai_troops_alive: int = _count_alive_troops(_ai_units)

	if player_troops_alive > 0 and ai_troops_alive > 0:
		return  # Battle continues.

	if player_troops_alive == 0 and ai_troops_alive == 0:
		# Draw — AI wins by default.
		_begin_chase_phase(1)
		return

	if ai_troops_alive == 0:
		_begin_chase_phase(0)
	else:
		_begin_chase_phase(1)


## Process attacks from fixed structures (Castle, Scout Tower) that fire from board positions.
func _process_fixed_structure_attacks(delta: float) -> void:
	# Player fixed structures attack AI units.
	for structure in _player_fixed_structures:
		_process_single_structure_attack(structure, _ai_units, delta, true)

	# AI fixed structures attack player units.
	for structure in _ai_fixed_structures:
		_process_single_structure_attack(structure, _player_units, delta, false)


## Process attacks from fixed structures in crowd battle mode.
func _process_crowd_fixed_structure_attacks(delta: float) -> void:
	if _crowd_runtime == null:
		return
	
	var enemy_soldiers: Array = _crowd_runtime.get_living_soldiers(1)
	var player_soldiers: Array = _crowd_runtime.get_living_soldiers(0)
	
	# Player fixed structures attack enemy soldiers
	for structure in _player_fixed_structures:
		_process_single_structure_attack_crowd(structure, enemy_soldiers, delta, true)
	
	# AI fixed structures attack player soldiers
	for structure in _ai_fixed_structures:
		_process_single_structure_attack_crowd(structure, player_soldiers, delta, false)


func _process_single_structure_attack(structure: Dictionary, enemy_units: Array, delta: float, is_player_structure: bool) -> void:
	# Decrease cooldown timer.
	structure["cooldown_timer"] = maxf(structure["cooldown_timer"] - delta, 0.0)

	if structure["cooldown_timer"] > 0.0:
		return
	
	# Player castle in manual mode doesn't auto-fire
	var card_id: StringName = structure.get("card_id", &"")
	if is_player_structure and card_id == CardLib.CARD_CASTLE and player_castle_fire_mode == "manual":
		return

	# Find nearest alive enemy within range.
	var target: Node2D = _find_nearest_enemy_for_structure(structure, enemy_units)
	if target == null:
		return

	# Perform attack.
	var damage: float = structure["attack_dmg"]
	if target.has_method("take_damage"):
		target.call("take_damage", damage)

	# Reset cooldown.
	structure["cooldown_timer"] = structure["attack_cd"]

	# Spawn visual attack effect.
	_spawn_fixed_structure_attack_effect(structure, target)


func _process_single_structure_attack_crowd(structure: Dictionary, enemy_soldiers: Array, delta: float, is_player_structure: bool) -> void:
	# Decrease cooldown timer.
	structure["cooldown_timer"] = maxf(structure["cooldown_timer"] - delta, 0.0)

	if structure["cooldown_timer"] > 0.0:
		return
	
	# Player castle in manual mode doesn't auto-fire
	var card_id: StringName = structure.get("card_id", &"")
	if is_player_structure and card_id == CardLib.CARD_CASTLE and player_castle_fire_mode == "manual":
		return

	# Find nearest alive enemy within range.
	var target: Dictionary = _find_nearest_enemy_soldier_for_structure(structure, enemy_soldiers)
	if target.is_empty():
		return

	# Perform attack.
	var damage: float = structure["attack_dmg"]
	target["hp"] = float(target.get("hp", 0.0)) - damage
	
	if float(target.get("hp", 0.0)) <= 0.0:
		target["state"] = "dying"

	# Reset cooldown.
	structure["cooldown_timer"] = structure["attack_cd"]

	# Spawn visual attack effect (projectile from structure to target position).
	var effect_parent := _ensure_effect_container()
	if effect_parent != null:
		var target_pos: Vector2 = target.get("position", Vector2.ZERO)
		_spawn_projectile_effect(effect_parent, card_id, structure["position"], target_pos)


## Perform a manual castle fire at a ground position (no specific target).
func _perform_castle_ground_fire(structure: Dictionary, target_pos: Vector2) -> void:
	# Spawn visual effect (projectile from structure to ground)
	var effect_parent := _ensure_effect_container()
	if effect_parent != null:
		_spawn_projectile_effect(effect_parent, CardLib.CARD_CASTLE, structure["position"], target_pos)
	
	# Apply splash damage at target_pos with castle damage values
	_apply_castle_splash_damage(target_pos, structure.get("attack_dmg", 50.0), structure)



func _apply_castle_splash_damage(impact_pos: Vector2, base_damage: float, source_structure: Dictionary = {}) -> void:
	# Only apply splash in crowd mode
	if not _using_crowd_battle or _crowd_runtime == null:
		return
	
	# Instantiate the impact scene to get splash parameters
	var impact = CastleImpactScene.instantiate()
	if impact == null:
		return
	
	# Get splash parameters
	var outer_radius: float = impact.outer_radius
	
	# Apply damage to crowd soldiers within splash radius
	# The crowd runtime manages soldiers internally, we access via call interface
	var soldiers: Array = _crowd_runtime.call("get_soldiers")
	var total_damage_dealt: int = 0
	if soldiers != null:
		for soldier: Dictionary in soldiers:
			var soldier_pos: Vector2 = soldier.get("position", Vector2.ZERO)
			var distance: float = impact_pos.distance_to(soldier_pos)
			
			# Only apply damage if within splash range
			if distance > outer_radius:
				continue
			
			# Get the multiplier based on distance
			var multiplier: float = impact.get_splash_multiplier(distance)
			if multiplier > 0.0:
				# Apply damage to the soldier
				var actual_damage: int = int(base_damage * multiplier)
				
				# Take damage (existing crowd system should handle this)
				if "current_hp" in soldier:
					soldier["current_hp"] = max(0, soldier["current_hp"] - actual_damage)
					total_damage_dealt += actual_damage
	
	# Record slot damage for the source structure
	if source_structure != null and source_structure.has("slot_pos") and source_structure.has("side"):
		_record_slot_damage(source_structure["side"], source_structure["slot_pos"], total_damage_dealt)
	
	# Clean up impact instance (visual effect may be spawned separately)
	impact.queue_free()


func _find_nearest_enemy_soldier_for_structure(structure: Dictionary, enemy_soldiers: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_dist: float = INF
	var origin: Vector2 = structure["position"]
	var attack_range: float = structure["attack_range"]

	for soldier: Dictionary in enemy_soldiers:
		var state: String = String(soldier.get("state", "dead"))
		if state == "dead" or state == "dying":
			continue
		var soldier_pos: Vector2 = soldier.get("position", Vector2.ZERO)
		var d: float = origin.distance_to(soldier_pos)
		if d <= attack_range and d < best_dist:
			best_dist = d
			best = soldier
	return best


func _find_nearest_enemy_for_structure(structure: Dictionary, enemies: Array) -> Node2D:
	var best: Node2D = null
	var best_dist: float = INF
	var origin: Vector2 = structure["position"]
	var attack_range: float = structure["attack_range"]

	for e: Node2D in enemies:
		if not _unit_is_alive(e):
			continue
		var d: float = origin.distance_to(e.global_position)
		if d <= attack_range and d < best_dist:
			best_dist = d
			best = e
	return best


func _spawn_fixed_structure_attack_effect(structure: Dictionary, target: Node2D) -> void:
	var effect_parent := _ensure_effect_container()
	if effect_parent == null:
		return
	var card_id: StringName = structure["card_id"]
	_spawn_projectile_effect(effect_parent, card_id, structure["position"], target.global_position)

	# Flash the target when hit.
	_flash_target(target)


func _begin_chase_phase(winner: int) -> void:
	if _field_result_locked:
		return

	_field_result_locked = true
	_chase_phase = true
	_chase_timer = _CHASE_DURATION
	_winner_side = winner

	# Determine loser side and get castle contact position from anchor.
	var loser_side: int = 1 if winner == 0 else 0
	var castle_pos: Vector2 = get_castle_contact_position(loser_side)

	# Winning troops chase toward the loser's castle contact anchor.
	var winner_units: Array = []
	if winner == 0:
		winner_units = _player_units
	else:
		winner_units = _ai_units
	for u: Node2D in winner_units:
		if _unit_is_alive(u) and not _unit_is_building(u):
			u.call("set_target", null)  # No unit target, just chase position
			u.call("start_chasing_castle", castle_pos)

	_assign_siege_targets()


func _process_chase_phase(delta: float) -> void:
	_assign_siege_targets()
	_check_fighting_transitions()

	if _did_siege_reach_castle():
		_finish_battle()
		return

	_chase_timer -= delta
	if _chase_timer <= 0.0:
		_finish_battle()


func _assign_siege_targets() -> void:
	var attackers: Array = _get_winning_mobile_units()
	var loser_side: int = 1 if _winner_side == 0 else 0
	var castle_pos: Vector2 = get_castle_contact_position(loser_side)

	for attacker: Node2D in attackers:
		if _unit_is_alive(attacker):
			attacker.call("set_target", null)
			attacker.call("start_chasing_castle", castle_pos)


func _did_siege_reach_castle() -> bool:
	var loser_side: int = 1 if _winner_side == 0 else 0
	var castle_pos: Vector2 = get_castle_contact_position(loser_side)

	for attacker: Node2D in _get_winning_mobile_units():
		var dist: float = attacker.global_position.distance_to(castle_pos)
		if dist <= _SIEGE_CONTACT_DISTANCE:
			return true
	return false


func _finish_battle() -> void:
	print("[BattleManager] _finish_battle called, winner_side: ", _winner_side)
	_is_active = false
	battle_ended.emit(_winner_side)


func _get_winning_mobile_units() -> Array:
	var winners: Array = []
	var source: Array = _player_units
	if _winner_side == 1:
		source = _ai_units

	for unit: Node2D in source:
		if _unit_is_alive(unit) and not _unit_is_building(unit):
			winners.append(unit)
	return winners


func _get_losing_units() -> Array:
	if _winner_side == 0:
		return _ai_units
	return _player_units


func _count_alive_troops(units: Array) -> int:
	var count: int = 0
	for u: Node2D in units:
		if _unit_is_alive(u) and not _unit_is_building(u):
			count += 1
	return count


func _on_unit_attack_performed(attacker, target) -> void:
	if not (attacker is Node2D) or not (target is Node2D):
		return
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	if not _should_spawn_attack_effect(attacker):
		return
	_spawn_attack_effect(attacker, target)
	_pulse_attacker_visual(attacker)
	_flash_target(target)


func _should_spawn_attack_effect(attacker: Node2D) -> bool:
	if _unit_is_building(attacker):
		var card_id := _unit_get_card_id(attacker)
		return card_id == CardLib.CARD_SCOUT_TOWER or card_id == CardLib.CARD_CASTLE
	return _unit_is_ranged(attacker)


func _spawn_attack_effect(attacker: Node2D, target: Node2D) -> void:
	var effect_parent := _ensure_effect_container()
	if effect_parent == null:
		return

	var card_id := _unit_get_card_id(attacker)
	_spawn_projectile_effect(effect_parent, card_id, attacker.global_position, target.global_position)


func _spawn_projectile_effect(effect_parent: Node2D, card_id: StringName, start_pos: Vector2, end_pos: Vector2) -> void:
	match card_id:
		CardLib.CARD_ARCHER, CardLib.CARD_SCOUT_TOWER:
			var arrow_effect := ProjectileEffectScene.instantiate()
			if arrow_effect == null:
				return
			effect_parent.add_child(arrow_effect)
			var arrow_duration_scale: float = 2.0 if card_id == CardLib.CARD_SCOUT_TOWER else 1.0
			arrow_effect.call("launch_arrow", start_pos, end_pos, 1400.0, Color.WHITE, arrow_duration_scale)
		CardLib.CARD_CASTLE:
			var cannonball_effect := ProjectileEffectScene.instantiate()
			if cannonball_effect == null:
				return
			effect_parent.add_child(cannonball_effect)
			cannonball_effect.call("launch_cannonball", start_pos, end_pos, 1250.0, Color(0.08, 0.08, 0.1, 1.0), 2.0)
		_:
			var fallback_effect = AttackEffectScript.new()
			effect_parent.add_child(fallback_effect)
			fallback_effect.launch(start_pos, end_pos, Color(1.0, 0.85, 0.35, 1.0), 3.0, 1200.0, 4.0, 10.0)


func _ensure_effect_container() -> Node2D:
	if _effect_container and is_instance_valid(_effect_container):
		return _effect_container
	if _battle_container == null or not is_instance_valid(_battle_container):
		return null

	_effect_container = Node2D.new()
	_effect_container.name = "BattleEffects"
	_effect_container.z_index = 10
	_battle_container.add_child(_effect_container)
	return _effect_container


func _emit_crowd_battle_start_summary(player_soldiers: Array, enemy_soldiers: Array) -> void:
	if _battle_debug == null or _arena_geometry == null:
		return
	var arena_rect: Rect2 = _arena_geometry.call("get_arena_rect")
	var player_zone: Rect2 = _arena_geometry.call("get_player_spawn_zone")
	var enemy_zone: Rect2 = _arena_geometry.call("get_enemy_spawn_zone")
	var summary: Dictionary = {
		"mode": "crowd",
		"arena_rect": arena_rect,
		"player_spawn_zone": player_zone,
		"enemy_spawn_zone": enemy_zone,
		"player_count": player_soldiers.size(),
		"enemy_count": enemy_soldiers.size(),
		"player_types": _count_soldiers_by_type(player_soldiers),
		"enemy_types": _count_soldiers_by_type(enemy_soldiers),
		"player_front_x": _arena_geometry.call("get_formation_x", 0, "melee"),
		"player_ranged_x": _arena_geometry.call("get_formation_x", 0, "ranged"),
		"enemy_front_x": _arena_geometry.call("get_formation_x", 1, "melee"),
		"enemy_ranged_x": _arena_geometry.call("get_formation_x", 1, "ranged"),
		"player_search_range": _extract_search_range(player_soldiers),
		"enemy_search_range": _extract_search_range(enemy_soldiers),
		"player_spawn_spread": _build_spawn_spread_summary(player_soldiers),
		"enemy_spawn_spread": _build_spawn_spread_summary(enemy_soldiers),
	}
	_battle_debug.call("set_battle_start_summary", summary)
	_battle_debug.call(
		"log_once_per_interval",
		"crowd_battle_start",
		0.0,
		"[CrowdStart] arena=%s player=%d enemy=%d p_front=%.1f e_front=%.1f search P:%.1f E:%.1f" % [
			str(arena_rect),
			player_soldiers.size(),
			enemy_soldiers.size(),
			float(summary["player_front_x"]),
			float(summary["enemy_front_x"]),
			float(summary["player_search_range"]),
			float(summary["enemy_search_range"]),
		],
		BattleDebugScript.LogLevel.SUMMARY,
		0.0
	)


func _count_soldiers_by_type(soldiers: Array) -> Dictionary:
	var counts: Dictionary = {}
	for soldier: Dictionary in soldiers:
		var unit_type: StringName = StringName(soldier.get("unit_type", &"unknown"))
		counts[unit_type] = int(counts.get(unit_type, 0)) + 1
	return counts


func _build_spawn_spread_summary(soldiers: Array) -> Dictionary:
	if soldiers.is_empty():
		return {}
	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	var max_y: float = -INF
	for soldier: Dictionary in soldiers:
		var pos: Vector2 = soldier.get("position", Vector2.ZERO)
		min_x = minf(min_x, pos.x)
		max_x = maxf(max_x, pos.x)
		min_y = minf(min_y, pos.y)
		max_y = maxf(max_y, pos.y)
	return {
		"min_x": min_x,
		"max_x": max_x,
		"min_y": min_y,
		"max_y": max_y,
	}


func _extract_search_range(soldiers: Array) -> float:
	if soldiers.is_empty():
		return 0.0
	var first_soldier: Variant = soldiers[0]
	if first_soldier is Dictionary:
		return float(first_soldier.get("search_range", 0.0))
	return 0.0


func _pulse_attacker_visual(attacker: Node2D) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	if not _unit_is_building(attacker):
		return

	var visual := attacker.get_node_or_null("IconSprite") as Node2D
	if visual == null:
		visual = attacker.get_node_or_null("Actor") as Node2D
	if visual == null:
		return

	var base_scale := visual.scale
	var tween := create_tween()
	tween.tween_property(visual, "scale", base_scale * 1.12, 0.04)
	tween.tween_property(visual, "scale", base_scale, 0.08)


func _flash_target(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	var base_modulate := Color(1.0, 1.0, 1.0, 1.0)
	if target.has_meta("flash_base_modulate"):
		var stored_modulate: Variant = target.get_meta("flash_base_modulate")
		if stored_modulate is Color:
			base_modulate = stored_modulate
	else:
		base_modulate = target.modulate
		target.set_meta("flash_base_modulate", base_modulate)

	if target.has_meta("flash_tween"):
		var existing_tween: Variant = target.get_meta("flash_tween")
		if existing_tween is Tween and is_instance_valid(existing_tween):
			existing_tween.kill()

	target.modulate = Color(1.0, 1.0, 1.0, 1.0)
	# Bind tween to target lifecycle so it dies when target is freed (prevents signal error)
	var tween := target.create_tween()
	target.set_meta("flash_tween", tween)
	tween.tween_property(target, "modulate", base_modulate, 0.12)
	tween.finished.connect(_on_target_flash_finished.bind(target, base_modulate))


func _on_target_flash_finished(target: Node2D, base_modulate: Color) -> void:
	if target == null or not is_instance_valid(target):
		return
	target.modulate = base_modulate
	if target.has_meta("flash_tween"):
		target.remove_meta("flash_tween")


func _get_player_board(player: RefCounted) -> RefCounted:
	var board_value: Variant = player.get("board")
	if board_value is RefCounted:
		return board_value
	return null


func _get_player_castle_hp(player: RefCounted) -> int:
	return int(player.get("castle_hp"))


func _get_slot_card_id(slot_data: RefCounted) -> StringName:
	return StringName(slot_data.get("card_id"))


func _get_slot_level(slot_data: RefCounted) -> int:
	return int(slot_data.get("level"))


func _get_slot_extra_units(slot_data: RefCounted) -> int:
	return int(slot_data.get("extra_units"))


func _get_slot_smith_bonus(slot_data: RefCounted) -> float:
	return float(slot_data.get("smith_dmg_bonus"))


func _get_slot_steel_coat_stacks(slot_data: RefCounted) -> int:
	return int(slot_data.get("steel_coat_stacks"))


func _unit_is_alive(unit: Node2D) -> bool:
	return bool(unit.call("is_alive"))


func _unit_has_live_target(unit: Node2D) -> bool:
	return bool(unit.call("has_live_target"))


func _unit_is_indestructible(unit: Node2D) -> bool:
	return bool(unit.get("is_indestructible"))


func _unit_is_advancing(unit: Node2D) -> bool:
	return bool(unit.call("is_advancing"))


func _unit_get_target(unit: Node2D) -> Node2D:
	var target_value: Variant = unit.call("get_target")
	if target_value is Node2D:
		return target_value
	return null


func _unit_get_card_id(unit: Node2D) -> StringName:
	return StringName(unit.get("card_id"))


func _unit_is_building(unit: Node2D) -> bool:
	return bool(unit.get("is_building"))


func _unit_is_ranged(unit: Node2D) -> bool:
	return bool(unit.get("is_ranged"))


func _unit_get_attack_range(unit: Node2D) -> float:
	return float(unit.get("attack_range"))
