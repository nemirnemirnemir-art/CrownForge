extends RefCounted
class_name GameSceneHeroes

## Manage heroes on the GameScene field
## Spawn, despawn, squad updates
## Uses MapMarkerService for positions

const HeroSceneRegistryScript = preload("res://scripts/hero/HeroSceneRegistry.gd")

var _game_scene: Node2D
var _hero_container: Node2D
var _map_bounds: Rect2
var active_heroes_on_field: Dictionary = {}
var _last_death_positions: Dictionary = {}  # hero_id -> Vector2 (for rider replacement)
const MAX_HEROES_ON_FIELD: int = 9999
const HERO_DEPLOY_SPAWN_OFFSET_X: float = 60.0
const WALL_SAFE_MARGIN_X: float = 55.0
const CASTLE_PATROL_BOX_SIZE: Vector2 = Vector2(150.0, 300.0)
const CASTLE_PATROL_CENTER_OFFSET_X: float = 95.0
const HERO_SPAWN_SCATTER_RADIUS: float = 22.0
const HERO_SPAWN_SCATTER_SLOTS: int = 6

func initialize(game_scene: Node2D, hero_container: Node2D, map_bounds: Rect2) -> void:
    _game_scene = game_scene
    _hero_container = hero_container
    _map_bounds = map_bounds

func update_heroes_on_field() -> void:
    if not _hero_container:
        var map_container = _game_scene.get_node_or_null("WorldYSort/MapContainer")
        if map_container:
            var pivot = map_container.get_node_or_null("HeroPivot")
            if pivot:
                _hero_container = pivot
            else:
                _hero_container = map_container
        
        if not _hero_container:
            return
    
    var hero_core: Variant = _get_hero_core()
    if hero_core == null or hero_core.query == null:
        return
    var active_hero_ids: Array = hero_core.active_hero_ids.duplicate()
    if active_hero_ids.size() > MAX_HEROES_ON_FIELD:
        active_hero_ids = active_hero_ids.slice(0, MAX_HEROES_ON_FIELD)
    print("[GameSceneHeroes] DEBUG: update_heroes_on_field called. Active IDs from HeroCore: %s" % str(active_hero_ids))
    print("[GameSceneHeroes] DEBUG: Currently on field: %s" % str(active_heroes_on_field.keys()))
    
    # Remove heroes that are not in active_hero_ids OR are dead
    for hero_id in active_heroes_on_field.keys():
        var should_remove = false
        var hero_node = active_heroes_on_field[hero_id]
        
        if not is_instance_valid(hero_node):
            active_heroes_on_field.erase(hero_id)
            continue
            
        if hero_id not in active_hero_ids:
            var is_returning = false
            if "is_returning" in hero_node:
                is_returning = bool(hero_node.is_returning)
            
            if not is_returning:
                should_remove = true
        elif hero_core.query.is_hero_dead(hero_id):
            should_remove = true
        
        if should_remove:
            despawn_hero_from_field(hero_id)
    
    for hero_id in active_hero_ids:
        if hero_id not in active_heroes_on_field:
            if hero_core.query.has_hero(hero_id):
                if not hero_core.query.is_hero_dead(hero_id):
                    spawn_hero_on_field(hero_id)

func spawn_hero_on_field(hero_id: String, override_position: Vector2 = Vector2.INF) -> void:
    var resolved_id := HeroSceneRegistryScript.resolve_unit_id(hero_id)
    var scene_to_use: PackedScene = HeroSceneRegistryScript.load_scene(hero_id)

    if not scene_to_use:
        push_error("[GameSceneHeroes] Unknown hero_id for spawning: %s (resolved unit: %s)" % [hero_id, resolved_id])
        return
    
    var hero_instance: Node2D = scene_to_use.instantiate()
    if not hero_instance: return
    
    # Position from MapMarkerService or override
    var spawn_pos: Vector2
    if override_position != Vector2.INF:
        spawn_pos = _clamp_to_map_bounds(override_position)
    else:
        spawn_pos = _clamp_to_map_bounds(_calculate_spawn_position())
    
    if _hero_container:
        hero_instance.position = _hero_container.to_local(spawn_pos)
    else:
        hero_instance.global_position = spawn_pos
    
    _hero_container.add_child(hero_instance)
    
    if hero_instance.has_method("initialize"):
        hero_instance.initialize(hero_id)
        
    # Pass bridge position from the service
    if "bridge_position" in hero_instance:
        hero_instance.bridge_position = _get_map_marker_service().get_bridge_position()

    var marker_service: Variant = _get_map_marker_service()
    var patrol_center: Vector2 = marker_service.get_bridge_position() if marker_service else Vector2.ZERO
    if patrol_center == Vector2.ZERO:
        patrol_center = spawn_pos
    var wall_pos_for_patrol: Vector2 = marker_service.get_wall_position() if marker_service else Vector2.ZERO
    if wall_pos_for_patrol != Vector2.ZERO:
        patrol_center.x = maxf(patrol_center.x + CASTLE_PATROL_CENTER_OFFSET_X, wall_pos_for_patrol.x + WALL_SAFE_MARGIN_X + 40.0)

    if "patrol_center" in hero_instance:
        hero_instance.patrol_center = _clamp_to_map_bounds(patrol_center)
    if "patrol_box_size" in hero_instance:
        hero_instance.patrol_box_size = CASTLE_PATROL_BOX_SIZE

    if hero_instance.has_method("set_map_bounds"):
        hero_instance.set_map_bounds(_map_bounds)

    active_heroes_on_field[hero_id] = hero_instance

func spawn_temporary_hero_on_field(unit_id: String, duration: float, override_position: Vector2 = Vector2.INF) -> void:
    var scene_to_use: PackedScene = HeroSceneRegistryScript.load_scene(unit_id)
    if not scene_to_use:
        push_error("[GameSceneHeroes] Unknown temporary summon unit_id: %s" % unit_id)
        return
    var hero_instance: Node2D = scene_to_use.instantiate()
    if hero_instance == null:
        return
    var spawn_pos: Vector2
    if override_position != Vector2.INF:
        spawn_pos = _clamp_to_map_bounds(override_position)
    else:
        spawn_pos = _clamp_to_map_bounds(_calculate_spawn_position())
    if _hero_container:
        hero_instance.position = _hero_container.to_local(spawn_pos)
    else:
        hero_instance.global_position = spawn_pos
    _hero_container.add_child(hero_instance)
    if hero_instance.has_method("initialize_as_summon"):
        hero_instance.call("initialize_as_summon", unit_id, duration)
    if "bridge_position" in hero_instance:
        hero_instance.bridge_position = _get_map_marker_service().get_bridge_position()
    if hero_instance.has_method("set_map_bounds"):
        hero_instance.set_map_bounds(_map_bounds)

func _calculate_spawn_position() -> Vector2:
    var hero_count: int = active_heroes_on_field.size()

    var marker_service: MapMarkerService = _get_map_marker_service()
    if marker_service == null:
        var fallback_base := Vector2(1000.0, 300.0)
        if _map_bounds.size != Vector2.ZERO:
            fallback_base = _map_bounds.get_center()
        return _clamp_to_map_bounds(_apply_spawn_spread(fallback_base, hero_count))

    var defense_markers := marker_service.get_defense_markers()
    if not defense_markers.is_empty():
        var pos: Vector2 = marker_service.get_defense_position(hero_count)
        if pos != Vector2.ZERO:
            pos.x += HERO_DEPLOY_SPAWN_OFFSET_X
            pos = _apply_spawn_spread(pos, hero_count)
            var wall_pos: Vector2 = marker_service.get_wall_position()
            if wall_pos != Vector2.ZERO:
                pos.x = max(pos.x, wall_pos.x + WALL_SAFE_MARGIN_X)
            return pos
    
    # Fallback to bridge + offset if there are no markers
    var bridge_pos: Vector2 = marker_service.get_bridge_position()
    var fallback_formation: Array[Vector2] = [
        Vector2(-140, 90),
        Vector2(-110, 40),
        Vector2(-200, 40),
        Vector2(-80, -20),
        Vector2(-160, -70),
        Vector2(-240, -10)
    ]
    
    if hero_count < fallback_formation.size():
        var fallback_pos: Vector2 = bridge_pos + fallback_formation[hero_count] + Vector2(HERO_DEPLOY_SPAWN_OFFSET_X, 0.0)
        fallback_pos = _apply_spawn_spread(fallback_pos, hero_count)
        var wall_pos_fallback: Vector2 = marker_service.get_wall_position()
        if wall_pos_fallback != Vector2.ZERO:
            fallback_pos.x = max(fallback_pos.x, wall_pos_fallback.x + WALL_SAFE_MARGIN_X)
        return fallback_pos

    var extra_index: int = hero_count - fallback_formation.size()
    var col: int = extra_index % 3
    var row: int = int(float(extra_index) / 3.0)
    var offset: Vector2 = Vector2(-260 - col * 70, -80 - row * 60)
    var extra_pos: Vector2 = bridge_pos + offset + Vector2(HERO_DEPLOY_SPAWN_OFFSET_X, 0.0)
    extra_pos = _apply_spawn_spread(extra_pos, hero_count)
    var wall_pos_extra: Vector2 = marker_service.get_wall_position()
    if wall_pos_extra != Vector2.ZERO:
        extra_pos.x = max(extra_pos.x, wall_pos_extra.x + WALL_SAFE_MARGIN_X)
    return extra_pos

func _apply_spawn_spread(base_pos: Vector2, hero_index: int) -> Vector2:
    if hero_index <= 0:
        return base_pos

    var ring: int = int(floor(float(hero_index) / float(HERO_SPAWN_SCATTER_SLOTS)))
    var slot: int = hero_index % HERO_SPAWN_SCATTER_SLOTS
    var radius: float = HERO_SPAWN_SCATTER_RADIUS * float(ring + 1)
    var angle: float = (TAU / float(HERO_SPAWN_SCATTER_SLOTS)) * float(slot)
    return base_pos + Vector2(cos(angle), sin(angle)) * radius

func reset() -> void:
    for hero_id in active_heroes_on_field:
        var hero = active_heroes_on_field[hero_id]
        if is_instance_valid(hero):
            hero.queue_free()
    active_heroes_on_field.clear()

func despawn_hero_from_field(hero_id: String) -> void:
    if not active_heroes_on_field.has(hero_id):
        return
        
    if hero_id in active_heroes_on_field:
        var hero = active_heroes_on_field[hero_id]
        if is_instance_valid(hero):
            # Store death position for rider replacement mechanic
            _last_death_positions[hero_id] = hero.global_position
            hero.queue_free()
        active_heroes_on_field.erase(hero_id)

## Get and consume death position for rider replacement mechanic
func pop_death_position(hero_id: String) -> Vector2:
    if _last_death_positions.has(hero_id):
        var pos: Vector2 = _last_death_positions[hero_id]
        _last_death_positions.erase(hero_id)
        return pos
    return Vector2.INF

## Get current position of hero on field (for rider replacement mechanic)
func get_hero_position(hero_id: String) -> Vector2:
    if active_heroes_on_field.has(hero_id):
        var hero = active_heroes_on_field[hero_id]
        if is_instance_valid(hero):
            return hero.global_position
    return Vector2.INF

func check_dead_heroes_cleanup() -> void:
    for hero_id in active_heroes_on_field.keys():
        var hero_core: Variant = _get_hero_core()
        if hero_core != null and hero_core.heroes.has(hero_id):
            var hero_data = hero_core.heroes[hero_id]
            if hero_data.get("isDead", false):
                despawn_hero_from_field(hero_id)

func _get_hero_core() -> Variant:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("HeroCore")

func _get_map_marker_service() -> MapMarkerService:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("MapMarkerService")

func update_map_bounds(map_bounds: Rect2) -> void:
    _map_bounds = map_bounds
    for hero_node in active_heroes_on_field.values():
        if hero_node and is_instance_valid(hero_node) and hero_node.has_method("set_map_bounds"):
            hero_node.set_map_bounds(_map_bounds)

func _clamp_to_map_bounds(world_position: Vector2) -> Vector2:
    if _map_bounds.size == Vector2.ZERO:
        return world_position
    return Vector2(
        clampf(world_position.x, _map_bounds.position.x, _map_bounds.end.x),
        clampf(world_position.y, _map_bounds.position.y, _map_bounds.end.y)
    )


## Called when GameSceneWaves emits wave_spawned.
## Waits 5 s then orders all on-field heroes to engage enemies.
func on_wave_spawned(wave_number: int) -> void:
    await _game_scene.get_tree().create_timer(5.0).timeout
    if not is_instance_valid(_game_scene) or not _game_scene.is_inside_tree():
        return
    var heroes := _game_scene.get_tree().get_nodes_in_group("hero")
    for hero in heroes:
        if hero.has_node("HeroAIController"):
            var ai := hero.get_node("HeroAIController")
            if ai.has_method("engage_enemies"):
                ai.engage_enemies()
    print("[GameSceneHeroes] Heroes engaging wave %d" % wave_number)


## Called when all enemies are cleared.  Orders all on-field heroes back to patrol.
func on_enemies_cleared() -> void:
    var tree := _game_scene.get_tree()
    if tree == null:
        return
    var heroes := tree.get_nodes_in_group("hero")
    for hero in heroes:
        if hero.has_node("HeroAIController"):
            var ai := hero.get_node("HeroAIController")
            if ai.has_method("return_to_patrol"):
                ai.return_to_patrol()
    print("[GameSceneHeroes] Heroes returned to patrol")
