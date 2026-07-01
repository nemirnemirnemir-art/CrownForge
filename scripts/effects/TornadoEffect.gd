extends SpellEffect

@onready var tornado_anim: AnimatedSprite2D = $TornadoAnim
@onready var capture_area: Area2D = $CaptureArea
@onready var capture_shape: CollisionShape2D = $CaptureArea/CollisionShape2D

const DEFAULT_DURATION: float = 12.0
const DEFAULT_RADIUS: float = 240.0
const DEFAULT_DPS: float = 40.0

const ANIM_NAME: StringName = &"default"
const ANIM_FPS: float = 14.0
const VISUAL_SCALE: float = 2.0

const MOVE_SPEED_MIN: float = 70.0
const MOVE_SPEED_MAX: float = 140.0
const BOUNDS_MARGIN_PX: float = 10.0

const CAPTURE_ORBIT_SPEED_RAD: float = 5.0
const CAPTURE_ORBIT_RADIUS_MIN: float = 36.0
const CAPTURE_ORBIT_RADIUS_MAX: float = 110.0
const CAPTURE_JITTER_PX: float = 8.0

const DAMAGE_TICK_INTERVAL: float = 1.0

const SpellEnemyTrackerScript := preload("res://scripts/effects/shared/SpellEnemyTracker.gd")
const SpellDamageApplicatorScript := preload("res://scripts/effects/shared/SpellDamageApplicator.gd")
const SpellBoundsEnforcerScript := preload("res://scripts/effects/shared/SpellBoundsEnforcer.gd")
const SpellCaptureOrbitControllerScript := preload("res://scripts/effects/shared/SpellCaptureOrbitController.gd")

static var _cached_frames: SpriteFrames = null

var _duration_left: float = DEFAULT_DURATION
var _tick_left: float = DAMAGE_TICK_INTERVAL
var _radius: float = DEFAULT_RADIUS
var _dps: float = DEFAULT_DPS

var _velocity: Vector2 = Vector2.ZERO
var _captured: Dictionary = {} # instance_id -> Dictionary
var _enemy_tracker: RefCounted = SpellEnemyTrackerScript.new()
var _damage_applicator: RefCounted = SpellDamageApplicatorScript.new()
var _bounds_enforcer: RefCounted = SpellBoundsEnforcerScript.new()
var _capture_orbit_controller: RefCounted = SpellCaptureOrbitControllerScript.new()

func _exit_tree() -> void:
    _release_all()

func execute_effect() -> void:
    if tornado_anim == null or capture_area == null or capture_shape == null:
        push_error("[TornadoEffect] Missing required nodes")
        queue_free()
        return

    _radius = get_scaled_radius((config.target_radius if config != null and config.target_radius > 0.0 else DEFAULT_RADIUS))
    _duration_left = (config.duration if config != null and config.duration > 0.0 else DEFAULT_DURATION)
    _dps = (config.damage_per_second if config != null and config.damage_per_second > 0.0 else DEFAULT_DPS)
    _dps = get_scaled_damage(_dps)

    var shape := CircleShape2D.new()
    shape.radius = _radius
    capture_shape.shape = shape

    capture_area.monitoring = true
    capture_area.monitorable = true

    tornado_anim.sprite_frames = _get_or_create_frames()
    tornado_anim.scale = Vector2.ONE * VISUAL_SCALE
    if tornado_anim.sprite_frames != null and tornado_anim.sprite_frames.has_animation(ANIM_NAME):
        tornado_anim.play(ANIM_NAME)

    _velocity = _random_velocity()

    set_process(true)
    set_physics_process(true)

func _physics_process(delta: float) -> void:
    _duration_left -= delta
    if _duration_left <= 0.0:
        _release_all()
        queue_free()
        return

    _move_within_bounds(delta)
    _capture_new_overlaps()
    _update_captured_units(delta)
    _apply_damage_tick(delta)

func _random_velocity() -> Vector2:
    var dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
    if dir.length_squared() < 0.001:
        dir = Vector2.RIGHT
    dir = dir.normalized()
    var speed := randf_range(MOVE_SPEED_MIN, MOVE_SPEED_MAX)
    return dir * speed

func _move_within_bounds(delta: float) -> void:
    var rect := _get_visible_world_rect()
    var result: Dictionary = _bounds_enforcer.move_within_rect(global_position, _velocity, delta, _radius, BOUNDS_MARGIN_PX, rect, Callable(self, "_random_velocity"))
    global_position = result.get("position", global_position)
    _velocity = result.get("velocity", _velocity)

func _get_visible_world_rect() -> Rect2:
    var viewport := get_viewport()
    if viewport == null:
        return Rect2(Vector2.ZERO, Vector2.ONE)

    var vis := viewport.get_visible_rect()
    var camera := viewport.get_camera_2d()
    if camera == null:
        return Rect2(global_position - vis.size * 0.5, vis.size)

    var zoom_x := maxf(camera.zoom.x, 0.001)
    var zoom_y := maxf(camera.zoom.y, 0.001)
    var half_w := vis.size.x * 0.5 / zoom_x
    var half_h := vis.size.y * 0.5 / zoom_y
    return Rect2(camera.global_position - Vector2(half_w, half_h), Vector2(half_w * 2.0, half_h * 2.0))

func _capture_new_overlaps() -> void:
    if capture_area == null:
        return

    var seen: Dictionary = {} # instance_id -> Node2D

    var bodies := capture_area.get_overlapping_bodies()
    for b in bodies:
        var enemy: Node2D = _enemy_tracker.resolve_enemy_from_collider(b, false)
        if enemy == null:
            continue
        seen[enemy.get_instance_id()] = enemy

    var areas := capture_area.get_overlapping_areas()
    for a in areas:
        var enemy: Node2D = _enemy_tracker.resolve_enemy_from_collider(a, false)
        if enemy == null:
            continue
        seen[enemy.get_instance_id()] = enemy

    if seen.is_empty():
        for enemy in _enemy_tracker.collect_tree_enemies_in_radius(get_tree().root, global_position, _radius, true):
            seen[enemy.get_instance_id()] = enemy

    for id in seen.keys():
        if not _captured.has(id):
            _capture_enemy(seen[id])

func _capture_enemy(enemy: Node2D) -> void:
    if enemy == null or not is_instance_valid(enemy):
        return

    var id := enemy.get_instance_id()
    if _captured.has(id):
        return

    var was_processing := enemy.is_processing()
    var was_physics_processing := enemy.is_physics_processing()

    var sm: Node = enemy.get_node_or_null("MobStateMachine")
    var sm_proc := false
    var sm_phys := false
    if sm and is_instance_valid(sm):
        sm_proc = sm.is_processing()
        sm_phys = sm.is_physics_processing()
        sm.process_mode = Node.PROCESS_MODE_DISABLED
        sm.set_process(false)
        sm.set_physics_process(false)

    var watchdog: Node = enemy.get_node_or_null("WatchdogTimer")
    var watchdog_was_stopped := true
    var watchdog_time_left := 0.0
    if watchdog and is_instance_valid(watchdog) and watchdog is Timer:
        var t := watchdog as Timer
        watchdog_was_stopped = t.is_stopped()
        watchdog_time_left = t.time_left
        t.process_mode = Node.PROCESS_MODE_DISABLED
        t.stop()

    enemy.set_process(false)
    enemy.set_physics_process(false)

    if enemy is CharacterBody2D:
        (enemy as CharacterBody2D).velocity = Vector2.ZERO

    var data := {
        "id": id,
        "weak_ref": weakref(enemy),
        "orbit_r": randf_range(CAPTURE_ORBIT_RADIUS_MIN, CAPTURE_ORBIT_RADIUS_MAX),
        "orbit_a": randf_range(-PI, PI),
        "phase": randf_range(0.0, 1000.0),
        "sm_ref": weakref(sm) if sm != null else null,
        "sm_proc": sm_proc,
        "sm_phys": sm_phys,
        "was_processing": was_processing,
        "was_physics_processing": was_physics_processing,
        "watchdog_ref": weakref(watchdog) if watchdog != null else null,
        "watchdog_was_stopped": watchdog_was_stopped,
        "watchdog_time_left": watchdog_time_left,
    }
    _captured[id] = data

func _update_captured_units(delta: float) -> void:
    var to_remove: Array[int] = []
    for id in _captured.keys():
        var data: Dictionary = _captured[id]
        var enemy := _get_enemy_from_data(data)
        if enemy == null or not enemy.is_inside_tree() or enemy.is_queued_for_deletion():
            to_remove.append(id)
            continue

        var orbit_r := float(data.get("orbit_r", 30.0))
        var orbit_a := float(data.get("orbit_a", 0.0))
        orbit_a += CAPTURE_ORBIT_SPEED_RAD * delta
        data["orbit_a"] = orbit_a

        var phase := float(data.get("phase", 0.0))
        var orbit_result: Dictionary = _capture_orbit_controller.advance_position(global_position, orbit_a, orbit_r, phase, CAPTURE_JITTER_PX)
        enemy.global_position = orbit_result.get("position", enemy.global_position)

        if enemy is CharacterBody2D:
            (enemy as CharacterBody2D).velocity = Vector2.ZERO

        _captured[id] = data

    for id in to_remove:
        _release_enemy_by_id(id)

func _apply_damage_tick(delta: float) -> void:
    _tick_left -= delta
    if _tick_left > 0.0:
        return
    _tick_left += DAMAGE_TICK_INTERVAL

    var dmg := _dps * DAMAGE_TICK_INTERVAL
    var attack_id := Time.get_ticks_msec()

    for id in _captured.keys():
        var data: Dictionary = _captured[id]
        var enemy := _get_enemy_from_data(data)
        if enemy == null:
            continue
        _apply_damage_to_target(enemy, dmg, attack_id + enemy.get_instance_id())

func _apply_damage_to_target(target: Node, amount: float, attack_id: int) -> void:
    _damage_applicator.apply_damage(target, amount, self, attack_id)

func _release_enemy_by_id(id: int, enemy: Node2D = null) -> void:
    if not _captured.has(id):
        return

    var data: Dictionary = _captured[id]
    if enemy == null:
        enemy = _get_enemy_from_data(data)

    var watchdog_obj := _get_object_from_weakref(data.get("watchdog_ref"))
    if watchdog_obj != null and is_instance_valid(watchdog_obj) and watchdog_obj is Timer:
        var t := watchdog_obj as Timer
        t.process_mode = Node.PROCESS_MODE_INHERIT
        if bool(data.get("watchdog_was_stopped", true)):
            t.stop()
        else:
            var left: float = float(data.get("watchdog_time_left", 0.0))
            if left > 0.0:
                t.start(left)
            else:
                t.start()

    if enemy and is_instance_valid(enemy):
        enemy.set_process(bool(data.get("was_processing", true)))
        enemy.set_physics_process(bool(data.get("was_physics_processing", true)))
        var sm_obj := _get_object_from_weakref(data.get("sm_ref"))
        if sm_obj != null and is_instance_valid(sm_obj):
            var sm: Node = sm_obj as Node
            sm.process_mode = Node.PROCESS_MODE_INHERIT
            sm.set_process(bool(data.get("sm_proc", true)))
            sm.set_physics_process(bool(data.get("sm_phys", true)))

    _captured.erase(id)

func _release_all() -> void:
    for id in _captured.keys():
        _release_enemy_by_id(id)
    _captured.clear()

func _get_enemy_from_data(data: Dictionary) -> Node2D:
    var weak: WeakRef = data.get("weak_ref")
    if weak == null:
        return null
    var obj: Object = weak.get_ref()
    if obj == null:
        return null
    return obj if obj is Node2D else null

func _get_object_from_weakref(value: Variant) -> Object:
    if value == null:
        return null
    if not (value is WeakRef):
        return null
    var wr: WeakRef = value
    return wr.get_ref() as Object

func _get_or_create_frames() -> SpriteFrames:
    if _cached_frames != null:
        return _cached_frames

    var frames := SpriteFrames.new()
    if not frames.has_animation(ANIM_NAME):
        frames.add_animation(ANIM_NAME)
    frames.set_animation_speed(ANIM_NAME, ANIM_FPS)
    frames.set_animation_loop(ANIM_NAME, true)

    for idx in range(1, 10):
        var frame_path := "res://assets/vfx/spells_visuals/Tornado/%03d.png" % idx
        var texture := load(frame_path) as Texture2D
        if texture != null:
            frames.add_frame(ANIM_NAME, texture)

    _cached_frames = frames
    return _cached_frames
