extends RefCounted
class_name MobCombat

## Combat module for Mob
## Handles all combat-related logic

var mob: Mob
var aggro_area: Area2D
var attack_component: Node

@export var attack_range: float = 50.0
@export var aggro_range: float = 200.0
@export var mob_damage: float = 1.0

var _combat_target: Node2D = null
var _total_damage_dealt: float = 0.0

# Distance-based attack state
var _is_attacking: bool = false
var _current_attack_target: Node2D = null
var _hit_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var hit_delay: float = 0.75  ## Damage applied at 0.75s into 1.0s attack (near end of animation)
var attack_cooldown: float = 1.0

func setup(mob_ref: Mob, aggro_area_ref: Area2D, attack_comp_ref: Node) -> void:
    mob = mob_ref
    aggro_area = aggro_area_ref
    attack_component = attack_comp_ref
    
    if attack_component:
        attack_component.use_animation_hit_window = true
        if attack_component.has_signal("hit_landed") and not attack_component.hit_landed.is_connected(_on_hit_landed):
            attack_component.hit_landed.connect(_on_hit_landed)

func set_attack_range(range_value: float) -> void:
    attack_range = range_value

func find_nearest_hero() -> Node2D:
    if aggro_area and aggro_area.has_method("get_best_target"):
        var target = aggro_area.get_best_target(mob.global_position)
        if target and is_instance_valid(target):
            return target
    return null

var _last_target_log_time: float = 0.0

func update_combat_target() -> Node2D:
    if mob.is_dead or not aggro_area:
        _combat_target = null
        return null
    
    # If current target is invalid or dead, clear it
    if _combat_target and (not is_instance_valid(_combat_target) or (_combat_target.has_method("get_current_hp") and _combat_target.get_current_hp() <= 0)):
        _combat_target = null
    
    # Return current target if still valid and within aggro range
    if _combat_target:
        var distance = mob.global_position.distance_to(_combat_target.global_position)
        if distance <= aggro_range * 1.5: # Keep target if within extended aggro range
            return _combat_target
        else:
            _combat_target = null # Target out of extended aggro range
    
    # Otherwise find nearest
    _combat_target = aggro_area.get_best_target(mob.global_position)
    
    # Throttled debug log (once per second)
    var now := Time.get_ticks_msec() / 1000.0
    if now - _last_target_log_time > 1.0:
        _last_target_log_time = now
        var target_name := "null"
        if _combat_target and is_instance_valid(_combat_target):
            target_name = _combat_target.name
        var aggro_has_targets := false
        if aggro_area and aggro_area.has_method("has_targets"):
            aggro_has_targets = aggro_area.has_targets()
        # print("[MobCombat] %s: target=%s, aggro_has_targets=%s" % [mob.name, target_name, aggro_has_targets])
    
    return _combat_target

func get_combat_target() -> Node2D:
    return _combat_target

func clear_combat_target() -> void:
    _combat_target = null

func is_in_attack_range(target: Node2D = null) -> bool:
    var check_target = target if target else _combat_target
    
    if check_target == null or not is_instance_valid(check_target):
        return false
    
    var distance = mob.global_position.distance_to(check_target.global_position)
    var range_check = attack_range
    
    if mob._state_machine and mob._state_machine.current_state and mob._state_machine.current_state.name == "MobAttackState":
        range_check *= 1.2
    
    return distance <= range_check

func start_attack(target: Node2D = null) -> void:
    var attack_target = target if target else _combat_target
    
    if not attack_target or not is_instance_valid(attack_target):
        return
    
    # SIMPLIFIED: Direct damage after hit_delay, no collision needed
    if _is_attacking:
        return
    
    _is_attacking = true
    _current_attack_target = attack_target
    _hit_timer = hit_delay
    
    # Play attack animation (handled by MobAttackState)
    # Damage will be applied in update() after hit_delay

func is_attacking() -> bool:
    return _is_attacking

func update(delta: float) -> void:
    # Cooldown timer
    if _attack_cooldown_timer > 0:
        _attack_cooldown_timer -= delta
    
    # Hit timer - track attack state (damage applied by MobAttackState)
    if _is_attacking and _hit_timer > 0:
        _hit_timer -= delta
        if _hit_timer <= 0:
            # Damage is now applied by MobAttackState._apply_damage() to prevent duplicates
            _is_attacking = false
            _attack_cooldown_timer = attack_cooldown

func can_start_attack() -> bool:
    return not _is_attacking and _attack_cooldown_timer <= 0

func _apply_damage() -> void:
    if _current_attack_target == null or not is_instance_valid(_current_attack_target):
        return
    if _is_target_dead(_current_attack_target):
        return
    
    if _current_attack_target.has_method("take_damage"):
        _current_attack_target.take_damage(int(mob_damage))
        _total_damage_dealt += mob_damage
        # print("[MobCombat] %s dealt %d damage to %s" % [mob.name, int(mob_damage), _current_attack_target.name])

func attack_finished() -> bool:
    return not is_attacking()

func end_attack() -> void:
    _is_attacking = false
    _current_attack_target = null
    _combat_target = null

func get_total_damage_dealt() -> float:
    return _total_damage_dealt

func record_damage_dealt(amount: float) -> void:
    _total_damage_dealt += maxf(0.0, amount)

func _on_hit_landed(amount: float) -> void:
    _total_damage_dealt += amount

func _is_target_dead(target: Node2D) -> bool:
    if target == null or not is_instance_valid(target):
        return true
    if "is_dead" in target:
        return bool(target.is_dead)
    return false
