extends RefCounted
class_name MobVisuals

## Handles visual effects (dust, fade in, etc.) for Mob

const SpawnDustScene = preload("res://scenes/effects/SpawnDustEffect.tscn")

var mob: Node2D

func setup(mob_ref: Node2D) -> void:
    mob = mob_ref

func play_spawn_effects() -> void:
    mob.call_deferred("_spawn_dust")
    
    mob.modulate.a = 0.0
    var tween = mob.create_tween()
    tween.tween_property(mob, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _spawn_dust() -> void:
    if SpawnDustScene:
        var dust: Node2D = SpawnDustScene.instantiate() as Node2D
        if dust == null:
            return
            
        dust.z_index = mob.z_index + 1
        var parent = mob.get_parent()
        if parent:
            parent.add_child(dust)
            dust.global_position = mob.global_position
