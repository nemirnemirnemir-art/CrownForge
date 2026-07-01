extends RefCounted
class_name TownProduction

const ProjectileSpawnHelper := preload("res://scripts/combat/ProjectileSpawnHelper.gd")

## Resource production
## Passive gold, tower damage, building production calculations

var _buildings_manager: TownBuildings
var _tower_timer: float = 0.0

func initialize(buildings_manager: TownBuildings) -> void:
    _buildings_manager = buildings_manager

func get_passive_gold_production() -> float:
    if not _buildings_manager:
        return 0.0
    
    var total = 0.0
    var buildings = _buildings_manager.get_buildings()
    for id in buildings:
        total += get_building_gold_production(id)
    return total

func get_passive_damage() -> float:
    if not _buildings_manager:
        return 0.0
    
    var total = 0.0
    var buildings = _buildings_manager.get_buildings()
    var registry = _buildings_manager.get_building_registry()
    
    for id in buildings:
        var level = buildings[id]["level"]
        var data = registry.get(id)
        if not data:
            continue
        
        var base = data.base_passive_damage_per_sec
        var per_lvl = data.passive_damage_per_level
        if level >= 1 and (base > 0 or per_lvl > 0):
            total += base + (per_lvl * (level - 1))
    return total

func get_building_gold_production(building_id: String) -> float:
    if not _buildings_manager:
        return 0.0
    
    var level = _buildings_manager.get_building_level(building_id)
    if level == 0:
        return 0.0
    
    var data = _buildings_manager.get_building_config(building_id)
    if not data:
        return 0.0
    
    var base = data.base_gold_per_sec
    var per_lvl = data.gold_per_level
    var production = 0.0
    
    if base > 0 or per_lvl > 0:
        production = base + (per_lvl * (level - 1))
    
    # Morale Bonus
    if MoraleSystem:
        production *= (1.0 + MoraleSystem.get_productivity_modifier())
    if KingSpellState:
        production *= (1.0 + KingSpellState.get_productivity_bonus_multiplier())
    
    return production

func process_passive_gold(delta: float) -> void:
    var gold_per_sec = get_passive_gold_production()
    if gold_per_sec > 0:
        EconomyCore.add_gold(gold_per_sec * delta)

func process_passive_damage(delta: float) -> void:
    var tower_damage_per_sec = get_passive_damage()
    if tower_damage_per_sec <= 0:
        return
    
    # Fire once per second (configurable)
    _tower_timer += delta
    if _tower_timer >= 1.0:  # Once per second
        _tower_timer = 0.0
        _shoot_tower_projectile(tower_damage_per_sec)

func _shoot_tower_projectile(damage: float) -> void:
    # Find GameScene and get nearest mob
    var game_scene = _get_game_scene()
    if game_scene == null:
        return
    
    # Ensure it has get_alive_mobs
    if not game_scene.has_method("get_alive_mobs"):
        return
    
    var alive_mobs = game_scene.get_alive_mobs()
    if alive_mobs.is_empty():
        return
    
    # Find nearest mob to the right side of the screen
    var viewport = Engine.get_main_loop().root.get_viewport()
    if viewport == null:
        return
    
    var screen_right = viewport.get_visible_rect().size.x
    var screen_center_y = viewport.get_visible_rect().size.y * 0.5
    var tower_start_pos = Vector2(screen_right, screen_center_y)
    
    # Find nearest enemy
    var nearest_target: Node2D = null
    var nearest_dist: float = INF
    
    for target in alive_mobs:
        if not is_instance_valid(target):
            continue
        
        # Check if it's a Mob
        if target is Mob:
            if target.is_dead:
                continue
        # Generic dead check for any enemy-like object
        elif "is_dead" in target:
            if bool(target.is_dead):
                continue
        
        var dist = tower_start_pos.distance_to(target.global_position)
        if dist < nearest_dist:
            nearest_dist = dist
            nearest_target = target
    
    if nearest_target == null:
        return
    
    # Create projectile
    var projectile_scene: PackedScene = preload("res://scenes/projectiles/ArrowProjectile.tscn")
    if projectile_scene == null:
        return

    var map_container = game_scene.get_node_or_null("WorldYSort/MapContainer")
    if map_container == null:
        # print("[TownProduction] ⚠️ MapContainer not found under WorldYSort")
        return
    
    var final_damage := damage
    if SkillCore and SkillCore.has_method("get_global_damage_multiplier"):
        final_damage *= float(SkillCore.get_global_damage_multiplier())

    var target_node := nearest_target as Node2D
    if target_node == null:
        return
    ProjectileSpawnHelper.spawn_at(projectile_scene, map_container, tower_start_pos, target_node, final_damage, 400.0, 0.0, null, "default")

func _get_game_scene() -> Node:
    # Find GameScene via group or tree
    var game_scene_nodes = Engine.get_main_loop().root.get_tree().get_nodes_in_group("game_scene")
    if game_scene_nodes.size() > 0:
        return game_scene_nodes[0]
    
    # Fallback: current scene
    return Engine.get_main_loop().root.get_tree().current_scene
