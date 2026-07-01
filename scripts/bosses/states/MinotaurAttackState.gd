extends "res://scripts/mob/states/MobState.gd"

var _attack_timer: float = 1.0
var _hit_applied: bool = false
var _go_idle_after_attack: bool = false

func enter() -> void:
	if not mob:
		return

	mob.velocity = Vector2.ZERO
	_go_idle_after_attack = false

	if mob.has_method("play_boss_anim"):
		mob.play_boss_anim("attack")

	var target := CombatTargetFinder.find_nearest(mob, "hero", float(mob.aggro_range))
	if target and is_instance_valid(target) and mob.combat:
		mob.combat._combat_target = target
	_start_attack(target)

func update(delta: float) -> void:
	if not mob or not state_machine:
		return
	if mob.is_dead:
		state_machine.change_state("MobDeathState")
		return

	mob.velocity = Vector2.ZERO
	_attack_timer -= delta

	var hit_delay: float = 0.45
	var cooldown: float = 1.0
	if mob.combat:
		hit_delay = float(mob.combat.hit_delay)
		cooldown = float(mob.combat.attack_cooldown)

	var target = mob.combat.get_combat_target() if mob.combat else null
	if not _is_valid_target(target):
		_find_next_target_or_exit()
		return

	if not _hit_applied and _attack_timer <= (cooldown - hit_delay):
		_hit_applied = true
		if _apply_damage(target):
			_go_idle_after_attack = true

	if _attack_timer <= 0.0:
		if _go_idle_after_attack:
			state_machine.change_state("MinotaurIdleState")
		else:
			state_machine.change_state("MinotaurWalkState")

func physics_update(_delta: float) -> void:
	if mob:
		mob.velocity = Vector2.ZERO

func exit() -> void:
	if mob and mob.combat:
		mob.combat.end_attack()

func _start_attack(target: Node2D) -> void:
	var cooldown: float = 1.0
	if mob.combat:
		cooldown = float(mob.combat.attack_cooldown)
	_attack_timer = cooldown
	_hit_applied = false
	if target and is_instance_valid(target) and mob.has_method("face_target_x"):
		mob.face_target_x(target.global_position.x)
	if mob.has_method("play_boss_anim"):
		mob.play_boss_anim("attack")

func _apply_damage(target: Node2D) -> bool:
	if not _is_valid_target(target):
		return false

	var dist := mob.global_position.distance_to(target.global_position)
	if dist > float(mob.attack_range) + 20.0:
		return false

	var damage: float = float(mob.mob_damage)
	if target.has_method("take_damage"):
		target.take_damage(int(round(damage)))

	if "is_dead" in target and bool(target.is_dead):
		if mob.has_method("request_idle_cycle_after_kill"):
			mob.request_idle_cycle_after_kill()
		return true

	return false

func _find_next_target_or_exit() -> void:
	var next_target = CombatTargetFinder.find_nearest(mob, "hero", float(mob.aggro_range))
	if next_target and is_instance_valid(next_target) and mob.combat:
		mob.combat._combat_target = next_target
		var dist := mob.global_position.distance_to(next_target.global_position)
		if dist <= float(mob.attack_range) + 20.0:
			_start_attack(next_target)
			return
	state_machine.change_state("MinotaurWalkState")

func _is_valid_target(target) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if "is_dead" in target and bool(target.is_dead):
		return false
	return true
