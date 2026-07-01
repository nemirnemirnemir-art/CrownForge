extends Node2D
class_name Corpse

## Corpse left behind when units die (50% chance)
## Lasts 3 minutes, plays disappear animation if timer expires
## Used by Necromancy spell - instant removal without animation

@onready var animation_player: AnimatedSprite2D = $AnimatedSprite2D

const CORPSE_LIFETIME: float = 180.0  # 3 minutes

var _lifetime_remaining: float = CORPSE_LIFETIME
var _is_being_consumed: bool = false  # Set to true when used by Necromancy

# Static list of all active corpses for Necromancy spell
static var active_corpses: Array[Corpse] = []

func _ready() -> void:
    add_to_group("corpse")
    active_corpses.append(self)
    
    # Play default (static) animation
    if animation_player:
        animation_player.play("default")

func _exit_tree() -> void:
    # Remove from static list
    var idx = active_corpses.find(self)
    if idx >= 0:
        active_corpses.remove_at(idx)

func _process(delta: float) -> void:
    if _is_being_consumed:
        return
    
    _lifetime_remaining -= delta
    
    if _lifetime_remaining <= 0.0:
        _play_disappear_animation()

func _play_disappear_animation() -> void:
    _is_being_consumed = true
    
    if animation_player and animation_player.sprite_frames.has_animation("decay"):
        animation_player.play("decay")
        await animation_player.animation_finished
    
    queue_free()

## Called by Necromancy spell - instant removal without animation
func consume_for_necromancy() -> void:
    if _is_being_consumed:
        return
    _is_being_consumed = true
    queue_free()

## Static helper to get up to N corpses for Necromancy
static func get_corpses_for_spell(count: int) -> Array[Corpse]:
    var result: Array[Corpse] = []
    
    # Clean up invalid references
    for i in range(active_corpses.size() - 1, -1, -1):
        if not is_instance_valid(active_corpses[i]):
            active_corpses.remove_at(i)
    
    # Get up to 'count' corpses
    for i in range(min(count, active_corpses.size())):
        result.append(active_corpses[i])
    
    return result

## Static helper to spawn corpse at position (50% chance)
static func try_spawn_at(parent: Node, position: Vector2) -> Corpse:
    # 50% chance to spawn
    if randf() > 0.5:
        # print("[Corpse] Spawn failed - 50%% chance roll missed")
        return null
    
    if not parent or not is_instance_valid(parent):
        push_error("[Corpse] Cannot spawn - parent is null or invalid!")
        return null
    
    # Randomly select corpse type (1-3)
    var corpse_type: int = randi_range(1, 3)
    var corpse_scene: PackedScene
    
    match corpse_type:
        1:
            corpse_scene = preload("res://scenes/effects/Corpse1.tscn")
        2:
            corpse_scene = preload("res://scenes/effects/Corpse2.tscn")
        3:
            corpse_scene = preload("res://scenes/effects/Corpse3.tscn")
        _:
            corpse_scene = preload("res://scenes/effects/Corpse1.tscn")
    
    # print("[Corpse] Spawning corpse type %d at %s" % [corpse_type, position])
    var corpse: Corpse = corpse_scene.instantiate()
    parent.add_child(corpse)
    corpse.global_position = position
    # print("[Corpse] ✅ Corpse added to scene tree")
    return corpse
