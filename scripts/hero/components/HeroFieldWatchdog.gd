extends Node
class_name HeroFieldWatchdog

var _hero: Node2D
var _state_machine: HeroStateMachine
var _health: Node
var _combat: Node

var _last_stuck_pos: Vector2 = Vector2.ZERO
var _stuck_time: float = 0.0
var _last_hp: float = 0.0
var _total_damage_dealt_last: float = 0.0

func setup(hero: Node2D, state_machine: HeroStateMachine, health: Node, combat: Node) -> void:
	_hero = hero
	_state_machine = state_machine
	_health = health
	_combat = combat
	var watchdog_timer = Timer.new()
	watchdog_timer.name = "WatchdogTimer"
	watchdog_timer.wait_time = 1.0
	watchdog_timer.autostart = true
	watchdog_timer.timeout.connect(_on_watchdog_timer_timeout)
	add_child(watchdog_timer)
	_last_stuck_pos = _hero.global_position if _hero else Vector2.ZERO
	_last_hp = _get_current_hp()
	_total_damage_dealt_last = _get_total_damage_dealt()

func _get_current_hp() -> float:
	if _health and _health.has_method("get_current_hp"):
		return float(_health.get_current_hp())
	return 0.0

func _get_total_damage_dealt() -> float:
	if _combat and "total_damage_dealt" in _combat:
		return float(_combat.total_damage_dealt)
	return 0.0

func _on_watchdog_timer_timeout() -> void:
	if not _state_machine or not _state_machine.current_state or not _hero:
		return
	var state_name = String(_state_machine.current_state.name)
	var duration = (Time.get_ticks_msec() / 1000.0) - float(_state_machine.state_enter_time)
	var current_hp = _get_current_hp()
	var current_dmg = _get_total_damage_dealt()
	if state_name != "HeroIdleState" and state_name != "HeroSaveFromStackState":
		if duration > 10.0: # Increased from 5.0
			var moved = _hero.global_position.distance_to(_last_stuck_pos)
			var hp_changed = not is_equal_approx(current_hp, _last_hp)
			var dmg_changed = not is_equal_approx(current_dmg, _total_damage_dealt_last)
			if moved < 2.0 and not hp_changed and not dmg_changed: # Reduced moved threshold
				_stuck_time += 1.0
				if _stuck_time >= 5.0:
					_state_machine.change_state("HeroSaveFromStackState")
					_stuck_time = 0.0
			else:
				_stuck_time = 0.0
			_last_stuck_pos = _hero.global_position
			_last_hp = current_hp
			_total_damage_dealt_last = current_dmg
	if state_name == "HeroMovingState" and duration > 15.0:
		if _hero.has_method("release_current_slot"):
			_hero.release_current_slot()
		_state_machine.change_state("HeroIdleState")
	# REMOVED: elif state_name == "HeroAttackingState" and duration > 4.0:
	# This was causing heroes to stop attacking every 4 seconds for no reason.
