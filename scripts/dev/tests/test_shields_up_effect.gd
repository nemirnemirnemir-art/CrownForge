extends SceneTree

const ShieldsUpEffectScene := preload("res://scenes/spells/effects/ShieldsUpEffect.tscn")
const ShieldsUpConfig := preload("res://resources/spells/configs/shields_up.tres")


class DummyAlly:
    extends Node2D

    var damage_taken_multiplier: float = 1.0
    var speed_multiplier: float = 1.0


func _init() -> void:
    var root := Node2D.new()
    get_root().add_child(root)
    call_deferred("_run_test", root)


func _run_test(root: Node2D) -> void:
    var ally := DummyAlly.new()
    ally.global_position = Vector2(0.0, 0.0)
    ally.add_to_group("hero")
    root.add_child(ally)

    await process_frame
    await process_frame

    var effect := ShieldsUpEffectScene.instantiate() as SpellEffect
    if effect == null:
        push_error("[test_shields_up_effect] failed to instantiate ShieldsUpEffect")
        quit(1)
        return

    var cfg := ShieldsUpConfig.duplicate() as SpellConfig
    if cfg == null:
        push_error("[test_shields_up_effect] failed to duplicate shields_up config")
        quit(1)
        return
    cfg.duration = 0.05
    cfg.target_radius = 90.0

    var before_damage_taken := ally.damage_taken_multiplier
    var before_speed := ally.speed_multiplier
    if abs(before_damage_taken - 1.0) > 0.001 or abs(before_speed - 1.0) > 0.001:
        push_error("[test_shields_up_effect] expected baseline multipliers to be 1.0")
        quit(1)
        return

    root.add_child(effect)
    effect.initialize(cfg, Vector2(0.0, 0.0))

    await process_frame
    await process_frame

    var buffed_damage_taken := ally.damage_taken_multiplier
    if abs(buffed_damage_taken - 0.7) > 0.001:
        push_error("[test_shields_up_effect] expected damage_taken_multiplier=0.7, got %.3f" % buffed_damage_taken)
        quit(1)
        return

    var buffed_speed := ally.speed_multiplier
    if abs(buffed_speed - 0.85) > 0.001:
        push_error("[test_shields_up_effect] expected speed_multiplier=0.85, got %.3f" % buffed_speed)
        quit(1)
        return

    await create_timer(0.08).timeout

    var restored_damage_taken := ally.damage_taken_multiplier
    if abs(restored_damage_taken - 1.0) > 0.001:
        push_error("[test_shields_up_effect] damage_taken_multiplier must reset to 1.0, got %.3f" % restored_damage_taken)
        quit(1)
        return

    var restored_speed := ally.speed_multiplier
    if abs(restored_speed - 1.0) > 0.001:
        push_error("[test_shields_up_effect] speed_multiplier must reset to 1.0, got %.3f" % restored_speed)
        quit(1)
        return

    print("[test_shields_up_effect] PASS")
    quit(0)
