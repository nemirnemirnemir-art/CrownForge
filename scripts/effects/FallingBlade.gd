extends Node2D

## Single falling blade - falls from sky, deals damage on impact

@onready var blade_anim: AnimatedSprite2D = $BladeAnim
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

const FALL_TEXTURE_PATH: String = "res://assets/vfx/spells_visuals/Bladefall.png"
const FALL_DISTANCE_PX: float = 420.0
const OFFSCREEN_MARGIN_PX: float = 100.0
const DEFAULT_FALL_TIME: float = 0.18
const ANIM_FALL: StringName = &"fall"
const ANIM_IMPACT: StringName = &"impact"

static var _cached_frames: SpriteFrames = null

var _damage: float = 60.0
var _delay: float = 2.0
var _activated: bool = false
var _damaged_enemies: Dictionary = {}
var _target: Node2D = null

func setup(damage: float, delay: float, target: Node2D = null) -> void:
    _damage = damage
    _delay = delay if delay > 0.0 else DEFAULT_FALL_TIME
    _target = target

    if blade_anim:
        blade_anim.sprite_frames = _get_or_create_frames()
        if blade_anim.sprite_frames and blade_anim.sprite_frames.has_animation(ANIM_FALL):
            blade_anim.play(ANIM_FALL)
    
    # Setup collision shape
    if damage_shape:
        var shape := RectangleShape2D.new()
        shape.size = Vector2(50, 30)
        damage_shape.shape = shape
        damage_shape.set_deferred("disabled", true)

    var impact_pos := global_position
    var fall_distance := maxf(FALL_DISTANCE_PX, _get_viewport_height() + OFFSCREEN_MARGIN_PX)
    global_position = impact_pos + Vector2(0.0, -fall_distance)

    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_IN)
    tween.tween_property(self, "global_position", impact_pos, _delay)
    await tween.finished
    _activate()

func _activate() -> void:
    _activated = true
    
    # Enable collision for brief moment
    if damage_shape:
        damage_shape.set_deferred("disabled", false)
    
    # Impact animation
    if blade_anim and blade_anim.sprite_frames and blade_anim.sprite_frames.has_animation(ANIM_IMPACT):
        blade_anim.play(ANIM_IMPACT)
    
    # Wait two frames for physics engine to register overlaps
    await get_tree().process_frame
    await get_tree().physics_frame
    await get_tree().physics_frame
    
    if _target and is_instance_valid(_target):
        var hb0 := _target.get_node_or_null("Hurtbox")
        if hb0 and hb0.has_method("apply_hit"):
            hb0.apply_hit(_damage, self, Time.get_ticks_msec() + get_instance_id())
        elif _target.has_method("take_damage"):
            _target.take_damage(_damage)
    else:
        _deal_damage()
    
    # Disable collision
    if damage_shape:
        damage_shape.set_deferred("disabled", true)
    await get_tree().create_timer(0.6).timeout
    queue_free()

func _get_viewport_height() -> float:
    var viewport := get_viewport()
    if viewport:
        return viewport.get_visible_rect().size.y
    return FALL_DISTANCE_PX

func _get_or_create_frames() -> SpriteFrames:
    if _cached_frames != null:
        return _cached_frames

    var frames := SpriteFrames.new()
    if not frames.has_animation(ANIM_FALL):
        frames.add_animation(ANIM_FALL)
    frames.set_animation_loop(ANIM_FALL, true)
    frames.set_animation_speed(ANIM_FALL, 24.0)

    if not frames.has_animation(ANIM_IMPACT):
        frames.add_animation(ANIM_IMPACT)
    frames.set_animation_loop(ANIM_IMPACT, false)
    frames.set_animation_speed(ANIM_IMPACT, 12.0)

    var tex := load(FALL_TEXTURE_PATH) as Texture2D
    if tex != null:
        frames.add_frame(ANIM_FALL, tex)
        frames.add_frame(ANIM_IMPACT, tex)

    _cached_frames = frames
    return _cached_frames

func _deal_damage() -> void:
    if not damage_area:
        return

    var targets: Array[Node2D] = []
    for body_any in damage_area.get_overlapping_bodies():
        if body_any is Node2D:
            targets.append(body_any as Node2D)

    if targets.is_empty():
        targets = _collect_fallback_targets()

    for body in targets:
        if _damaged_enemies.has(body):
            continue
        
        if not body.is_in_group("enemy") and not body.is_in_group("mobs"):
            continue

        var hurtbox = body.get_node_or_null("Hurtbox")
        if hurtbox and hurtbox.has_method("apply_hit"):
            var attack_id: int = Time.get_ticks_msec() + get_instance_id()
            hurtbox.apply_hit(_damage, self, attack_id)
            _damaged_enemies[body] = true
            continue

        if body.has_method("take_damage"):
            body.take_damage(_damage)
            _damaged_enemies[body] = true

func _collect_fallback_targets() -> Array[Node2D]:
    var result: Array[Node2D] = []
    var tree := get_tree()
    if tree == null:
        return result

    var candidates: Array = tree.get_nodes_in_group("enemy")
    candidates.append_array(tree.get_nodes_in_group("mobs"))
    candidates.append_array(tree.get_nodes_in_group("enemies"))

    for candidate in candidates:
        if not (candidate is Node2D):
            continue
        var enemy := candidate as Node2D
        if not is_instance_valid(enemy):
            continue
        if absf(enemy.global_position.x - global_position.x) > 36.0:
            continue
        if absf(enemy.global_position.y - global_position.y) > 40.0:
            continue
        result.append(enemy)

    return result
