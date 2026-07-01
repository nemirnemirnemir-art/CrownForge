extends "res://scripts/mob/states/MobState.gd"

const CombatTargetFinderScript = preload("res://scripts/combat/CombatTargetFinder.gd")

const STUN_DURATION: float = 3.0
const KNOCKBACK_FORCE: float = 180.0
const KNOCKBACK_DURATION: float = 0.2

var _sprite: AnimatedSprite2D = null
var _hit_done: bool = false
var _fallback_left: float = 0.0
var _debug_combo_started_at: float = 0.0
var _debug_moves_done: int = 0
var _frame_from: int = 0
var _frame_to: int = 0
var _frame_span: int = 1
var _moves_max: int = 1
var _combo_dir_x: float = 1.0

func enter() -> void:
    if not mob or not state_machine:
        return
    mob.velocity = Vector2.ZERO

    if mob.has_method("consume_combo_dir_x"):
        _combo_dir_x = float(mob.consume_combo_dir_x())
    elif mob.has_method("get_facing_dir_x"):
        _combo_dir_x = float(mob.get_facing_dir_x())
    else:
        _combo_dir_x = 1.0
    if mob.has_method("set_facing_dir_x"):
        mob.set_facing_dir_x(_combo_dir_x)

    _hit_done = false
    _fallback_left = 2.0
    _debug_combo_started_at = Time.get_ticks_msec() / 1000.0
    _debug_moves_done = 0
    _frame_from = int(mob.combo_shift_frame_from) if ("combo_shift_frame_from" in mob) else 0
    _frame_to = int(mob.combo_shift_frame_to) if ("combo_shift_frame_to" in mob) else _frame_from
    _frame_span = 1
    _moves_max = 1
    if mob.has_method("reset_combo_cd"):
        mob.reset_combo_cd()
    if mob.has_method("play_boss_anim"):
        mob.play_boss_anim("combo")
    _sprite = mob.get_node_or_null("AnimationSprite2D") as AnimatedSprite2D
    if _sprite:
        if _sprite.sprite_frames and _sprite.sprite_frames.has_animation("combo"):
            var fc: int = _sprite.sprite_frames.get_frame_count("combo")
            var sp: float = float(_sprite.sprite_frames.get_animation_speed("combo"))
            if sp <= 0.01:
                sp = 8.0
            _fallback_left = maxf(0.6, float(fc) / sp + 0.25)
            _configure_combo_window(fc)
            var window_len: int = maxi(0, _frame_to - _frame_from + 1)
            _combo_debug("enter: frames=%d speed=%.2f fallback=%.2f from=%d to=%d window=%d span=%d moves=%d" % [fc, sp, _fallback_left, _frame_from, _frame_to, window_len, _frame_span, _moves_max])
            if _sprite.sprite_frames.has_method("get_animation_loop") and bool(_sprite.sprite_frames.get_animation_loop("combo")):
                push_warning("[HomeseekerComboState] combo animation is looping; forcing fallback exit")
        if not _sprite.frame_changed.is_connected(_on_frame_changed):
            _sprite.frame_changed.connect(_on_frame_changed)
        if not _sprite.animation_finished.is_connected(_on_animation_finished):
            _sprite.animation_finished.connect(_on_animation_finished)
    if mob.has_method("request_combo_shake"):
        mob.request_combo_shake()

func update(delta: float) -> void:
    if not mob or not state_machine:
        return
    if mob.is_dead:
        state_machine.change_state("MobDeathState")
        return
    mob.velocity = Vector2.ZERO
    _fallback_left -= delta
    if _should_debug_timers():
        _combo_debug("update: fallback_left=%.3f delta=%.3f" % [_fallback_left, delta])
    if _fallback_left <= 0.0:
        _combo_debug("fallback timer expired -> recovery")
        state_machine.change_state("HomeseekerRecoveryState")

func physics_update(_delta: float) -> void:
    if mob:
        mob.velocity = Vector2.ZERO

func exit() -> void:
    if _sprite and is_instance_valid(_sprite):
        if _sprite.frame_changed.is_connected(_on_frame_changed):
            _sprite.frame_changed.disconnect(_on_frame_changed)
        if _sprite.animation_finished.is_connected(_on_animation_finished):
            _sprite.animation_finished.disconnect(_on_animation_finished)
    _combo_debug("exit after %.3fs, moves_done=%d" % [Time.get_ticks_msec() / 1000.0 - _debug_combo_started_at, _debug_moves_done])

func _on_frame_changed() -> void:
    if not mob or _sprite == null:
        return
    if _sprite.animation != "combo":
        return

    var frame_i: int = int(_sprite.frame)
    if frame_i >= _frame_from and frame_i <= _frame_to:
        var rel := frame_i - _frame_from
        if rel % _frame_span == 0:
            var step_index: int = int(floor(float(rel) / float(_frame_span)))
            if step_index < _moves_max:
                var shift_total: float = float(mob.combo_shift_px)
                if "combo_shift_multiplier" in mob:
                    shift_total *= float(mob.combo_shift_multiplier)
                var shift: float = shift_total / float(_moves_max)
                var dx: float = shift * _combo_dir_x
                if mob.has_method("apply_combo_shift"):
                    mob.apply_combo_shift(dx)
                else:
                    mob.global_position.x += dx
                _debug_moves_done += 1
                _combo_debug("move step=%d/%d frame=%d rel=%d span=%d dir=%.1f shift=%.2f pos_x=%.2f" % [step_index + 1, _moves_max, frame_i, rel, _frame_span, _combo_dir_x, shift, mob.global_position.x])
                if mob.has_method("request_combo_shake"):
                    mob.request_combo_shake()

    if not _hit_done and frame_i == _frame_from:
        _hit_done = true
        _apply_combo_effects()

func _on_animation_finished() -> void:
    if not mob or not state_machine:
        return
    if _sprite and _sprite.animation != "combo":
        return
    _combo_debug("animation_finished signal -> recovery")
    state_machine.change_state("HomeseekerRecoveryState")

func _apply_combo_effects() -> void:
    var targets := CombatTargetFinderScript.find_all_in_range(mob, "hero", 220.0)
    for h in targets:
        if h == null or not is_instance_valid(h):
            continue
        if h.has_method("apply_stun"):
            h.apply_stun(STUN_DURATION)
        _apply_knockback(h)
        _apply_tilt(h, (h.global_position - mob.global_position).normalized(), KNOCKBACK_DURATION, KNOCKBACK_DURATION * 0.9)
        _start_stun_wobble(h, STUN_DURATION)

    var damage: float = float(mob.mob_damage)
    for h2 in targets:
        if h2 == null or not is_instance_valid(h2):
            continue
        if h2.has_method("take_damage"):
            h2.take_damage(int(round(damage)))

func _apply_knockback(hero: Node2D) -> void:
    if hero == null or not is_instance_valid(hero):
        return
    var dir := (hero.global_position - mob.global_position).normalized()
    if dir == Vector2.ZERO:
        dir = Vector2.RIGHT
    var source: Vector2 = hero.global_position - dir * 10.0
    var kb_node := hero.get_node_or_null("KnockbackComponent")
    if kb_node and kb_node.has_method("apply_knockback"):
        kb_node.call("apply_knockback", source, KNOCKBACK_FORCE, KNOCKBACK_DURATION)
        return
    var target_pos := hero.global_position + dir * KNOCKBACK_FORCE
    var t := hero.create_tween()
    t.tween_property(hero, "global_position", target_pos, KNOCKBACK_DURATION)

func _apply_tilt(unit2d: Node2D, direction: Vector2, push_duration: float, settle_duration: float) -> void:
    if unit2d == null or not is_instance_valid(unit2d):
        return
    var target_node: Node = unit2d.get_node_or_null("AnimationSprite2D")
    if target_node == null:
        target_node = unit2d
    if not (target_node is Node2D):
        return
    var target2d := target_node as Node2D
    var tilt_angle := clampf(direction.x, -1.0, 1.0) * deg_to_rad(15.0)
    var squash_scale := Vector2(1.0 + abs(direction.x) * 0.12, 1.0 - 0.1)

    var tilt_tween := target2d.create_tween()
    tilt_tween.set_parallel(true)
    tilt_tween.tween_property(target2d, "rotation", tilt_angle, push_duration * 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tilt_tween.tween_property(target2d, "scale", squash_scale, push_duration * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tilt_tween.set_parallel(false)
    tilt_tween.tween_property(target2d, "rotation", 0.0, settle_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tilt_tween.tween_property(target2d, "scale", Vector2.ONE, settle_duration * 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_stun_wobble(unit2d: Node2D, duration: float) -> void:
    if unit2d == null or not is_instance_valid(unit2d):
        return
    var target_node: Node = unit2d.get_node_or_null("AnimationSprite2D")
    if target_node == null:
        target_node = unit2d
    if not (target_node is Node2D):
        return
    var target2d := target_node as Node2D

    if target2d.has_meta("_homeseeker_wobble_tween"):
        var prev: Tween = target2d.get_meta("_homeseeker_wobble_tween") as Tween
        if prev and prev is Tween and prev.is_valid():
            prev.kill()

    var amplitude: float = deg_to_rad(11.0)
    var segment: float = 0.25
    var loops: int = maxi(1, int(ceil(duration / (segment * 2.0))))
    var wobble := target2d.create_tween()
    wobble.set_trans(Tween.TRANS_SINE)
    wobble.set_ease(Tween.EASE_IN_OUT)
    for _i in range(loops):
        wobble.tween_property(target2d, "rotation", amplitude, segment)
        wobble.tween_property(target2d, "rotation", -amplitude, segment)
    wobble.tween_property(target2d, "rotation", 0.0, 0.3)
    wobble.finished.connect(func():
        if target2d.has_meta("_homeseeker_wobble_tween"):
            target2d.set_meta("_homeseeker_wobble_tween", null)
    )
    target2d.set_meta("_homeseeker_wobble_tween", wobble)

func _combo_debug(msg: String) -> void:
    if _should_debug():
        print("[HomeseekerComboState] ", msg)

func _should_debug() -> bool:
    return mob != null and "combo_debug_enabled" in mob and bool(mob.combo_debug_enabled)

func _should_debug_timers() -> bool:
    return mob != null and "combo_debug_timers" in mob and bool(mob.combo_debug_timers)

func _configure_combo_window(total_frames: int) -> void:
    _frame_span = 1
    if "combo_step_frame_span" in mob:
        _frame_span = maxi(1, int(mob.combo_step_frame_span))
    _moves_max = 1
    if "combo_step_move_count" in mob:
        _moves_max = maxi(1, int(mob.combo_step_move_count))

    var required_window: int = _frame_span * (_moves_max - 1) + 1
    var target_to: int = _frame_from + required_window - 1
    var max_frame_index: int = maxi(0, total_frames - 1)
    if target_to > max_frame_index:
        target_to = max_frame_index
    _frame_to = max(_frame_from, target_to)

    var actual_window: int = maxi(1, _frame_to - _frame_from + 1)
    var possible_moves: int = int(floor(float(actual_window - 1) / float(_frame_span))) + 1
    if possible_moves < _moves_max:
        if _should_debug():
            push_warning("[HomeseekerComboState] reducing combo steps: possible=%d requested=%d (from=%d to=%d span=%d frames=%d)" % [possible_moves, _moves_max, _frame_from, _frame_to, _frame_span, actual_window])
        _moves_max = possible_moves
