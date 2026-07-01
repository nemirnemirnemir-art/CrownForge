extends RefCounted
class_name TenKingsBattleDebug

enum LogLevel {
	OFF,
	ERRORS,
	SUMMARY,
	COMBAT,
	VERBOSE,
}

var log_level: LogLevel = LogLevel.SUMMARY
var battle_enabled: bool = true
var crowd_enabled: bool = true
var geometry_enabled: bool = true
var targeting_enabled: bool = true
var watchdog_enabled: bool = true

var _last_log_times: Dictionary = {}
var _battle_start_summary: Dictionary = {}
var _latest_heartbeat_snapshot: Dictionary = {}
var _latest_watchdog_snapshot: Dictionary = {}
var _counters: Dictionary = {
	"attacks": 0,
	"deaths": 0,
	"retargets": 0,
	"castle_attacks_player": 0,
	"castle_attacks_enemy": 0,
	"tower_attacks_player": 0,
	"tower_attacks_enemy": 0,
	"castle_damage_player": 0,
	"castle_damage_enemy": 0,
	"splash_inner_hits": 0,
	"splash_middle_hits": 0,
	"splash_outer_hits": 0,
}


func reset() -> void:
	_last_log_times.clear()
	_battle_start_summary.clear()
	_latest_heartbeat_snapshot.clear()
	_latest_watchdog_snapshot.clear()
	_counters["attacks"] = 0
	_counters["deaths"] = 0
	_counters["retargets"] = 0
	_counters["castle_attacks_player"] = 0
	_counters["castle_attacks_enemy"] = 0
	_counters["tower_attacks_player"] = 0
	_counters["tower_attacks_enemy"] = 0
	_counters["castle_damage_player"] = 0
	_counters["castle_damage_enemy"] = 0
	_counters["splash_inner_hits"] = 0
	_counters["splash_middle_hits"] = 0
	_counters["splash_outer_hits"] = 0


func log_once_per_interval(key: String, interval_sec: float, message: String, level: LogLevel, now_sec: float) -> void:
	if level > log_level or log_level == LogLevel.OFF:
		return
	var last_time: float = float(_last_log_times.get(key, -INF))
	if now_sec - last_time < interval_sec:
		return
	_last_log_times[key] = now_sec
	print("[TenKingsDebug] %s" % message)


func set_battle_start_summary(summary: Dictionary) -> void:
	_battle_start_summary = summary.duplicate(true)


func get_battle_start_summary() -> Dictionary:
	return _battle_start_summary.duplicate(true)


func set_latest_heartbeat_snapshot(snapshot: Dictionary) -> void:
	_latest_heartbeat_snapshot = snapshot.duplicate(true)


func get_latest_heartbeat_snapshot() -> Dictionary:
	return _latest_heartbeat_snapshot.duplicate(true)


func set_latest_watchdog_snapshot(snapshot: Dictionary) -> void:
	_latest_watchdog_snapshot = snapshot.duplicate(true)


func get_latest_watchdog_snapshot() -> Dictionary:
	return _latest_watchdog_snapshot.duplicate(true)


func record_attack() -> void:
	_counters["attacks"] = int(_counters.get("attacks", 0)) + 1


func record_death() -> void:
	_counters["deaths"] = int(_counters.get("deaths", 0)) + 1


func record_retarget() -> void:
	_counters["retargets"] = int(_counters.get("retargets", 0)) + 1


## Record a castle attack (specify "player" or "enemy")
func record_castle_attack(target: String) -> void:
	var key = "castle_attacks_" + target.to_lower()
	_counters[key] = int(_counters.get(key, 0)) + 1


## Record a tower attack (specify "player" or "enemy")
func record_tower_attack(target: String) -> void:
	var key = "tower_attacks_" + target.to_lower()
	_counters[key] = int(_counters.get(key, 0)) + 1


## Record castle damage (specify "player" or "enemy" as target, and damage amount)
func record_castle_damage(target: String, damage: int) -> void:
	var key = "castle_damage_" + target.to_lower()
	_counters[key] = int(_counters.get(key, 0)) + damage


## Record splash damage hit (inner, middle, or outer zone)
func record_splash_hit(zone: String) -> void:
	var key = "splash_" + zone.to_lower() + "_hits"
	if _counters.has(key):
		_counters[key] = int(_counters.get(key, 0)) + 1


func get_counters() -> Dictionary:
	return _counters.duplicate(true)
