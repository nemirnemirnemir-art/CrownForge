extends "res://scripts/mob/states/MobState.gd"

## Mob Attack State (Refactored)
## Simple loop: FREEZE → Attack → Check nearest → Repeat/Exit

var _attack_timer: float = 0.0
var _hit_applied: bool = false

func enter() -> void:
    if not mob:
        return
    
    # FREEZE: Stop all movement
    _freeze_position()
    
    # Play attack animation
    if mob.animations:
        mob.animations.play_attack()
    
    # Get target and start attack
    var target = mob.combat.get_combat_target() if mob.combat else null
    if not _is_valid_target(target):
        _find_next_target_or_exit()
        return
    
    _start_attack(target)

func update(delta: float) -> void:
    if not mob or not state_machine:
        return
    
    # Check death
    if mob.is_dead:
        state_machine.change_state("MobDeathState")
        return
    
    # IMMEDIATE CHECK: if target is dead/invalid, look for new one NOW
    var target = mob.combat.get_combat_target() if mob.combat else null
    if not _is_valid_target(target):
        _on_attack_finished()
        return
    
    # Keep frozen
    _freeze_position()
    
    # Attack timer
    _attack_timer -= delta
    
    # Apply damage at hit point
    var hit_delay: float = 0.4
    var cooldown: float = 1.0
    if mob.combat:
        hit_delay = float(mob.combat.hit_delay)
        cooldown = float(mob.combat.attack_cooldown)
    
    if not _hit_applied and _attack_timer <= (cooldown - hit_delay):
        _hit_applied = true
        _apply_damage()
        
        # IMMEDIATE CHECK: if target died from our hit, don't wait for cooldown
        target = mob.combat.get_combat_target() if mob.combat else null
        if not _is_valid_target(target):
            _on_attack_finished()
            return
    
    # Attack finished
    if _attack_timer <= 0:
        _on_attack_finished()

func physics_update(_delta: float) -> void:
    # NEVER move while attacking
    _freeze_position()

func exit() -> void:
    if mob and mob.combat:
        mob.combat.end_attack()

# ============ PRIVATE METHODS ============

func _freeze_position() -> void:
    mob.velocity = Vector2.ZERO

func _start_attack(target: Node2D) -> void:
    var cooldown: float = 1.0
    if mob.combat:
        cooldown = float(mob.combat.attack_cooldown)
    _attack_timer = cooldown
    _hit_applied = false
    
    # Face target - use flip_h on sprite instead of scale to avoid flickering
    var direction_x = target.global_position.x - mob.global_position.x
    if abs(direction_x) > 0.3:
        var should_flip = mob.get_should_flip_for_direction(direction_x)
        if mob.anim_walk:
            mob.anim_walk.flip_h = should_flip
        if mob.anim_attack:
            mob.anim_attack.flip_h = should_flip
        if mob.animation_sprite:
            mob.animation_sprite.flip_h = should_flip
    
    # Play animation
    if mob.animations:
        mob.animations.play_attack()

func _apply_damage() -> void:
    if not mob.combat:
        return
    
    var target = mob.combat.get_combat_target()
    if not _is_valid_target(target):
        # print("[MobAttack] %s: No valid target for damage" % mob.name)
        return
    
    # Distance check
    var dist := mob.global_position.distance_to(target.global_position)
    var attack_range: float = 25.0
    if mob.combat:
        attack_range = float(mob.combat.attack_range)
    const ATTACK_TOLERANCE: float = 20.0
    var effective_range: float = attack_range + ATTACK_TOLERANCE  # 25 + 20 = 45
    
    if dist > effective_range:
        # print("[MobAttack] %s: Target %s out of range (dist=%.1f, range=%.1f)" % [mob.name, target.name, dist, effective_range])
        return
    
    # Deal damage or Spawn Projectile
    if "projectile_scene" in mob and mob.projectile_scene:
        if is_instance_valid(target) and mob.has_method("fire_projectile"):
            mob.fire_projectile(target.global_position, target)
    else:
        # Melee: Direct damage to SINGLE target only
        var damage: float = 10.0
        if "mob_damage" in mob:
            damage = float(mob.mob_damage)
        if target.has_method("take_damage"):
            target.take_damage(int(damage))
            # print("[MobAttack] %s dealt %d melee damage to %s (dist=%.1f)" % [mob.name, int(damage), target.name, dist])

func _on_attack_finished() -> void:
    # IMMEDIATE target check after attack
    _find_next_target_or_exit()

func _find_next_target_or_exit() -> void:
    # Find nearest hero using unified finder
    var search_range: float = 400.0
    var next_target = CombatTargetFinder.find_nearest(mob, "hero", search_range)
    
    if next_target and is_instance_valid(next_target):
        if mob.combat:
            mob.combat._combat_target = next_target
        
        # Check if in attack range (HitBox tolerance + Buffer)
        var dist := mob.global_position.distance_to(next_target.global_position)
        var attack_range: float = 25.0
        if mob.combat:
            attack_range = float(mob.combat.attack_range)
        const ATTACK_TOLERANCE: float = 20.0
        var effective_range = attack_range + ATTACK_TOLERANCE  # 25 + 20 = 45

        if dist <= effective_range:
            # Stay and attack
            _start_attack(next_target)
        else:
            # Move to target
            state_machine.change_state("MobMoveState")
    else:
        # No heroes - go back to moving (toward wall)
        if mob.combat:
            mob.combat.clear_combat_target()
        state_machine.change_state("MobMoveState")

func _is_valid_target(target) -> bool:
    if target == null or not is_instance_valid(target):
        return false
    if "is_dead" in target and bool(target.is_dead):
        return false
    return true
