extends SpellEffect

## Moonshine Barrel spell - falls from sky, impacts with splash,
## deals damage and applies drunk debuff (-30% attack speed)

const StatusIconServiceScript := preload("res://scripts/effects/shared/StatusIconService.gd")

@onready var barrel_anim: AnimatedSprite2D = $BarrelAnim
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

const ICON_PATH: String = "res://assets/vfx/spells/Moonshine Barrel.png"
const ICON_OFFSET_Y: float = -55.0

const IMPACT_DAMAGE: float = 75.0
const ATTACK_SPEED_DEBUFF: float = 0.7
const DEBUFF_DURATION: float = 8.0
const FALL_START_OFFSET_Y: float = -360.0
const FALL_TIME: float = 0.35

const BARREL_FOLDER: String = "res://assets/vfx/spells_visuals/Moonshine Barrel"
const BARREL_ANIM: StringName = &"fall"
const BARREL_FPS: float = 16.0

const WATER_SPLASH_FOLDER: String = "res://assets/vfx/Particle FX/WaterSplash"
const WATER_SPLASH_ANIM: StringName = &"default"
const WATER_SPLASH_FPS: float = 16.0

static var _cached_barrel_frames: SpriteFrames = null
static var _cached_water_splash_frames: SpriteFrames = null

var _affected_enemies: Dictionary = {}
var _damaged_enemies: Dictionary = {}

func execute_effect() -> void:
    if not damage_area or not damage_shape:
        push_error("[MoonshineBarrelEffect] Missing required nodes")
        queue_free()
        return

    if config:
        var shape := CircleShape2D.new()
        var base_radius := config.target_radius if config.target_radius > 0 else 60.0
        shape.radius = get_scaled_radius(base_radius)
        damage_shape.shape = shape

    damage_area.monitoring = true
    damage_area.monitorable = true

    if barrel_anim:
        barrel_anim.sprite_frames = _get_or_create_barrel_frames()
        if barrel_anim.sprite_frames and barrel_anim.sprite_frames.has_animation(BARREL_ANIM):
            barrel_anim.play(BARREL_ANIM)

    var impact_pos := global_position
    global_position = impact_pos + Vector2(0.0, FALL_START_OFFSET_Y)

    var fall_tween := create_tween()
    fall_tween.set_trans(Tween.TRANS_QUAD)
    fall_tween.set_ease(Tween.EASE_IN)
    fall_tween.tween_property(self, "global_position", impact_pos, FALL_TIME)
    await fall_tween.finished

    global_position = impact_pos
    _spawn_water_splash(impact_pos)

    await get_tree().process_frame
    await get_tree().physics_frame
    _deal_damage_and_debuff()

    var debuff_duration := DEBUFF_DURATION
    if config != null and config.duration > 0.0:
        debuff_duration = config.duration
    await get_tree().create_timer(debuff_duration).timeout

    _remove_debuff()
    queue_free()

func _deal_damage_and_debuff() -> void:
    if not damage_area:
        return

    var overlaps: Array = []
    overlaps.append_array(damage_area.get_overlapping_areas())
    overlaps.append_array(damage_area.get_overlapping_bodies())

    for obj in overlaps:
        var enemy := _resolve_enemy_from_overlap(obj)
        if enemy == null:
            continue
        _apply_impact(enemy)
        _apply_debuff(enemy)

    if _damaged_enemies.is_empty() and _affected_enemies.is_empty():
        for enemy in _collect_fallback_targets():
            _apply_impact(enemy)
            _apply_debuff(enemy)

func _apply_impact(enemy: Node2D) -> void:
    var id := enemy.get_instance_id()
    if _damaged_enemies.has(id):
        return

    var base_damage := IMPACT_DAMAGE
    if config != null and config.damage > 0.0:
        base_damage = config.damage
    var dmg := get_scaled_damage(base_damage)

    var hurtbox := enemy.get_node_or_null("Hurtbox")
    if hurtbox and hurtbox.has_method("apply_hit"):
        hurtbox.apply_hit(dmg, self, Time.get_ticks_msec() + get_instance_id() + id)
    elif enemy.has_method("take_damage"):
        enemy.take_damage(dmg)

    _damaged_enemies[id] = true

func _apply_debuff(enemy: Node2D) -> void:
    if not ("attack_speed_multiplier" in enemy):
        return

    var id := enemy.get_instance_id()
    if _affected_enemies.has(id):
        return

    enemy.attack_speed_multiplier = float(enemy.attack_speed_multiplier) * ATTACK_SPEED_DEBUFF

    var icon: Sprite2D = StatusIconServiceScript.add_status_icon(enemy, ICON_PATH, "MoonshineIcon", ICON_OFFSET_Y)
    _affected_enemies[id] = {
        "enemy_ref": weakref(enemy),
        "applied_mult": ATTACK_SPEED_DEBUFF,
        "icon_ref": weakref(icon) if icon != null else null,
    }

func _remove_debuff() -> void:
    for id in _affected_enemies.keys():
        var data: Dictionary = _affected_enemies[id]
        var enemy_obj := _resolve_weakref(data.get("enemy_ref"))
        if enemy_obj == null or not is_instance_valid(enemy_obj):
            continue
        if not (enemy_obj is Node2D):
            continue
        var enemy := enemy_obj as Node2D
        if "attack_speed_multiplier" in enemy:
            var applied := float(data.get("applied_mult", 1.0))
            if applied > 0.001:
                enemy.attack_speed_multiplier = maxf(0.01, float(enemy.attack_speed_multiplier) / applied)

        var icon_node := _resolve_weakref(data.get("icon_ref"))
        if icon_node != null and is_instance_valid(icon_node) and icon_node is Node:
            (icon_node as Node).queue_free()
        StatusIconServiceScript.schedule_deferred_reflow(enemy)

    _affected_enemies.clear()

func _resolve_enemy_from_overlap(obj: Variant) -> Node2D:
    if obj == null:
        return null

    if obj is Hurtbox:
        var owner_node := (obj as Hurtbox).get_parent()
        if owner_node is Node2D and _is_enemy(owner_node as Node2D):
            var enemy := owner_node as Node2D
            if "is_dead" in enemy and bool(enemy.is_dead):
                return null
            return enemy
        return null

    if obj is Node2D:
        var node := obj as Node2D
        if _is_enemy(node):
            if "is_dead" in node and bool(node.is_dead):
                return null
            return node
        var parent := node.get_parent()
        if parent is Node2D and _is_enemy(parent as Node2D):
            var enemy_parent := parent as Node2D
            if "is_dead" in enemy_parent and bool(enemy_parent.is_dead):
                return null
            return enemy_parent

    return null

func _collect_fallback_targets() -> Array[Node2D]:
    var result: Array[Node2D] = []
    var tree := get_tree()
    if tree == null:
        return result

    var radius := 60.0
    if damage_shape != null and damage_shape.shape is CircleShape2D:
        radius = (damage_shape.shape as CircleShape2D).radius
    var radius_sq := radius * radius

    var candidates: Array = tree.get_nodes_in_group("enemy")
    candidates.append_array(tree.get_nodes_in_group("mobs"))
    candidates.append_array(tree.get_nodes_in_group("enemies"))

    var seen: Dictionary = {}
    for node in candidates:
        if not (node is Node2D):
            continue
        var enemy := node as Node2D
        if not is_instance_valid(enemy):
            continue
        if "is_dead" in enemy and bool(enemy.is_dead):
            continue
        var id := enemy.get_instance_id()
        if seen.has(id):
            continue
        seen[id] = true
        if enemy.global_position.distance_squared_to(global_position) > radius_sq:
            continue
        result.append(enemy)

    return result

func _spawn_water_splash(world_pos: Vector2) -> void:
    var frames := _get_or_create_water_splash_frames()
    if frames == null:
        return

    var splash := AnimatedSprite2D.new()
    splash.sprite_frames = frames
    splash.animation = WATER_SPLASH_ANIM
    splash.global_position = world_pos
    splash.z_index = 205
    add_child(splash)

    if splash.sprite_frames.has_animation(WATER_SPLASH_ANIM):
        splash.play(WATER_SPLASH_ANIM)
        splash.animation_finished.connect(_on_temp_anim_finished.bind(splash))
    else:
        splash.queue_free()

func _on_temp_anim_finished(anim: AnimatedSprite2D) -> void:
    if anim != null and is_instance_valid(anim):
        anim.queue_free()

func _resolve_weakref(value: Variant) -> Object:
    if value == null or not (value is WeakRef):
        return null
    return (value as WeakRef).get_ref() as Object

func _is_enemy(node: Node2D) -> bool:
    return node.is_in_group("enemy") or node.is_in_group("mobs") or node.is_in_group("enemies")

func _get_or_create_barrel_frames() -> SpriteFrames:
    if _cached_barrel_frames != null:
        return _cached_barrel_frames

    var frames := SpriteFrames.new()
    if not frames.has_animation(BARREL_ANIM):
        frames.add_animation(BARREL_ANIM)
    frames.set_animation_loop(BARREL_ANIM, false)
    frames.set_animation_speed(BARREL_ANIM, BARREL_FPS)

    for idx in range(1, 11):
        var path := "%s/%03d.png" % [BARREL_FOLDER, idx]
        if not ResourceLoader.exists(path):
            continue
        var tex := load(path) as Texture2D
        if tex != null:
            frames.add_frame(BARREL_ANIM, tex)

    _cached_barrel_frames = frames
    return _cached_barrel_frames

func _get_or_create_water_splash_frames() -> SpriteFrames:
    if _cached_water_splash_frames != null:
        return _cached_water_splash_frames

    var frames := SpriteFrames.new()
    if not frames.has_animation(WATER_SPLASH_ANIM):
        frames.add_animation(WATER_SPLASH_ANIM)
    frames.set_animation_loop(WATER_SPLASH_ANIM, false)
    frames.set_animation_speed(WATER_SPLASH_ANIM, WATER_SPLASH_FPS)

    for idx in range(1, 10):
        var path := "%s/Water Splash%d.png" % [WATER_SPLASH_FOLDER, idx]
        if not ResourceLoader.exists(path):
            continue
        var tex := load(path) as Texture2D
        if tex != null:
            frames.add_frame(WATER_SPLASH_ANIM, tex)

    _cached_water_splash_frames = frames
    return _cached_water_splash_frames
