extends SpellEffect

const THUNDER_FOLDER: String = "res://assets/vfx/spells_visuals/Thunderstorm"
const THUNDER_ANIM: StringName = &"erupt"
const THUNDER_FPS: float = 24.0
const THUNDER_SCALE: float = 2.0
const THUNDER_SPLASH_TRIGGER_FRAME: int = 10 # 11th frame (0-based index)

const WATER_SPLASH_FOLDER: String = "res://assets/vfx/Particle FX/WaterSplash"
const WATER_SPLASH_ANIM: StringName = &"default"
const WATER_SPLASH_FPS: float = 16.0

const PICK_RADIUS_DEFAULT: float = 75.0
const LAUNCH_HEIGHT_PX: float = 200.0
const LAUNCH_UP_TIME: float = 0.36
const LAUNCH_HANG_TIME: float = 1.0
const LAUNCH_DOWN_TIME: float = 0.22
const LAND_DAMAGE: float = 250.0
const LAND_STUN_SEC: float = 3.0

static var _cached_thunder_frames: SpriteFrames = null
static var _cached_water_splash_frames: SpriteFrames = null

func execute_effect() -> void:
    var target := _find_primary_target()
    var thunder := _spawn_thunder_animation()

    var trigger_delay := _get_splash_trigger_delay(thunder)
    if trigger_delay > 0.0:
        await get_tree().create_timer(trigger_delay).timeout

    _spawn_water_splash(global_position)

    if target != null and is_instance_valid(target):
        await _launch_and_land_target(target)

    if thunder != null and is_instance_valid(thunder) and thunder.is_playing():
        await thunder.animation_finished

    queue_free()

func _find_primary_target() -> Node2D:
    var tree := get_tree()
    if tree == null:
        return null

    var radius := get_scaled_radius(config.target_radius if config != null and config.target_radius > 0.0 else PICK_RADIUS_DEFAULT)
    var radius_sq := radius * radius

    var candidates: Array = tree.get_nodes_in_group("enemy")
    candidates.append_array(tree.get_nodes_in_group("mobs"))
    candidates.append_array(tree.get_nodes_in_group("enemies"))

    var seen: Dictionary = {}
    var best: Node2D = null
    var best_d2 := INF

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

        var d2 := enemy.global_position.distance_squared_to(global_position)
        if d2 > radius_sq:
            continue
        if d2 < best_d2:
            best_d2 = d2
            best = enemy

    return best

func _spawn_thunder_animation() -> AnimatedSprite2D:
    var frames := _get_or_create_thunder_frames()
    if frames == null:
        return null

    var sprite := AnimatedSprite2D.new()
    sprite.sprite_frames = frames
    sprite.animation = THUNDER_ANIM
    sprite.global_position = global_position
    sprite.z_index = 205
    sprite.z_as_relative = false
    sprite.scale = Vector2.ONE * THUNDER_SCALE
    if get_parent() != null:
        get_parent().add_child(sprite)
    else:
        add_child(sprite)

    if sprite.sprite_frames.has_animation(THUNDER_ANIM):
        sprite.play(THUNDER_ANIM)

    return sprite

func _get_splash_trigger_delay(thunder: AnimatedSprite2D) -> float:
    if thunder == null or not is_instance_valid(thunder):
        return 0.0
    if thunder.sprite_frames == null or not thunder.sprite_frames.has_animation(THUNDER_ANIM):
        return 0.0

    var frame_count := thunder.sprite_frames.get_frame_count(THUNDER_ANIM)
    if frame_count <= 0:
        return 0.0

    var trigger_frame: int = mini(THUNDER_SPLASH_TRIGGER_FRAME, frame_count - 1)
    var fps := thunder.sprite_frames.get_animation_speed(THUNDER_ANIM)
    if fps <= 0.001:
        fps = THUNDER_FPS

    return float(trigger_frame) / fps

func _spawn_water_splash(world_pos: Vector2) -> void:
    var frames := _get_or_create_water_splash_frames()
    if frames == null:
        return

    var sprite := AnimatedSprite2D.new()
    sprite.sprite_frames = frames
    sprite.animation = WATER_SPLASH_ANIM
    var adjusted_pos := world_pos + Vector2(0, 15.0)
    sprite.global_position = adjusted_pos
    sprite.z_index = 210
    sprite.z_as_relative = false
    if get_parent() != null:
        get_parent().add_child(sprite)
    else:
        add_child(sprite)

    if sprite.sprite_frames.has_animation(WATER_SPLASH_ANIM):
        sprite.play(WATER_SPLASH_ANIM)
        sprite.animation_finished.connect(_on_temp_fx_finished.bind(sprite))
    else:
        sprite.queue_free()

func _launch_and_land_target(target: Node2D) -> void:
    if target == null or not is_instance_valid(target):
        return

    var start_pos := target.global_position
    var state := _capture_motion_state(target)
    _set_target_locked(target, state, true)

    if target != null and is_instance_valid(target):
        var tween := create_tween()
        tween.set_trans(Tween.TRANS_QUAD)
        tween.set_ease(Tween.EASE_OUT)
        tween.tween_property(target, "global_position", start_pos + Vector2(0.0, -LAUNCH_HEIGHT_PX), LAUNCH_UP_TIME)
        tween.tween_interval(LAUNCH_HANG_TIME)
        tween.set_ease(Tween.EASE_IN)
        tween.tween_property(target, "global_position", start_pos, LAUNCH_DOWN_TIME)
        await tween.finished

    if target != null and is_instance_valid(target):
        target.global_position = start_pos

    _set_target_locked(target, state, false)

    if target == null or not is_instance_valid(target):
        return

    _apply_land_damage_and_stun(target)

func _capture_motion_state(target: Node2D) -> Dictionary:
    var sm := target.get_node_or_null("MobStateMachine")
    var result := {
        "state_machine": sm,
        "sm_was_processing": true,
        "sm_was_physics_processing": true,
        "target_was_processing": target.is_processing(),
        "target_was_physics_processing": target.is_physics_processing(),
    }

    if sm != null and is_instance_valid(sm):
        result["sm_was_processing"] = sm.is_processing()
        result["sm_was_physics_processing"] = sm.is_physics_processing()

    return result

func _set_target_locked(target: Node2D, state: Dictionary, locked: bool) -> void:
    if target == null or not is_instance_valid(target):
        return

    var sm: Node = state.get("state_machine")
    if sm != null and is_instance_valid(sm):
        if locked:
            sm.process_mode = Node.PROCESS_MODE_DISABLED
            sm.set_process(false)
            sm.set_physics_process(false)
        else:
            sm.process_mode = Node.PROCESS_MODE_INHERIT
            sm.set_process(bool(state.get("sm_was_processing", true)))
            sm.set_physics_process(bool(state.get("sm_was_physics_processing", true)))

    if locked:
        target.set_process(false)
        target.set_physics_process(false)
        if target is CharacterBody2D:
            (target as CharacterBody2D).velocity = Vector2.ZERO
    else:
        target.set_process(bool(state.get("target_was_processing", true)))
        target.set_physics_process(bool(state.get("target_was_physics_processing", true)))
        if target is CharacterBody2D:
            (target as CharacterBody2D).velocity = Vector2.ZERO

func _apply_land_damage_and_stun(target: Node2D) -> void:
    var base_damage := LAND_DAMAGE
    if config != null and config.damage > 0.0:
        base_damage = config.damage
    var damage := get_scaled_damage(base_damage)

    var hurtbox := target.get_node_or_null("Hurtbox")
    if hurtbox != null and hurtbox.has_method("apply_hit"):
        hurtbox.apply_hit(damage, self, Time.get_ticks_msec() + target.get_instance_id() + get_instance_id())
    elif target.has_method("take_damage"):
        target.take_damage(damage)

    if target.has_method("apply_stun"):
        target.apply_stun(LAND_STUN_SEC)

func _get_or_create_thunder_frames() -> SpriteFrames:
    if _cached_thunder_frames != null:
        return _cached_thunder_frames

    var frames := SpriteFrames.new()
    if not frames.has_animation(THUNDER_ANIM):
        frames.add_animation(THUNDER_ANIM)
    frames.set_animation_loop(THUNDER_ANIM, false)
    frames.set_animation_speed(THUNDER_ANIM, THUNDER_FPS)

    for idx in range(1, 14):
        var path := "%s/%03d.png" % [THUNDER_FOLDER, idx]
        if not ResourceLoader.exists(path):
            continue
        var tex := load(path) as Texture2D
        if tex != null:
            frames.add_frame(THUNDER_ANIM, tex)

    _cached_thunder_frames = frames
    return _cached_thunder_frames

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

func _on_temp_fx_finished(sprite: AnimatedSprite2D) -> void:
    if sprite != null and is_instance_valid(sprite):
        sprite.queue_free()
