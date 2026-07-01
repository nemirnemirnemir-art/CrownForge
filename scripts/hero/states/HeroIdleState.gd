extends "res://scripts/hero/states/HeroState.gd"

## Hero Idle State (Debug Enriched)
## Throttled enemy check every 2 seconds, light physics-based wandering

var _check_timer: float = 0.0
const CHECK_INTERVAL: float = 0.5  # Check for enemies every 0.5 seconds for faster response
const WALL_SAFE_MARGIN_X: float = 55.0
const WALL_TARGET_BUFFER_X: float = 6.0
const DEFAULT_HERO_RADIUS: float = 12.0
const BLOCKED_WANDER_TIMEOUT: float = 0.75
const MIN_BLOCKED_TRAVEL_RATIO: float = 0.25

var _wander_timer: float = 0.0
var _wander_target: Vector2 = Vector2.ZERO
var _is_wandering: bool = false
var _wander_stuck_time: float = 0.0
var _wander_progress_accum: float = 0.0
var _wander_movement_accum: float = 0.0
var _wander_expected_movement_accum: float = 0.0
var _log_timer: float = 0.0 # Strict debug throttling

func enter() -> void:
    if not hero:
        if state_machine: hero = state_machine._get_hero()
        if not hero: return
    
    # print("[HeroIdleState] %s ENTER detected." % hero.hero_id)
    _check_timer = 0.5
    _wander_timer = 1.0
    _is_wandering = false
    _wander_stuck_time = 0.0
    _wander_progress_accum = 0.0
    _wander_movement_accum = 0.0
    _wander_expected_movement_accum = 0.0
    hero.velocity = Vector2.ZERO
    
    if hero.has_method("_update_animation"):
        hero._update_animation("idle")

func update(delta: float) -> void:
    if not hero or hero.is_dead: return
    
    # Check if hero is orphaned (not in HeroCore anymore)
    if _is_hero_orphaned():
        print("[HeroIdleState] %s is orphaned - removing" % hero.hero_id)
        hero.queue_free()
        return
    
    _check_timer -= delta
    if _check_timer <= 0:
        _check_timer = CHECK_INTERVAL
        if not _is_passive_patroller():
            _check_for_enemies()
    
    if not _is_wandering:
        _wander_timer -= delta
        if _wander_timer <= 0:
            # Wait time over, pick a new spot
            _start_wandering()
            _wander_timer = randf_range(2.0, 4.0) # Next wait time

func physics_update(delta: float) -> void:
    if not hero or hero.is_dead: return
    
    if not _is_wandering:
        _wander_stuck_time = 0.0
        _wander_progress_accum = 0.0
        _wander_movement_accum = 0.0
        _wander_expected_movement_accum = 0.0
        hero.velocity = Vector2.ZERO
        return
    
    var dist = hero.global_position.distance_to(_wander_target)
    
    # HEAVY DEBUG (Throttled slightly to be readable but fast)
    _log_timer += delta
    if _log_timer > 0.2:
        _log_timer = 0.0
        # print("[HeroIdleState] %s Moving... Dist: %.1f, Pos: %s, Target: %s" % [hero.hero_id, dist, hero.global_position, _wander_target])

    if dist < 15.0: # Reached target (tolerance 15px)
        # print("[HeroIdleState] %s Reached wander target." % hero.hero_id)
        _is_wandering = false
        _wander_stuck_time = 0.0
        _wander_progress_accum = 0.0
        _wander_movement_accum = 0.0
        _wander_expected_movement_accum = 0.0
        hero.velocity = Vector2.ZERO
        if hero.has_method("_update_animation"):
            hero._update_animation("idle")
    else:
        # Move
        var previous_pos: Vector2 = hero.global_position
        var dir: Vector2 = (_wander_target - hero.global_position).normalized()
        var move_speed := float(hero.move_speed)
        if "speed_multiplier" in hero:
            move_speed *= maxf(0.0, float(hero.speed_multiplier))
        move_speed *= _get_artifact_move_speed_multiplier()
        hero.velocity = dir * (move_speed * 0.4) # Walk slower when wandering
        hero.move_and_slide()
        if hero.has_method("enforce_battlefield_bounds"):
            var bounced_direction: Vector2 = hero.enforce_battlefield_bounds(dir)
            if bounced_direction != dir and bounced_direction != Vector2.ZERO:
                hero.velocity = bounced_direction * (move_speed * 0.4)
        
        # Flip using flip_h on sprite instead of scale to avoid flickering
        # Only flip when direction change is significant (threshold 0.3)
        if abs(dir.x) > 0.3:
            var should_flip = dir.x < 0
            var walk_sprite = hero.get_node_or_null("AnimWalk")
            var attack_sprite = hero.get_node_or_null("AnimAttack")
            if walk_sprite:
                walk_sprite.flip_h = should_flip
            if attack_sprite:
                attack_sprite.flip_h = should_flip
            if hero.animation_sprite:
                hero.animation_sprite.flip_h = should_flip

        var current_dist: float = hero.global_position.distance_to(_wander_target)
        var moved: float = hero.global_position.distance_to(previous_pos)
        var made_progress: float = dist - current_dist
        _wander_stuck_time += delta
        _wander_movement_accum += moved
        _wander_progress_accum += maxf(0.0, made_progress)
        _wander_expected_movement_accum += move_speed * 0.4 * delta
        if _wander_stuck_time >= BLOCKED_WANDER_TIMEOUT:
            if _wander_expected_movement_accum > 0.0:
                var movement_ratio: float = _wander_movement_accum / _wander_expected_movement_accum
                var progress_ratio: float = _wander_progress_accum / _wander_expected_movement_accum
                if movement_ratio < MIN_BLOCKED_TRAVEL_RATIO or progress_ratio < MIN_BLOCKED_TRAVEL_RATIO:
                    _abort_blocked_wander()
                    return
            _wander_stuck_time = 0.0
            _wander_movement_accum = 0.0
            _wander_progress_accum = 0.0
            _wander_expected_movement_accum = 0.0
        
        if hero.has_method("_update_animation"):
            hero._update_animation("walk")

func exit() -> void:
    # print("[HeroIdleState] %s EXIT. Stopping velocity." % (hero.hero_id if hero else "null"))
    _is_wandering = false
    if hero: hero.velocity = Vector2.ZERO

func _check_for_enemies() -> void:
    if _is_passive_patroller():
        return

    var enemy = CombatTargetFinder.find_nearest(hero, "enemy", 1000.0)
    if enemy and is_instance_valid(enemy):
        # print("[HeroIdleState] %s Found enemy! Switching to combat." % hero.hero_id)
        hero.set_current_target(enemy)
        state_machine.change_state("HeroMovingToCombatState")

func _is_passive_patroller() -> bool:
    return hero and hero.has_method("is_passive_patroller") and hero.is_passive_patroller()

func _start_wandering() -> void:
    var patrol_center := hero.global_position
    if "patrol_center" in hero:
        # If we have a dedicated patrol center, use it. Otherwise use current pos.
        # Ideally patrol center is where they spawned or "Home"
        patrol_center = hero.patrol_center

    var patrol_box_size: Vector2 = Vector2(150.0, 300.0)
    if "patrol_box_size" in hero:
        patrol_box_size = hero.patrol_box_size

    var half_w: float = maxf(10.0, float(patrol_box_size.x) * 0.5)
    var half_h: float = maxf(10.0, float(patrol_box_size.y) * 0.5)
    var offset: Vector2 = Vector2(randf_range(-half_w, half_w), randf_range(-half_h, half_h))

    _wander_target = _sanitize_wander_target(patrol_center + offset)
    _is_wandering = true
    _wander_stuck_time = 0.0
    _wander_progress_accum = 0.0
    _wander_movement_accum = 0.0
    _wander_expected_movement_accum = 0.0

    # print("[HeroIdleState] %s STARTED wandering to %s" % [hero.hero_id, _wander_target])

func _abort_blocked_wander() -> void:
    _is_wandering = false
    _wander_stuck_time = 0.0
    _wander_progress_accum = 0.0
    _wander_movement_accum = 0.0
    _wander_expected_movement_accum = 0.0
    hero.velocity = Vector2.ZERO
    if state_machine:
        state_machine.change_state("HeroSaveFromStackState")

func _sanitize_wander_target(target: Vector2) -> Vector2:
    var safe_target := target
    var wall_safe_x: float = _get_wall_safe_x()
    if wall_safe_x > -INF:
        safe_target.x = maxf(safe_target.x, wall_safe_x)

    var bounds := Rect2()
    if hero and hero.has_method("get_map_bounds"):
        bounds = hero.get_map_bounds()
    elif hero and "map_bounds" in hero:
        bounds = hero.map_bounds

    if bounds.size != Vector2.ZERO:
        safe_target = Vector2(
            clampf(safe_target.x, bounds.position.x, bounds.end.x),
            clampf(safe_target.y, bounds.position.y, bounds.end.y)
        )

    return safe_target

func _get_wall_safe_x() -> float:
    var tree := get_tree()
    if tree:
        for wall in tree.get_nodes_in_group("wall"):
            if wall == null or not is_instance_valid(wall):
                continue
            if wall.has_method("get_world_rect"):
                var wall_rect: Rect2 = wall.get_world_rect()
                if wall_rect.size != Vector2.ZERO:
                    return wall_rect.end.x + _get_hero_collision_radius() + WALL_TARGET_BUFFER_X
            if wall is Node2D:
                return (wall as Node2D).global_position.x + WALL_SAFE_MARGIN_X

    var marker_service := _get_map_marker_service()
    if marker_service and marker_service.has_method("get_wall_position"):
        var wall_pos: Vector2 = marker_service.get_wall_position()
        return wall_pos.x + WALL_SAFE_MARGIN_X

    return -INF

func _get_hero_collision_radius() -> float:
    if hero == null:
        return DEFAULT_HERO_RADIUS

    var collision_shape := hero.get_node_or_null("CollisionShape2D") as CollisionShape2D
    if collision_shape == null or collision_shape.shape == null:
        return DEFAULT_HERO_RADIUS

    var scale := collision_shape.global_transform.get_scale().abs()
    if collision_shape.shape is CircleShape2D:
        var circle := collision_shape.shape as CircleShape2D
        return circle.radius * maxf(scale.x, scale.y)
    if collision_shape.shape is RectangleShape2D:
        var rect := collision_shape.shape as RectangleShape2D
        return rect.size.x * scale.x * 0.5

    return DEFAULT_HERO_RADIUS

func _get_artifact_move_speed_multiplier() -> float:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return 1.0
    var artifact_core := tree.root.get_node_or_null("ArtifactCore")
    if artifact_core == null or not artifact_core.has_method("get_unit_move_speed_multiplier"):
        return 1.0
    var unit_id := _resolve_base_unit_id(String(hero.hero_id))
    if unit_id == "":
        return 1.0
    return maxf(0.01, float(artifact_core.call("get_unit_move_speed_multiplier", unit_id)))

func _resolve_base_unit_id(hero_id: String) -> String:
    var id := hero_id.to_lower()
    if id.contains("_"):
        var parts := id.rsplit("_", true, 1)
        if parts.size() == 2 and String(parts[1]).is_valid_int():
            return String(parts[0])
    return id
