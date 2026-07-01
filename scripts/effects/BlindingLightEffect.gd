extends SpellEffect

## Blinding Light spell - forces enemies into random left/right movement

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

const StatusIconServiceScript := preload("res://scripts/effects/shared/StatusIconService.gd")

const DEFAULT_DURATION: float = 4.0
const ICON_TEXTURE_PATH: String = "res://assets/vfx/spells_visuals/Blinding Light.png"
const ICON_OFFSET: Vector2 = Vector2(0.0, -55.0)
const ICON_SIZE: float = 37.5
const DIR_CHANGE_MIN_SEC: float = 0.35
const DIR_CHANGE_MAX_SEC: float = 1.1
const MOVE_SPEED_RATIO_MIN: float = 0.45
const MOVE_SPEED_RATIO_MAX: float = 0.75
const MOVE_SPEED_FLOOR: float = 18.0
const MOVE_SPEED_CEIL: float = 110.0

const SpellEnemyTrackerScript := preload("res://scripts/effects/shared/SpellEnemyTracker.gd")

var _affected: Dictionary = {}
var _enemy_tracker: SpellEnemyTracker = SpellEnemyTrackerScript.new()

func execute_effect() -> void:
    if not detection_area or not detection_shape:
        push_error("[BlindingLightEffect] Missing required nodes")
        queue_free()
        return

    if config:
        var shape := CircleShape2D.new()
        shape.radius = config.target_radius if config.target_radius > 0 else 80.0
        detection_shape.shape = shape

    await get_tree().process_frame
    await get_tree().physics_frame
    await get_tree().physics_frame

    var duration := DEFAULT_DURATION
    if config != null and config.duration > 0.0:
        duration = config.duration

    _apply_to_enemies()
    set_physics_process(true)

    await get_tree().create_timer(duration).timeout
    _release_all()
    queue_free()

func _apply_to_enemies() -> void:
    var targets: Array[Node2D] = []
    if detection_area != null:
        for body_any in detection_area.get_overlapping_bodies():
            if body_any is Node2D:
                targets.append(body_any as Node2D)
    if targets.is_empty():
        targets = _enemy_tracker.collect_tree_enemies_in_radius(get_tree().root, global_position, config.target_radius if config != null and config.target_radius > 0.0 else 80.0, true)

    for body in targets:
        var enemy: Node2D = _enemy_tracker.resolve_enemy_from_collider(body)
        if enemy == null:
            continue
        _blind_enemy(enemy)

func _blind_enemy(enemy: Node2D) -> void:
    if enemy == null or not is_instance_valid(enemy):
        return

    var id := enemy.get_instance_id()
    if _affected.has(id):
        return

    var sm: Node = enemy.get_node_or_null("MobStateMachine")
    var was_sm_processing := true
    var was_sm_physics := true
    if sm != null and is_instance_valid(sm):
        was_sm_processing = sm.is_processing()
        was_sm_physics = sm.is_physics_processing()
        sm.process_mode = Node.PROCESS_MODE_DISABLED
        sm.set_process(false)
        sm.set_physics_process(false)

    var was_processing := enemy.is_processing()
    var was_physics := enemy.is_physics_processing()
    enemy.set_process(false)
    enemy.set_physics_process(false)

    var icon := Sprite2D.new()
    var tex := load(ICON_TEXTURE_PATH) as Texture2D
    icon.texture = tex
    icon.position = ICON_OFFSET
    icon.z_index = 200
    icon.name = "BlindingLightIcon"
    icon.set_meta("status_icon", true)
    icon.set_meta("status_icon_offset_y", ICON_OFFSET.y)
    if tex != null:
        var size := tex.get_size()
        if size.x > 0.0 and size.y > 0.0:
            icon.scale = Vector2(ICON_SIZE / size.x, ICON_SIZE / size.y)
    enemy.add_child(icon)
    StatusIconServiceScript.reflow_status_icons(enemy)

    var anim_walk := enemy.get_node_or_null("AnimWalk")
    var anim_attack := enemy.get_node_or_null("AnimAttack")
    var was_walk_visible := false
    var was_attack_visible := false
    if anim_walk != null and anim_walk is CanvasItem:
        was_walk_visible = (anim_walk as CanvasItem).visible
    if anim_attack != null and anim_attack is CanvasItem:
        was_attack_visible = (anim_attack as CanvasItem).visible

    if anim_walk != null and anim_walk is AnimatedSprite2D:
        var walk_sprite := anim_walk as AnimatedSprite2D
        if walk_sprite.sprite_frames:
            if walk_sprite.sprite_frames.has_animation("walk"):
                walk_sprite.play("walk")
            elif walk_sprite.sprite_frames.has_animation("default"):
                walk_sprite.play("default")
        walk_sprite.visible = true
    if anim_attack != null and anim_attack is CanvasItem:
        (anim_attack as CanvasItem).visible = false

    var anim_single := enemy.get_node_or_null("AnimationSprite2D")
    if anim_single is AnimatedSprite2D:
        var single := anim_single as AnimatedSprite2D
        if single.sprite_frames:
            if single.sprite_frames.has_animation("walk"):
                single.play("walk")
            elif single.sprite_frames.has_animation("run"):
                single.play("run")
            elif single.sprite_frames.has_animation("default"):
                single.play("default")

    var base_speed := 60.0
    var speed_variant: Variant = null
    if enemy.has_method("get"):
        speed_variant = enemy.get("move_speed")
    if speed_variant != null:
        base_speed = float(speed_variant)
    var blind_speed := _roll_blind_speed(base_speed)

    _affected[id] = {
        "enemy_ref": weakref(enemy),
        "sm_ref": weakref(sm) if sm != null else null,
        "was_sm_processing": was_sm_processing,
        "was_sm_physics_processing": was_sm_physics,
        "was_processing": was_processing,
        "was_physics_processing": was_physics,
        "icon_ref": weakref(icon),
        "walk_ref": weakref(anim_walk) if anim_walk != null else null,
        "attack_ref": weakref(anim_attack) if anim_attack != null else null,
        "was_walk_visible": was_walk_visible,
        "was_attack_visible": was_attack_visible,
        "base_move_speed": base_speed,
        "time_since_dir_change": 0.0,
        "next_dir_change": randf_range(DIR_CHANGE_MIN_SEC, DIR_CHANGE_MAX_SEC),
        "current_dir": 1.0 if randf() > 0.5 else -1.0,
        "speed": blind_speed,
    }

func _physics_process(delta: float) -> void:
    var stale_ids: Array[int] = []
    for id in _affected.keys():
        var data: Dictionary = _affected[id]
        var enemy := _get_enemy_from_data(data)
        if enemy == null or not is_instance_valid(enemy):
            stale_ids.append(int(id))
            continue

        data["time_since_dir_change"] = float(data.get("time_since_dir_change", 0.0)) + delta
        if float(data.get("time_since_dir_change", 0.0)) >= float(data.get("next_dir_change", DIR_CHANGE_MIN_SEC)):
            data["time_since_dir_change"] = 0.0
            data["next_dir_change"] = randf_range(DIR_CHANGE_MIN_SEC, DIR_CHANGE_MAX_SEC)
            data["current_dir"] = 1.0 if randf() > 0.5 else -1.0
            data["speed"] = _roll_blind_speed(float(data.get("base_move_speed", 60.0)))

        var dir := float(data.get("current_dir", 1.0))
        var speed := float(data.get("speed", MOVE_SPEED_FLOOR))
        if enemy is CharacterBody2D:
            var cb := enemy as CharacterBody2D
            cb.velocity = Vector2(dir * speed, 0.0)
            cb.move_and_slide()
            _flip_enemy_visuals(enemy, dir)
        else:
            enemy.global_position.x += dir * speed * delta
            _flip_enemy_visuals(enemy, dir)

    for id in stale_ids:
        _release_enemy_by_id(id)

func _release_all() -> void:
    for id in _affected.keys():
        _release_enemy_by_id(int(id))
    _affected.clear()
    set_physics_process(false)

func _release_enemy_by_id(id: int) -> void:
    if not _affected.has(id):
        return

    var data: Dictionary = _affected[id]
    var enemy := _get_enemy_from_data(data)

    _queue_free_node_from_weakref(data.get("icon_ref"))

    var sm_obj := _get_object_from_weakref(data.get("sm_ref"))
    if sm_obj != null and is_instance_valid(sm_obj) and sm_obj is Node:
        var sm := sm_obj as Node
        sm.process_mode = Node.PROCESS_MODE_INHERIT
        sm.set_process(bool(data.get("was_sm_processing", true)))
        sm.set_physics_process(bool(data.get("was_sm_physics_processing", true)))

    if enemy != null and is_instance_valid(enemy):
        enemy.process_mode = Node.PROCESS_MODE_INHERIT
        enemy.set_process(bool(data.get("was_processing", true)))
        enemy.set_physics_process(bool(data.get("was_physics_processing", true)))
        if enemy is CharacterBody2D:
            (enemy as CharacterBody2D).velocity = Vector2.ZERO
        call_deferred("_deferred_reflow_for_enemy", enemy)

    var walk_obj := _get_object_from_weakref(data.get("walk_ref"))
    if walk_obj != null and is_instance_valid(walk_obj) and walk_obj is CanvasItem:
        (walk_obj as CanvasItem).visible = bool(data.get("was_walk_visible", true))
    var attack_obj := _get_object_from_weakref(data.get("attack_ref"))
    if attack_obj != null and is_instance_valid(attack_obj) and attack_obj is CanvasItem:
        (attack_obj as CanvasItem).visible = bool(data.get("was_attack_visible", false))

    _affected.erase(id)

func _get_enemy_from_data(data: Dictionary) -> Node2D:
    var weak: WeakRef = data.get("enemy_ref")
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
    return (value as WeakRef).get_ref() as Object

func _queue_free_node_from_weakref(value: Variant) -> void:
    var obj := _get_object_from_weakref(value)
    if obj != null and is_instance_valid(obj) and obj is Node:
        (obj as Node).queue_free()

func _roll_blind_speed(base_speed: float) -> float:
    var ratio := randf_range(MOVE_SPEED_RATIO_MIN, MOVE_SPEED_RATIO_MAX)
    return clampf(base_speed * ratio, MOVE_SPEED_FLOOR, MOVE_SPEED_CEIL)

func _flip_enemy_visuals(enemy: Node2D, dir: float) -> void:
    if absf(dir) < 0.05:
        return
    var should_flip := dir < 0.0

    var anim_walk := enemy.get_node_or_null("AnimWalk")
    if anim_walk is AnimatedSprite2D:
        (anim_walk as AnimatedSprite2D).flip_h = should_flip

    var anim_attack := enemy.get_node_or_null("AnimAttack")
    if anim_attack is AnimatedSprite2D:
        (anim_attack as AnimatedSprite2D).flip_h = should_flip

    var anim := enemy.get_node_or_null("AnimationSprite2D")
    if anim is AnimatedSprite2D:
        (anim as AnimatedSprite2D).flip_h = should_flip

func _deferred_reflow_for_enemy(target: Node2D) -> void:
    StatusIconServiceScript.reflow_status_icons(target)
