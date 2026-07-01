extends "res://scripts/mob/states/MobState.gd"

func enter() -> void:
    var dragon := _get_dragon()
    if dragon == null:
        if state_machine:
            state_machine.change_state("MobMoveState")
        return

    dragon.velocity = Vector2.ZERO
    dragon.call("set_facing_dir_x", -1.0)
    dragon.call("play_dragon_fly_anim")
    dragon.call("start_continuous_flight_fire")

func update(delta: float) -> void:
    var dragon := _get_dragon()
    if dragon == null or not state_machine:
        return

    if "is_dead" in dragon and bool(dragon.is_dead):
        state_machine.change_state("MobDeathState")
        return

    if bool(dragon.call("is_outside_left_map_for_flight")):
        state_machine.change_state("DragonFlyReturnState")

func physics_update(delta: float) -> void:
    var dragon := _get_dragon()
    if dragon == null:
        return

    var pos := dragon.global_position
    pos.x -= float(dragon.call("get_fly_speed")) * delta
    var peak: Vector2 = dragon.call("get_flight_peak_position")
    pos.y = peak.y
    dragon.global_position = pos

func exit() -> void:
    var dragon := _get_dragon()
    if dragon:
        dragon.call("stop_continuous_flight_fire")
        dragon.velocity = Vector2.ZERO

func _get_dragon() -> Node2D:
    if mob == null:
        return null
    if not mob.has_method("spawn_fire_from_dragon"):
        return null
    return mob
