extends "res://scripts/mob/states/MobState.gd"

var _time_left: float = 2.0
var _spawn_done: bool = false

func enter() -> void:
    if not mob:
        return

    mob.velocity = Vector2.ZERO
    _spawn_done = false
    if mob.has_method("get_point_duration"):
        _time_left = mob.get_point_duration()
    else:
        _time_left = 2.0

    if mob.has_method("reset_point_cd"):
        mob.reset_point_cd()
    if mob.has_method("play_boss_anim"):
        mob.play_boss_anim("point")

func update(delta: float) -> void:
    if not mob or not state_machine:
        return
    if mob.is_dead:
        state_machine.change_state("MobDeathState")
        return

    mob.velocity = Vector2.ZERO
    var total_duration: float = 2.0
    if mob.has_method("get_point_duration"):
        total_duration = float(mob.get_point_duration())

    if not _spawn_done and _time_left <= maxf(0.1, total_duration - 0.35):
        _spawn_done = true
        if mob.has_method("spawn_gnoll_pack"):
            mob.spawn_gnoll_pack()

    _time_left -= delta
    if _time_left <= 0.0:
        state_machine.change_state("MinotaurWalkState")

func physics_update(_delta: float) -> void:
    if mob:
        mob.velocity = Vector2.ZERO

func exit() -> void:
    if not _spawn_done and mob and not mob.is_dead and mob.has_method("spawn_gnoll_pack"):
        mob.spawn_gnoll_pack()
