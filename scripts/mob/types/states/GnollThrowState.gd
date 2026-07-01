extends "res://scripts/mob/states/MobState.gd"

var _time_left: float = 1.0
var _hit_done: bool = false
var _queued_hit_state: bool = false

func enter() -> void:
    if not mob:
        return
    mob.velocity = Vector2.ZERO
    _hit_done = false
    _queued_hit_state = false
    if mob.has_method("get_throw_duration"):
        _time_left = mob.get_throw_duration()
    else:
        _time_left = 1.0
    if mob.has_method("play_gnoll_anim"):
        mob.play_gnoll_anim("throw")

    var target := _resolve_target()
    if target and mob.has_method("face_target_x"):
        mob.face_target_x(target.global_position.x)

func update(delta: float) -> void:
    if not mob or not state_machine:
        return
    if mob.is_dead:
        state_machine.change_state("MobDeathState")
        return

    mob.velocity = Vector2.ZERO
    _time_left -= delta

    var throw_duration := 1.0
    var hit_delay := 0.45
    if mob.has_method("get_throw_duration"):
        throw_duration = mob.get_throw_duration()
    if mob.has_method("get_throw_hit_delay"):
        hit_delay = mob.get_throw_hit_delay()

    if not _hit_done and _time_left <= (throw_duration - hit_delay):
        _hit_done = true
        _apply_throw()

    if _hit_done and mob.has_method("has_pending_hit_reaction") and mob.has_pending_hit_reaction():
        _queued_hit_state = true

    if _time_left <= 0.0:
        if _queued_hit_state and mob.has_method("consume_hit_reaction") and mob.consume_hit_reaction():
            state_machine.change_state("GnollHitState")
            return
        if mob.has_method("roll_post_throw_idle") and mob.roll_post_throw_idle():
            if mob.has_method("set_idle_request"):
                mob.set_idle_request(2.0)
            state_machine.change_state("GnollIdleState")
            return
        state_machine.change_state("GnollWalkState")

func physics_update(_delta: float) -> void:
    if mob:
        mob.velocity = Vector2.ZERO

func _apply_throw() -> void:
    var target := _resolve_target()
    if target == null:
        return

    if mob.has_method("face_target_x"):
        mob.face_target_x(target.global_position.x)

    if mob.has_method("fire_projectile"):
        mob.fire_projectile(target.global_position)

func _resolve_target() -> Node2D:
    var target: Node2D = null
    if mob.combat and mob.combat.has_method("get_combat_target"):
        var raw_target = mob.combat.get_combat_target()
        if raw_target != null and is_instance_valid(raw_target) and not _is_dead_target(raw_target):
            target = raw_target
    if target:
        return target

    target = CombatTargetFinder.find_nearest(mob, "hero", float(mob.aggro_range))
    if target and is_instance_valid(target):
        if mob.combat:
            mob.combat._combat_target = target
        return target
    return null

func _is_dead_target(target: Node2D) -> bool:
    if target == null or not is_instance_valid(target):
        return true
    if "is_dead" in target and bool(target.is_dead):
        return true
    return false
