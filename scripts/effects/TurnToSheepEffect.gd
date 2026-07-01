extends SpellEffect

## Turn to Sheep spell effect - transforms up to 5 enemies into sheep for 3 seconds

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

const SheepScene = preload("res://scenes/spells/sheep/Sheep.tscn")

const MAX_TARGETS: int = 5
const SHEEP_DURATION: float = 3.0

var _transformed_enemies: Array[Dictionary] = []  # {enemy: Node, sheep_instance: Node2D, sprites: Array, timers: Array}

const SHEEP_VISUAL_NAME: StringName = &"__sheep_visual"

const SHEEP_SPEED: float = 100.0

func execute_effect() -> void:
    if not detection_area or not detection_shape:
        push_error("[TurnToSheepEffect] Missing required nodes")
        queue_free()
        return

    detection_area.monitoring = true
    detection_area.monitorable = true
    
    # Set detection radius
    if config:
        var shape := CircleShape2D.new()
        shape.radius = get_scaled_radius(config.target_radius if config.target_radius > 0.0 else 100.0)
        detection_shape.shape = shape
    
    # Wait one frame for physics to update
    await get_tree().physics_frame
    await get_tree().physics_frame
    
    _detect_and_transform_enemies()
    
    # Start duration timer
    var duration := SHEEP_DURATION
    if config and config.duration > 0.0:
        duration = config.duration
    await get_tree().create_timer(duration).timeout
    _restore_all_enemies()
    queue_free()

func _detect_and_transform_enemies() -> void:
    if not detection_area:
        return

    var targets := _collect_targets(MAX_TARGETS)
    for enemy in targets:
        _transform_enemy(enemy)

func _collect_targets(limit: int) -> Array[Node2D]:
    var result: Array[Node2D] = []
    var dedupe: Dictionary = {}

    var overlaps: Array = []
    overlaps.append_array(detection_area.get_overlapping_bodies())
    overlaps.append_array(detection_area.get_overlapping_areas())

    for obj in overlaps:
        var enemy := _resolve_enemy_from_collider(obj)
        if enemy == null:
            continue
        var id := enemy.get_instance_id()
        if dedupe.has(id):
            continue
        dedupe[id] = true
        result.append(enemy)

    if result.size() < limit:
        var fallback := _collect_fallback_enemies_in_radius()
        for enemy in fallback:
            var id := enemy.get_instance_id()
            if dedupe.has(id):
                continue
            dedupe[id] = true
            result.append(enemy)

    result.sort_custom(func(a: Node2D, b: Node2D):
        return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position)
    )

    if result.size() > limit:
        result.resize(limit)

    return result

func _collect_fallback_enemies_in_radius() -> Array[Node2D]:
    var result: Array[Node2D] = []
    var tree := get_tree()
    if tree == null:
        return result

    var radius := get_scaled_radius(config.target_radius if config != null and config.target_radius > 0.0 else 100.0)
    var radius_sq := radius * radius

    var candidates: Array = tree.get_nodes_in_group("enemy")
    candidates.append_array(tree.get_nodes_in_group("mobs"))
    candidates.append_array(tree.get_nodes_in_group("enemies"))

    var dedupe: Dictionary = {}
    for node in candidates:
        if not (node is Node2D):
            continue
        var enemy := node as Node2D
        if not is_instance_valid(enemy):
            continue
        if "is_dead" in enemy and bool(enemy.is_dead):
            continue
        if enemy.global_position.distance_squared_to(global_position) > radius_sq:
            continue
        var id := enemy.get_instance_id()
        if dedupe.has(id):
            continue
        dedupe[id] = true
        result.append(enemy)

    return result

func _resolve_enemy_from_collider(collider: Object) -> Node2D:
    if collider == null:
        return null
    var enemy: Node2D = null
    if collider is Hurtbox:
        var p := (collider as Hurtbox).get_parent()
        if p is Node2D:
            enemy = p
    elif collider is Node2D:
        enemy = collider as Node2D
    if enemy == null:
        return null
    if not enemy.is_in_group("enemy") and not enemy.is_in_group("enemies") and not enemy.is_in_group("mobs"):
        return null
    if "is_dead" in enemy and bool(enemy.is_dead):
        return null
    return enemy

func _collect_visuals_to_hide(root: Node) -> Array[CanvasItem]:
    var result: Array[CanvasItem] = []
    var stack: Array[Node] = [root]
    while stack.size() > 0:
        var n: Node = stack.pop_back()
        for c in n.get_children():
            stack.append(c)
            if c is AnimatedSprite2D or c is Sprite2D:
                result.append(c as CanvasItem)
    return result

func _transform_enemy(enemy: Node2D) -> void:
    # Find all sprite-like visuals to hide (robust against different mob scene structures)
    var sprite_states: Array[Dictionary] = []
    var visuals: Array[CanvasItem] = _collect_visuals_to_hide(enemy)
    for v in visuals:
        sprite_states.append({"node": v, "was_visible": v.visible})
        v.visible = false

    # Remove any old sheep visual that might have remained from previous transforms
    var old_sheep: Node = enemy.get_node_or_null(String(SHEEP_VISUAL_NAME))
    if old_sheep and is_instance_valid(old_sheep):
        old_sheep.queue_free()
    
    # Create and attach sheep visual
    var sheep: Node2D = SheepScene.instantiate()
    sheep.name = String(SHEEP_VISUAL_NAME)
    enemy.add_child(sheep)
    sheep.position = Vector2.ZERO  # Position at enemy origin
    
    # Store data for restoration
    var original_speed := 0.0
    var v: Variant = enemy.get("move_speed")
    if v != null and (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT):
        original_speed = float(v)
    var transform_data := {
        "enemy": enemy,
        "sheep_instance": sheep,
        "sprites": sprite_states,
        "original_speed": original_speed,
        "was_processing": enemy.is_processing(),
        "was_physics_processing": enemy.is_physics_processing(),
        "state_machine": enemy.get_node_or_null("MobStateMachine"),
        "state_machine_was_processing": false,
        "state_machine_was_physics_processing": false,
        "watchdog_timer": enemy.get_node_or_null("WatchdogTimer"),
        "watchdog_timer_was_stopped": true,
        "watchdog_timer_time_left": 0.0,
        "sheep_dir": Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized(),
        "timers": []
    }
    _transformed_enemies.append(transform_data)

    var sm: Node = transform_data.get("state_machine")
    if sm and is_instance_valid(sm):
        transform_data["state_machine_was_processing"] = sm.is_processing()
        transform_data["state_machine_was_physics_processing"] = sm.is_physics_processing()
        sm.process_mode = Node.PROCESS_MODE_DISABLED
        sm.set_process(false)
        sm.set_physics_process(false)

    var watchdog: Node = transform_data.get("watchdog_timer")
    if watchdog and is_instance_valid(watchdog) and watchdog is Timer:
        var t := watchdog as Timer
        transform_data["watchdog_timer_was_stopped"] = t.is_stopped()
        transform_data["watchdog_timer_time_left"] = t.time_left
        t.process_mode = Node.PROCESS_MODE_DISABLED
        t.stop()
    enemy.set_process(false)
    enemy.set_physics_process(false)

    if enemy is CharacterBody2D:
        (enemy as CharacterBody2D).velocity = Vector2.ZERO
    
    # Apply sheep movement behavior
    _apply_sheep_movement(enemy, transform_data)

func _apply_sheep_movement(enemy: Node, transform_data: Dictionary) -> void:
    var movement_timer := Timer.new()
    movement_timer.wait_time = 0.3
    movement_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
    movement_timer.timeout.connect(func():
        if not is_instance_valid(enemy):
            return
        transform_data["sheep_dir"] = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
    )
    add_child(movement_timer)
    movement_timer.start()
    transform_data["timers"].append(movement_timer)

func _physics_process(delta: float) -> void:
    for data in _transformed_enemies:
        var enemy: Node = data.get("enemy")
        if not is_instance_valid(enemy):
            continue
        if enemy is Node and not (enemy as Node).is_inside_tree():
            continue
        if enemy is Node and (enemy as Node).is_queued_for_deletion():
            continue
        var dir: Vector2 = data.get("sheep_dir", Vector2.ZERO)
        if dir == Vector2.ZERO:
            dir = Vector2.RIGHT
        if enemy is Node2D:
            (enemy as Node2D).global_position += dir * (SHEEP_SPEED * delta)

func _restore_all_enemies() -> void:
    for data in _transformed_enemies:
        var enemy: Node = data.get("enemy")
        if not is_instance_valid(enemy):
            continue
        
        # Remove sheep visual
        var sheep_instance = data.get("sheep_instance")
        if sheep_instance and is_instance_valid(sheep_instance):
            sheep_instance.queue_free()

        # Fallback: ensure there is no lingering sheep visual node
        var sheep_leftover: Node = enemy.get_node_or_null(String(SHEEP_VISUAL_NAME))
        if sheep_leftover and is_instance_valid(sheep_leftover):
            sheep_leftover.queue_free()
        
        # Restore enemy sprites
        var sprite_states: Array = data.get("sprites", [])
        for s in sprite_states:
            var n: CanvasItem = s.get("node")
            if n and is_instance_valid(n):
                n.visible = bool(s.get("was_visible", true))

        var sm: Node = data.get("state_machine")
        if sm and is_instance_valid(sm):
            sm.process_mode = Node.PROCESS_MODE_INHERIT
            sm.set_process(bool(data.get("state_machine_was_processing", true)))
            sm.set_physics_process(bool(data.get("state_machine_was_physics_processing", true)))

        var watchdog: Node = data.get("watchdog_timer")
        if watchdog and is_instance_valid(watchdog) and watchdog is Timer:
            var t := watchdog as Timer
            t.process_mode = Node.PROCESS_MODE_INHERIT
            if bool(data.get("watchdog_timer_was_stopped", true)):
                t.stop()
            else:
                var left: float = float(data.get("watchdog_timer_time_left", 0.0))
                if left > 0.0:
                    t.start(left)
                else:
                    t.start()

        enemy.set_process(bool(data.get("was_processing", true)))
        enemy.set_physics_process(bool(data.get("was_physics_processing", true)))
        
        # Restore movement speed
        if enemy.get("move_speed") != null:
            enemy.set("move_speed", data.get("original_speed", 50.0))
        
        # Clean up timers
        var timers: Array = data.get("timers", [])
        for timer in timers:
            if timer and is_instance_valid(timer):
                timer.queue_free()
    
    _transformed_enemies.clear()
