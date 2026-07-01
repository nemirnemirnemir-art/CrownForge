extends SpellEffect

## Groundfire - start explosion, ring fire zone, applies 6s DoT to enemies entering zone

@onready var fire_anim: AnimatedSprite2D = $FireAnim
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

const ZONE_DURATION: float = 6.0
const DOT_DURATION: float = 6.0
const DOT_TICK_INTERVAL: float = 1.0
const DOT_DAMAGE_PER_TICK: float = 30.0

const RING_FIRE_COUNT: int = 8
const RING_FIRE_SCALE: float = 1.0
const RING_OFFSET_FACTOR: float = 0.6

const GROUND_FIRE_FOLDER: String = "res://assets/vfx/spells_visuals/Groundfire"
const GROUND_FIRE_ANIM: StringName = &"groundfire_start"
const GROUND_FIRE_FPS: float = 20.0

const FIRE_LOOP_FOLDER: String = "res://assets/vfx/Particle FX/Fire"
const FIRE_LOOP_ANIM: StringName = &"fire_loop"
const FIRE_LOOP_FPS: float = 14.0

const PULSE_SPEED: float = 4.0
const PULSE_STRENGTH: float = 0.4

static var _cached_groundfire_frames: SpriteFrames = null
static var _cached_fire_loop_frames: SpriteFrames = null

const SpellEnemyTrackerScript := preload("res://scripts/effects/shared/SpellEnemyTracker.gd")
const SpellDamageApplicatorScript := preload("res://scripts/effects/shared/SpellDamageApplicator.gd")
const SpellVisualLifecycleScript := preload("res://scripts/effects/shared/SpellVisualLifecycle.gd")

var _zone_time_left: float = ZONE_DURATION
var _zone_radius: float = 80.0
var _zone_active: bool = true
var _zone_fading: bool = false

var _ring_fires: Array[AnimatedSprite2D] = []
var _active_dots: Dictionary = {}
var _enemy_tracker: RefCounted = SpellEnemyTrackerScript.new()
var _damage_applicator: RefCounted = SpellDamageApplicatorScript.new()
var _visual_lifecycle: RefCounted = SpellVisualLifecycleScript.new()

func execute_effect() -> void:
    if damage_area == null or damage_shape == null:
        push_error("[GroundfireEffect] Missing required nodes")
        queue_free()
        return

    _zone_time_left = config.duration if config != null and config.duration > 0.0 else ZONE_DURATION
    _zone_radius = get_scaled_radius(config.target_radius if config != null and config.target_radius > 0.0 else 80.0)

    var shape := CircleShape2D.new()
    shape.radius = _zone_radius
    damage_shape.shape = shape

    damage_area.monitoring = true
    damage_area.monitorable = true

    _spawn_start_explosion()
    _spawn_ring_fires()
    set_process(true)

func _process(delta: float) -> void:
    if _zone_active:
        _zone_time_left -= delta
        _apply_dot_to_overlapping_enemies()
        if _zone_time_left <= 0.0:
            _zone_active = false
            _fade_zone_visuals()

    _update_active_dots(delta)

    if not _zone_active and _active_dots.is_empty() and _zone_fading:
        queue_free()

func _apply_dot_to_overlapping_enemies() -> void:
    var found_any := false

    var overlaps: Array = []
    overlaps.append_array(damage_area.get_overlapping_areas())
    overlaps.append_array(damage_area.get_overlapping_bodies())

    for obj in overlaps:
        var enemy: Node2D = _enemy_tracker.resolve_enemy_from_collider(obj)
        if enemy == null:
            continue
        found_any = true
        _apply_or_refresh_dot(enemy)

    if found_any:
        return

    for enemy in _collect_fallback_targets():
        _apply_or_refresh_dot(enemy)

func _apply_or_refresh_dot(enemy: Node2D) -> void:
    var id := enemy.get_instance_id()
    if _active_dots.has(id):
        var existing: Dictionary = _active_dots[id]
        existing["remaining"] = DOT_DURATION
        return

    _active_dots[id] = {
        "enemy_ref": weakref(enemy),
        "remaining": DOT_DURATION,
        "tick_timer": DOT_TICK_INTERVAL,
        "base_modulate": enemy.modulate,
    }

func _update_active_dots(delta: float) -> void:
    var to_remove: Array[int] = []
    var pulse_t := (sin(Time.get_ticks_msec() * 0.001 * PULSE_SPEED) + 1.0) * 0.5

    for id in _active_dots.keys():
        var data: Dictionary = _active_dots[id]
        var enemy := _get_enemy_from_data(data)
        if enemy == null or not is_instance_valid(enemy):
            to_remove.append(int(id))
            continue
        if "is_dead" in enemy and bool(enemy.is_dead):
            _restore_enemy_modulate(enemy, data)
            to_remove.append(int(id))
            continue

        var remaining := float(data.get("remaining", 0.0)) - delta
        data["remaining"] = remaining

        var tick := float(data.get("tick_timer", DOT_TICK_INTERVAL)) - delta
        if tick <= 0.0:
            tick += DOT_TICK_INTERVAL
            _deal_dot_damage(enemy, int(id))
        data["tick_timer"] = tick

        var base_col: Color = data.get("base_modulate", Color(1, 1, 1, 1))
        if base_col is Color:
            var base := base_col as Color
            var red := Color(base.r + 0.45, base.g * 0.55, base.b * 0.55, base.a)
            enemy.modulate = base.lerp(red, pulse_t * PULSE_STRENGTH)

        if remaining <= 0.0:
            _restore_enemy_modulate(enemy, data)
            to_remove.append(int(id))

    for id in to_remove:
        _active_dots.erase(id)

func _deal_dot_damage(enemy: Node2D, key_id: int) -> void:
    var base_tick := DOT_DAMAGE_PER_TICK
    if config != null and config.damage_per_second > 0.0:
        base_tick = config.damage_per_second
    var tick_damage := get_scaled_damage(base_tick)
    var attack_id := Time.get_ticks_msec() + get_instance_id() + key_id

    _damage_applicator.apply_damage(enemy, tick_damage, self, attack_id)

func _restore_enemy_modulate(enemy: Node2D, data: Dictionary) -> void:
    var base_col: Color = data.get("base_modulate", Color.WHITE)
    if base_col is Color and is_instance_valid(enemy):
        enemy.modulate = base_col as Color

func _spawn_start_explosion() -> void:
    var frames := _get_or_create_groundfire_frames()
    if fire_anim == null:
        fire_anim = AnimatedSprite2D.new()
        add_child(fire_anim)
    fire_anim.z_index = 175
    fire_anim.sprite_frames = frames
    fire_anim.scale = Vector2(1.0, 1.0)
    if frames != null and frames.has_animation(GROUND_FIRE_ANIM):
        fire_anim.play(GROUND_FIRE_ANIM)

func _spawn_ring_fires() -> void:
    var frames := _get_or_create_fire_loop_frames()
    if frames == null:
        return

    var ring_r := _zone_radius * RING_OFFSET_FACTOR
    for i in range(RING_FIRE_COUNT):
        var t := float(i) / float(max(1, RING_FIRE_COUNT))
        var angle := t * TAU
        var node := AnimatedSprite2D.new()
        node.sprite_frames = frames
        node.animation = FIRE_LOOP_ANIM
        node.scale = Vector2.ONE * RING_FIRE_SCALE
        node.z_index = 170
        node.position = Vector2(cos(angle), sin(angle)) * ring_r
        add_child(node)
        if node.sprite_frames.has_animation(FIRE_LOOP_ANIM):
            node.play(FIRE_LOOP_ANIM)
        _ring_fires.append(node)

func _fade_zone_visuals() -> void:
    if _zone_fading:
        return
    _zone_fading = true
    var fading_nodes: Array = []
    if fire_anim != null and is_instance_valid(fire_anim):
        fading_nodes.append(fire_anim)
    for f in _ring_fires:
        if f != null and is_instance_valid(f):
            fading_nodes.append(f)
    _visual_lifecycle.fade_out_nodes(self, fading_nodes, 0.4)

func _collect_fallback_targets() -> Array[Node2D]:
    var tree := get_tree()
    if tree == null:
        return []
    return _enemy_tracker.collect_tree_enemies_in_radius(tree.root, global_position, _zone_radius, true)

func _get_enemy_from_data(data: Dictionary) -> Node2D:
    var weak: WeakRef = data.get("enemy_ref")
    if weak == null:
        return null
    var obj: Object = weak.get_ref()
    if obj == null:
        return null
    return obj if obj is Node2D else null

func _get_or_create_groundfire_frames() -> SpriteFrames:
    if _cached_groundfire_frames != null:
        return _cached_groundfire_frames

    var frames := SpriteFrames.new()
    if not frames.has_animation(GROUND_FIRE_ANIM):
        frames.add_animation(GROUND_FIRE_ANIM)
    frames.set_animation_loop(GROUND_FIRE_ANIM, false)
    frames.set_animation_speed(GROUND_FIRE_ANIM, GROUND_FIRE_FPS)

    for idx in range(1, 13):
        var path := "%s/explosion-d%d.png" % [GROUND_FIRE_FOLDER, idx]
        if not ResourceLoader.exists(path):
            continue
        var tex := load(path) as Texture2D
        if tex != null:
            frames.add_frame(GROUND_FIRE_ANIM, tex)

    _cached_groundfire_frames = frames
    return _cached_groundfire_frames

func _get_or_create_fire_loop_frames() -> SpriteFrames:
    if _cached_fire_loop_frames != null:
        return _cached_fire_loop_frames

    var frames := SpriteFrames.new()
    if not frames.has_animation(FIRE_LOOP_ANIM):
        frames.add_animation(FIRE_LOOP_ANIM)
    frames.set_animation_loop(FIRE_LOOP_ANIM, true)
    frames.set_animation_speed(FIRE_LOOP_ANIM, FIRE_LOOP_FPS)

    for idx in range(1, 9):
        var path := "%s/Fire_%02d.png" % [FIRE_LOOP_FOLDER, idx]
        if not ResourceLoader.exists(path):
            continue
        var tex := load(path) as Texture2D
        if tex != null:
            frames.add_frame(FIRE_LOOP_ANIM, tex)

    _cached_fire_loop_frames = frames
    return _cached_fire_loop_frames
