extends SpellEffect

## Healing Pool spell - heals allies for 70 HP per second for 3 seconds

@onready var pool_anim: AnimatedSprite2D = $PoolAnim
@onready var heal_area: Area2D = $HealArea
@onready var heal_shape: CollisionShape2D = $HealArea/CollisionShape2D

const POOL_DURATION: float = 3.0
const HEAL_PER_TICK: float = 70.0
const TICK_INTERVAL: float = 1.0
const HEAL_VFX_LIFETIME: float = 0.45

const HEAL_VFX_TEX: Texture2D = preload("res://assets/vfx/effects/Shaman_Projectile.png")
const POOL_VFX_FOLDER: String = "res://assets/vfx/spells_visuals/Healing Pool"
const POOL_VFX_ANIM: StringName = &"pool"
const POOL_VFX_FPS: float = 14.0

static var _cached_pool_frames: SpriteFrames = null

var _duration_remaining: float = POOL_DURATION
var _tick_timer: float = 0.0
var _healed_this_tick: Dictionary = {}

func execute_effect() -> void:
    if not heal_area or not heal_shape:
        push_error("[HealingPoolEffect] Missing required nodes")
        queue_free()
        return
    
    if config:
        var shape := CircleShape2D.new()
        shape.radius = config.target_radius if config.target_radius > 0 else 80.0
        heal_shape.shape = shape
    
    # Target heroes
    heal_area.monitoring = true
    heal_area.monitorable = true
    heal_area.collision_mask = 1
    
    if pool_anim:
        pool_anim.sprite_frames = _get_or_create_pool_frames()
    if pool_anim and pool_anim.sprite_frames:
        if pool_anim.sprite_frames.has_animation("heal"):
            pool_anim.play("heal")
        elif pool_anim.sprite_frames.has_animation(POOL_VFX_ANIM):
            pool_anim.play(POOL_VFX_ANIM)
        elif pool_anim.sprite_frames.has_animation("default"):
            pool_anim.play("default")

func _process(delta: float) -> void:
    _duration_remaining -= delta
    _tick_timer += delta
    
    if _tick_timer >= TICK_INTERVAL:
        _tick_timer = 0.0
        _heal_allies()
        _healed_this_tick.clear()
    
    if _duration_remaining <= 0.0:
        _fade_and_destroy()

func _heal_allies() -> void:
    if not heal_area:
        return

    var hero_core := _get_autoload("HeroCore")

    var overlaps: Array = []
    overlaps.append_array(heal_area.get_overlapping_areas())
    overlaps.append_array(heal_area.get_overlapping_bodies())

    for obj in overlaps:
        var hero := _resolve_hero_from_overlap(obj)
        if hero == null:
            continue
        if _healed_this_tick.has(hero):
            continue

        if hero.has_method("heal"):
            hero.heal(int(HEAL_PER_TICK))
            _healed_this_tick[hero] = true
        elif "hero_id" in hero and hero_core != null and hero_core.has_method("heal_hero"):
            hero_core.heal_hero(str(hero.hero_id), int(HEAL_PER_TICK))
            _healed_this_tick[hero] = true
        else:
            continue

        _spawn_heal_vfx(hero)
        if FloatingText:
            FloatingText.spawn_heal(hero.get_parent(), hero.global_position + Vector2(0, -30), int(HEAL_PER_TICK))

func _resolve_hero_from_overlap(obj: Variant) -> Node2D:
    if obj == null:
        return null
    if obj is Hurtbox:
        var owner_node := (obj as Hurtbox).get_parent()
        if owner_node is Node2D and (owner_node as Node2D).is_in_group("hero"):
            return owner_node as Node2D
        return null
    if obj is Node2D:
        var node := obj as Node2D
        if node.is_in_group("hero"):
            return node
        var parent := node.get_parent()
        if parent is Node2D and (parent as Node2D).is_in_group("hero"):
            return parent as Node2D
    return null

func _spawn_heal_vfx(hero: Node2D) -> void:
    if HEAL_VFX_TEX == null:
        return
    var vfx := Sprite2D.new()
    vfx.texture = HEAL_VFX_TEX
    vfx.z_index = 180
    vfx.global_position = hero.global_position + Vector2(0, -18)
    vfx.scale = Vector2(0.45, 0.45)
    if get_parent() != null:
        get_parent().add_child(vfx)
    else:
        add_child(vfx)
    var tw := create_tween()
    tw.tween_property(vfx, "global_position", vfx.global_position + Vector2(0, -24), HEAL_VFX_LIFETIME)
    tw.parallel().tween_property(vfx, "modulate:a", 0.0, HEAL_VFX_LIFETIME)
    tw.finished.connect(_free_temp_node.bind(vfx))

func _free_temp_node(node: Node) -> void:
    if node != null and is_instance_valid(node):
        node.queue_free()

func _fade_and_destroy() -> void:
    if pool_anim:
        var tween := create_tween()
        tween.tween_property(pool_anim, "modulate:a", 0.0, 0.5)
        await tween.finished
    queue_free()

func _get_or_create_pool_frames() -> SpriteFrames:
    if _cached_pool_frames != null:
        return _cached_pool_frames

    var frames := SpriteFrames.new()
    if not frames.has_animation(POOL_VFX_ANIM):
        frames.add_animation(POOL_VFX_ANIM)
    frames.set_animation_loop(POOL_VFX_ANIM, true)
    frames.set_animation_speed(POOL_VFX_ANIM, POOL_VFX_FPS)

    for idx in range(1, 12):
        var path := "%s/%d.png" % [POOL_VFX_FOLDER, idx]
        if not ResourceLoader.exists(path):
            continue
        var tex := load(path) as Texture2D
        if tex != null:
            frames.add_frame(POOL_VFX_ANIM, tex)

    _cached_pool_frames = frames
    return _cached_pool_frames

func _get_autoload(node_name: String) -> Node:
    var tree := get_tree()
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null(node_name)
