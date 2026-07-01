extends "res://scripts/mob/states/MobState.gd"

## Simple Mob Attack State
## Uses distance-based combat - no collision detection

var _combat: SimpleCombat = null

func enter() -> void:
	if not mob:
		return
	
	# Stop movement
	if mob.navigation:
		mob.navigation.stop_movement()
	
	# Play attack animation
	if mob.animations:
		mob.animations.play_attack()
	
	# Initialize combat
	if _combat == null:
		_combat = SimpleCombat.new(mob)
		var attack_range = mob.attack_range if "attack_range" in mob else 60.0
		var damage = mob.mob_damage if "mob_damage" in mob else 10.0
		var cooldown = mob.attack_cooldown if "attack_cooldown" in mob else 1.0
		_combat.setup(attack_range, damage, cooldown, 0.4)
	
	# Start attack
	var target = _get_target()
	if target and _combat.is_in_range(target) and _combat.can_attack():
		_combat.start_attack(target)

func update(delta: float) -> void:
	if not mob or not state_machine:
		return
	
	if mob.is_dead:
		state_machine.change_state("MobDeathState")
		return
	
	if not _combat:
		state_machine.change_state("MobMoveState")
		return
	
	_combat.update(delta)
	
	var target = _get_target()
	
	# No target
	if target == null or not is_instance_valid(target):
		state_machine.change_state("MobMoveState")
		return
	
	# Target dead
	if "is_dead" in target and bool(target.is_dead):
		state_machine.change_state("MobMoveState")
		return
	
	# Attack finished
	if not _combat.is_attacking():
		if _combat.is_in_range(target):
			if _combat.can_attack():
				# Update damage (may change with buffs)
				_combat.attack_damage = mob.mob_damage if "mob_damage" in mob else 10.0
				_combat.start_attack(target)
				if mob.animations:
					mob.animations.play_attack()
		else:
			# Target moved away
			state_machine.change_state("MobMovingToHeroState")
	
	# Face target
	_face_target(target)

func physics_update(_delta: float) -> void:
	# No movement while attacking
	pass

func exit() -> void:
	if _combat:
		_combat.cancel_attack()

func _get_target() -> Node2D:
	if mob.combat and mob.combat.has_method("get_combat_target"):
		return mob.combat.get_combat_target()
	if mob._aggro_area and mob._aggro_area.has_method("get_best_target"):
		return mob._aggro_area.get_best_target(mob.global_position)
	return null

func _face_target(target: Node2D) -> void:
	if target.global_position.x < mob.global_position.x:
		mob._set_sprites_flip(true)
	else:
		mob._set_sprites_flip(false)
