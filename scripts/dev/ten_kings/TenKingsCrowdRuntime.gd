class_name TenKingsCrowdRuntime
extends Node
## Centralized battle simulation that updates all soldiers each frame.

const SpatialGridScript = preload("res://scripts/dev/ten_kings/TenKingsCrowdSpatialGrid.gd")
const BattleDebugScript = preload("res://scripts/dev/ten_kings/TenKingsBattleDebug.gd")

signal soldier_died(soldier_id: int, team: int)
signal battle_ended(winner_team: int)
signal soldier_attack_performed(attacker_id: int, target_id: int, damage: float)

const TEAM_PLAYER := 0
const TEAM_ENEMY := 1

var player_soldiers: Array = []
var enemy_soldiers: Array = []
var _spatial_grid: RefCounted
var _active: bool = false
var _debug_helper: RefCounted = null
var _elapsed_time: float = 0.0
var _heartbeat_timer: float = 0.0
var _watchdog_timer: float = 0.0
var _attacks_in_window: int = 0
var _player_attacks_in_window: int = 0
var _enemy_attacks_in_window: int = 0
var _player_damage_in_window: float = 0.0
var _enemy_damage_in_window: float = 0.0
var _player_kills_in_window: int = 0
var _enemy_kills_in_window: int = 0
var _deaths_in_window: int = 0
var _retargets_in_window: int = 0

# Lookup table: soldier_id -> soldier Dictionary
var _soldiers_by_id: Dictionary = {}


func _ready() -> void:
	_spatial_grid = SpatialGridScript.new()


func setup(p_player_soldiers: Array, p_enemy_soldiers: Array) -> void:
	player_soldiers = p_player_soldiers.duplicate(true)
	enemy_soldiers = p_enemy_soldiers.duplicate(true)
	_elapsed_time = 0.0
	_heartbeat_timer = 0.0
	_watchdog_timer = 0.0
	_attacks_in_window = 0
	_player_attacks_in_window = 0
	_enemy_attacks_in_window = 0
	_player_damage_in_window = 0.0
	_enemy_damage_in_window = 0.0
	_player_kills_in_window = 0
	_enemy_kills_in_window = 0
	_deaths_in_window = 0
	_retargets_in_window = 0
	
	_soldiers_by_id.clear()
	_spatial_grid.clear()
	
	# Initialize player soldiers
	for soldier in player_soldiers:
		_ensure_soldier_defaults(soldier, TEAM_PLAYER)
		_soldiers_by_id[soldier["id"]] = soldier
		_spatial_grid.insert(soldier["id"], soldier["position"], TEAM_PLAYER)
	
	# Initialize enemy soldiers
	for soldier in enemy_soldiers:
		_ensure_soldier_defaults(soldier, TEAM_ENEMY)
		_soldiers_by_id[soldier["id"]] = soldier
		_spatial_grid.insert(soldier["id"], soldier["position"], TEAM_ENEMY)


func _ensure_soldier_defaults(soldier: Dictionary, team: int) -> void:
	if not soldier.has("state"):
		soldier["state"] = "idle"
	if not soldier.has("target_id"):
		soldier["target_id"] = -1
	if not soldier.has("attack_cooldown"):
		soldier["attack_cooldown"] = 1.0
	if not soldier.has("current_cooldown"):
		soldier["current_cooldown"] = 0.0
	if not soldier.has("team"):
		soldier["team"] = team
	if not soldier.has("smith_dmg_bonus"):
		soldier["smith_dmg_bonus"] = 0.0
	if not soldier.has("last_position"):
		soldier["last_position"] = soldier.get("position", Vector2.ZERO)
	if not soldier.has("last_target_distance"):
		soldier["last_target_distance"] = INF
	if not soldier.has("time_since_progress"):
		soldier["time_since_progress"] = 0.0


func set_debug_helper(debug_helper: RefCounted) -> void:
	_debug_helper = debug_helper


func start() -> void:
	_active = true
	for soldier in player_soldiers:
		if soldier.get("state", "idle") == "deploying":
			soldier["state"] = "idle"
	for soldier in enemy_soldiers:
		if soldier.get("state", "idle") == "deploying":
			soldier["state"] = "idle"
	refresh_spatial_grid()


func stop() -> void:
	_active = false


func refresh_spatial_grid() -> void:
	_spatial_grid.clear()
	for soldier in player_soldiers:
		if soldier.get("state", "dead") == "dead":
			continue
		_spatial_grid.insert(soldier["id"], soldier.get("position", Vector2.ZERO), TEAM_PLAYER)
	for soldier in enemy_soldiers:
		if soldier.get("state", "dead") == "dead":
			continue
		_spatial_grid.insert(soldier["id"], soldier.get("position", Vector2.ZERO), TEAM_ENEMY)


func get_soldier(id: int) -> Dictionary:
	if _soldiers_by_id.has(id):
		return _soldiers_by_id[id]
	return {}


func get_living_soldiers(team: int) -> Array:
	var living: Array = []
	var source := player_soldiers if team == TEAM_PLAYER else enemy_soldiers
	
	for soldier in source:
		if soldier["state"] != "dead" and soldier["state"] != "dying":
			living.append(soldier)
	
	return living


## Returns all living soldiers from both teams.
func get_all_living_soldiers() -> Array:
	var living: Array = []
	living.append_array(get_living_soldiers(TEAM_PLAYER))
	living.append_array(get_living_soldiers(TEAM_ENEMY))
	return living


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed_time += delta
	_heartbeat_timer += delta
	_watchdog_timer += delta
	
	# Update all soldiers
	for soldier in player_soldiers:
		_update_soldier(soldier, delta)
	
	for soldier in enemy_soldiers:
		_update_soldier(soldier, delta)

	if _heartbeat_timer >= 1.0:
		_emit_heartbeat_snapshot()
		_heartbeat_timer = 0.0
		_attacks_in_window = 0
		_player_attacks_in_window = 0
		_enemy_attacks_in_window = 0
		_player_damage_in_window = 0.0
		_enemy_damage_in_window = 0.0
		_player_kills_in_window = 0
		_enemy_kills_in_window = 0
		_deaths_in_window = 0
		_retargets_in_window = 0

	_check_watchdog()
	
	# Check for battle end
	_check_battle_end()


func _update_soldier(soldier: Dictionary, delta: float) -> void:
	match soldier["state"]:
		"dead":
			return
		"dying":
			_process_dying(soldier, delta)
		"idle":
			_process_idle(soldier)
		"walking":
			_process_walking(soldier, delta)
		"attacking":
			_process_attacking(soldier, delta)


func _process_idle(soldier: Dictionary) -> void:
	# Find nearest enemy
	var target_id := _find_nearest_enemy(soldier)
	
	if target_id != -1:
		if int(soldier.get("target_id", -1)) != target_id:
			_on_retargeted()
		soldier["target_id"] = target_id
		soldier["state"] = "walking"
	else:
		soldier["target_id"] = -1


func _process_walking(soldier: Dictionary, delta: float) -> void:
	var target_id: int = soldier["target_id"]
	
	# Check if target is still valid
	if target_id == -1 or not _soldiers_by_id.has(target_id):
		soldier["state"] = "idle"
		soldier["target_id"] = -1
		return
	
	var target: Dictionary = _soldiers_by_id[target_id]
	if target["state"] == "dead" or target["state"] == "dying":
		soldier["state"] = "idle"
		soldier["target_id"] = -1
		return
	
	var position: Vector2 = soldier["position"]
	var target_position: Vector2 = target["position"]
	var direction := (target_position - position).normalized()
	var distance := position.distance_to(target_position)
	var attack_range: float = soldier.get("attack_range", 50.0)
	var previous_distance: float = float(soldier.get("last_target_distance", INF))
	if previous_distance - distance > 1.0:
		soldier["time_since_progress"] = 0.0
	else:
		soldier["time_since_progress"] = float(soldier.get("time_since_progress", 0.0)) + delta
	soldier["last_target_distance"] = distance
	
	# Check if in attack range
	if distance <= attack_range:
		soldier["state"] = "attacking"
		soldier["current_cooldown"] = float(soldier.get("attack_entry_windup", 0.2))
		return

	if float(soldier.get("time_since_progress", 0.0)) >= 1.5:
		soldier["state"] = "idle"
		soldier["target_id"] = -1
		return
	
	# Move toward target
	var old_position := position
	var speed: float = soldier.get("speed", 100.0)
	var new_position := position + direction * speed * delta
	soldier["position"] = new_position
	soldier["last_position"] = position
	
	# Update spatial grid
	_spatial_grid.update(soldier["id"], old_position, new_position)


func _process_attacking(soldier: Dictionary, delta: float) -> void:
	var target_id: int = soldier["target_id"]
	
	# Check if target is still valid
	if target_id == -1 or not _soldiers_by_id.has(target_id):
		soldier["state"] = "idle"
		soldier["target_id"] = -1
		return
	
	var target: Dictionary = _soldiers_by_id[target_id]
	if target["state"] == "dead" or target["state"] == "dying":
		soldier["state"] = "idle"
		soldier["target_id"] = -1
		return
	
	# Check if still in range
	var distance: float = soldier["position"].distance_to(target["position"])
	var attack_range: float = soldier.get("attack_range", 50.0)
	var range_buffer: float = 18.0 if bool(soldier.get("is_ranged", false)) else 8.0
	
	if distance > attack_range + range_buffer:
		soldier["state"] = "walking"
		return
	
	# Handle attack cooldown
	soldier["current_cooldown"] = float(soldier.get("current_cooldown", 0.0)) - delta
	
	if float(soldier.get("current_cooldown", 0.0)) <= 0.0:
		_perform_attack(soldier, target)
		var attack_cooldown: float = float(soldier.get("attack_cooldown", 1.0))
		soldier["current_cooldown"] = attack_cooldown


func _perform_attack(attacker: Dictionary, target: Dictionary) -> void:
	var base_damage: float = attacker.get("attack_dmg", 10.0)
	var smith_bonus: float = attacker.get("smith_dmg_bonus", 0.0)
	var damage := base_damage * (1.0 + smith_bonus)
	
	target["hp"] = target.get("hp", 100.0) - damage
	
	_attacks_in_window += 1
	if int(attacker.get("team", TEAM_PLAYER)) == TEAM_PLAYER:
		_player_attacks_in_window += 1
		_player_damage_in_window += damage
	else:
		_enemy_attacks_in_window += 1
		_enemy_damage_in_window += damage
	if _debug_helper != null:
		_debug_helper.call("record_attack")
	soldier_attack_performed.emit(attacker["id"], target["id"], damage)
	
	if target["hp"] <= 0:
		target["state"] = "dying"
		_spatial_grid.remove(target["id"])
		_deaths_in_window += 1
		if int(attacker.get("team", TEAM_PLAYER)) == TEAM_PLAYER:
			_player_kills_in_window += 1
		else:
			_enemy_kills_in_window += 1
		if _debug_helper != null:
			_debug_helper.call("record_death")
		soldier_died.emit(target["id"], target["team"])


func _process_dying(soldier: Dictionary, delta: float) -> void:
	# Death animation timer (if any)
	var death_timer: float = soldier.get("death_timer", 0.5)
	death_timer -= delta
	soldier["death_timer"] = death_timer
	
	if death_timer <= 0.0:
		soldier["state"] = "dead"


func _find_nearest_enemy(soldier: Dictionary) -> int:
	var position: Vector2 = soldier["position"]
	var team: int = soldier["team"]
	var search_range: float = soldier.get("search_range", 500.0)
	
	# Get all enemies in range from spatial grid
	var enemies: Array = _spatial_grid.get_enemies_in_range(position, team, search_range)
	
	var nearest_id: int = -1
	var nearest_dist_sq: float = INF
	
	for enemy_id in enemies:
		if not _soldiers_by_id.has(enemy_id):
			continue
		
		var enemy: Dictionary = _soldiers_by_id[enemy_id]
		if enemy["state"] == "dead" or enemy["state"] == "dying":
			continue
		
		var dist_sq: float = position.distance_squared_to(enemy["position"])
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest_id = enemy_id
	
	return nearest_id


func _emit_heartbeat_snapshot() -> void:
	if _debug_helper == null:
		return
	var player_living: Array = get_living_soldiers(TEAM_PLAYER)
	var enemy_living: Array = get_living_soldiers(TEAM_ENEMY)
	var player_metrics: Dictionary = _collect_team_metrics(player_living)
	var enemy_metrics: Dictionary = _collect_team_metrics(enemy_living)
	var snapshot: Dictionary = {
		"elapsed_time": _elapsed_time,
		"player_alive": player_living.size(),
		"enemy_alive": enemy_living.size(),
		"player_idle": player_metrics["idle"],
		"player_walking": player_metrics["walking"],
		"player_attacking": player_metrics["attacking"],
		"player_dying": player_metrics["dying"],
		"enemy_idle": enemy_metrics["idle"],
		"enemy_walking": enemy_metrics["walking"],
		"enemy_attacking": enemy_metrics["attacking"],
		"enemy_dying": enemy_metrics["dying"],
		"player_no_target": player_metrics["no_target"],
		"enemy_no_target": enemy_metrics["no_target"],
		"player_stuck": player_metrics["stuck"],
		"enemy_stuck": enemy_metrics["stuck"],
		"player_avg_distance_to_target": player_metrics["avg_distance_to_target"],
		"enemy_avg_distance_to_target": enemy_metrics["avg_distance_to_target"],
		"player_attacking_avg_distance_to_target": player_metrics["attacking_avg_distance_to_target"],
		"enemy_attacking_avg_distance_to_target": enemy_metrics["attacking_avg_distance_to_target"],
		"player_attacking_avg_attack_range": player_metrics["attacking_avg_attack_range"],
		"enemy_attacking_avg_attack_range": enemy_metrics["attacking_avg_attack_range"],
		"attacks_in_window": _attacks_in_window,
		"player_attacks_in_window": _player_attacks_in_window,
		"enemy_attacks_in_window": _enemy_attacks_in_window,
		"player_damage_in_window": _player_damage_in_window,
		"enemy_damage_in_window": _enemy_damage_in_window,
		"player_kills_in_window": _player_kills_in_window,
		"enemy_kills_in_window": _enemy_kills_in_window,
		"deaths_in_window": _deaths_in_window,
		"retargets_in_window": _retargets_in_window,
	}
	_debug_helper.call("set_latest_heartbeat_snapshot", snapshot)
	_debug_helper.call(
		"log_once_per_interval",
		"crowd_heartbeat",
		1.0,
		"[Crowd] alive P:%d E:%d walk P:%d E:%d atk P:%d E:%d no_target P:%d E:%d stuck P:%d E:%d attacks P:%d E:%d dmg P:%.1f E:%.1f kills P:%d E:%d atk_dist P:%.1f/%.1f E:%.1f/%.1f" % [
			snapshot["player_alive"],
			snapshot["enemy_alive"],
			snapshot["player_walking"],
			snapshot["enemy_walking"],
			snapshot["player_attacking"],
			snapshot["enemy_attacking"],
			snapshot["player_no_target"],
			snapshot["enemy_no_target"],
			snapshot["player_stuck"],
			snapshot["enemy_stuck"],
			snapshot["player_attacks_in_window"],
			snapshot["enemy_attacks_in_window"],
			snapshot["player_damage_in_window"],
			snapshot["enemy_damage_in_window"],
			snapshot["player_kills_in_window"],
			snapshot["enemy_kills_in_window"],
			0.0 if snapshot["player_attacking_avg_distance_to_target"] == INF else snapshot["player_attacking_avg_distance_to_target"],
			0.0 if snapshot["player_attacking_avg_attack_range"] == INF else snapshot["player_attacking_avg_attack_range"],
			0.0 if snapshot["enemy_attacking_avg_distance_to_target"] == INF else snapshot["enemy_attacking_avg_distance_to_target"],
			0.0 if snapshot["enemy_attacking_avg_attack_range"] == INF else snapshot["enemy_attacking_avg_attack_range"],
		],
		BattleDebugScript.LogLevel.SUMMARY,
		_elapsed_time
	)


func _collect_team_metrics(soldiers: Array) -> Dictionary:
	var idle_count: int = 0
	var walking_count: int = 0
	var attacking_count: int = 0
	var dying_count: int = 0
	var no_target_count: int = 0
	var stuck_count: int = 0
	var total_distance: float = 0.0
	var distance_samples: int = 0
	var attacking_total_distance: float = 0.0
	var attacking_distance_samples: int = 0
	var attacking_total_range: float = 0.0
	var attacking_range_samples: int = 0
	for soldier: Dictionary in soldiers:
		var state: String = String(soldier.get("state", "idle"))
		match state:
			"idle":
				idle_count += 1
			"walking":
				walking_count += 1
			"attacking":
				attacking_count += 1
			"dying":
				dying_count += 1
		if int(soldier.get("target_id", -1)) == -1:
			no_target_count += 1
		if float(soldier.get("time_since_progress", 0.0)) >= 1.5:
			stuck_count += 1
		var distance_to_target: float = _get_distance_to_target(soldier)
		if distance_to_target < INF:
			total_distance += distance_to_target
			distance_samples += 1
			if state == "attacking":
				attacking_total_distance += distance_to_target
				attacking_distance_samples += 1
				attacking_total_range += float(soldier.get("attack_range", 0.0))
				attacking_range_samples += 1
	return {
		"idle": idle_count,
		"walking": walking_count,
		"attacking": attacking_count,
		"dying": dying_count,
		"no_target": no_target_count,
		"stuck": stuck_count,
		"avg_distance_to_target": total_distance / float(distance_samples) if distance_samples > 0 else INF,
		"attacking_avg_distance_to_target": attacking_total_distance / float(attacking_distance_samples) if attacking_distance_samples > 0 else INF,
		"attacking_avg_attack_range": attacking_total_range / float(attacking_range_samples) if attacking_range_samples > 0 else INF,
	}


func _get_distance_to_target(soldier: Dictionary) -> float:
	var target_id: int = int(soldier.get("target_id", -1))
	if target_id == -1 or not _soldiers_by_id.has(target_id):
		return INF
	var target: Dictionary = _soldiers_by_id[target_id]
	if String(target.get("state", "dead")) == "dead":
		return INF
	return Vector2(soldier.get("position", Vector2.ZERO)).distance_to(Vector2(target.get("position", Vector2.ZERO)))


func _check_watchdog() -> void:
	if _debug_helper == null:
		return
	if not bool(_debug_helper.get("watchdog_enabled")):
		return
	if _watchdog_timer < 2.5:
		return
	var player_alive: int = get_living_soldiers(TEAM_PLAYER).size()
	var enemy_alive: int = get_living_soldiers(TEAM_ENEMY).size()
	if player_alive <= 0 or enemy_alive <= 0:
		return
	if _attacks_in_window > 0 or _deaths_in_window > 0:
		_watchdog_timer = 0.0
		return
	var heartbeat: Dictionary = _debug_helper.call("get_latest_heartbeat_snapshot")
	var snapshot: Dictionary = {
		"elapsed_time": _elapsed_time,
		"reason": "stall_no_attacks",
		"player_alive": player_alive,
		"enemy_alive": enemy_alive,
		"attacks_in_window": _attacks_in_window,
		"deaths_in_window": _deaths_in_window,
		"retargets_in_window": _retargets_in_window,
		"heartbeat": heartbeat,
	}
	_debug_helper.call("set_latest_watchdog_snapshot", snapshot)
	_debug_helper.call(
		"log_once_per_interval",
		"crowd_watchdog_stall",
		2.5,
		"[Crowd] watchdog stall alive P:%d E:%d attacks:%d stuck P:%d E:%d" % [
			player_alive,
			enemy_alive,
			_attacks_in_window,
			int(heartbeat.get("player_stuck", 0)),
			int(heartbeat.get("enemy_stuck", 0)),
		],
		BattleDebugScript.LogLevel.COMBAT,
		_elapsed_time
	)
	_watchdog_timer = 0.0


func _on_retargeted() -> void:
	_retargets_in_window += 1
	if _debug_helper != null:
		_debug_helper.call("record_retarget")


func _check_battle_end() -> void:
	var player_alive := get_living_soldiers(TEAM_PLAYER)
	var enemy_alive := get_living_soldiers(TEAM_ENEMY)
	
	if player_alive.is_empty() and enemy_alive.is_empty():
		# Draw - no winner
		_active = false
		battle_ended.emit(-1)
	elif player_alive.is_empty():
		_active = false
		battle_ended.emit(TEAM_ENEMY)
	elif enemy_alive.is_empty():
		_active = false
		battle_ended.emit(TEAM_PLAYER)
