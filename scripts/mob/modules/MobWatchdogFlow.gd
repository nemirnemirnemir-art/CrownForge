extends RefCounted
class_name MobWatchdogFlow


func watchdog_tick(mob, movement, combat, state_machine, end_attack: Callable) -> void:
	if mob == null or mob.is_dead:
		return
	var state_name := "<none>"
	if state_machine and state_machine.current_state:
		state_name = state_machine.current_state.name
	if state_name == "MobDeathState" or movement == null or combat == null:
		return
	var dmg: float = combat.get_total_damage_dealt()
	var is_stuck: bool = movement.check_stuck(mob.current_health, mob._last_hp, dmg, mob._total_damage_dealt_last)
	if is_stuck:
		if end_attack.is_valid():
			end_attack.call()
		if state_machine:
			state_machine.change_state("MobMoveState")
	mob._last_hp = mob.current_health
	mob._total_damage_dealt_last = dmg


## Creates and adds a WatchdogTimer child to mob, firing callback every second.
func setup_timer(mob: Node, callback: Callable) -> void:
	var watchdog_timer := Timer.new()
	watchdog_timer.name = "WatchdogTimer"
	watchdog_timer.wait_time = 1.0
	watchdog_timer.autostart = true
	watchdog_timer.timeout.connect(callback)
	mob.add_child(watchdog_timer)
