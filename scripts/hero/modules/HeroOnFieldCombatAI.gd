extends RefCounted
class_name HeroOnFieldCombatAI

const ProjectileSpawnHelperScript := preload("res://scripts/combat/ProjectileSpawnHelper.gd")

## Handles combat AI and projectile firing for HeroOnField

var hero: Node2D
var stats: HeroOnFieldStats
var total_damage_dealt: float = 0.0
var _attack_timer: float = 0.0

func setup(hero_ref: Node2D, stats_ref: HeroOnFieldStats) -> void:
    hero = hero_ref
    stats = stats_ref

func update_attack_timer(delta: float) -> void:
    if _attack_timer > 0.0:
        _attack_timer -= delta

func check_attack_range(target: Node2D, extra_buffer: float = 0.0) -> bool:
    if target == null or stats == null:
        return false
    var dist = hero.global_position.distance_to(target.global_position)
    return dist <= (stats.attack_range + 15.0 + extra_buffer)

func is_target_dead(target: Node2D) -> bool:
    if target == null or not is_instance_valid(target): return true
    if "is_dead" in target: return bool(target.is_dead)
    return false

func shoot_projectile(target: Node2D) -> void:
    if stats == null or target == null:
        if _is_ballista_debug():
            print("[BALLISTA ATTACK][combat_ai_abort] hero_id=%s reason=missing_stats_or_target stats=%s target=%s" % [_debug_hero_id(), str(stats != null), str(target != null)])
        return
    var projectile_scene: PackedScene = stats.projectile_scene
    if projectile_scene == null and hero != null and "projectile_scene" in hero:
        projectile_scene = hero.projectile_scene
    if projectile_scene == null:
        if _is_ballista_debug():
            print("[BALLISTA ATTACK][combat_ai_abort] hero_id=%s reason=no_projectile_scene stats_scene=%s hero_scene=%s" % [_debug_hero_id(), str(stats.projectile_scene), str(hero.projectile_scene if hero != null and "projectile_scene" in hero else null)])
        return
    if _is_ballista_debug():
        print("[BALLISTA ATTACK][combat_ai] hero_id=%s target=%s projectile_scene=%s projectile_type=%s speed=%.2f spin=%.2f" % [
            _debug_hero_id(),
            _debug_target_name(target),
            str(projectile_scene),
            String(stats.projectile_type),
            stats.projectile_speed,
            stats.projectile_spin_speed_deg
        ])
    var proj = ProjectileSpawnHelperScript.spawn(
        projectile_scene,
        hero,
        target,
        _get_attack_damage(),
        stats.projectile_speed,
        stats.projectile_spin_speed_deg,
        Vector2(0.0, -20.0),
        stats.projectile_type
    )
    if proj == null:
        if _is_ballista_debug():
            print("[BALLISTA ATTACK][combat_ai_abort] hero_id=%s reason=spawn_returned_null scene=%s" % [_debug_hero_id(), str(projectile_scene)])
        return
    # Apply pending projectile damage multiplier (e.g. Long Shot distance bonus)
    if "damage_multiplier" in proj:
        var pending_mult: float = 1.0
        if "_pending_projectile_multiplier" in hero:
            pending_mult = float(hero._pending_projectile_multiplier)
            hero._pending_projectile_multiplier = 1.0
        proj.damage_multiplier = pending_mult


func _is_ballista_debug() -> bool:
    return hero != null and "hero_id" in hero and String(hero.hero_id).begins_with("ballista")


func _debug_hero_id() -> String:
    if hero == null or not ("hero_id" in hero):
        return "unknown"
    return String(hero.hero_id)


func _debug_target_name(target) -> String:
    if target == null or not is_instance_valid(target):
        return "null"
    return String(target.name)
            
func _get_attack_damage() -> float:
    var eng := Engine.get_main_loop() as SceneTree
    var hero_core = eng.root.get_node_or_null("/root/HeroCore") if eng else null
    if hero_core == null:
        return 1.0
        
    var hero_id = hero.hero_id if "hero_id" in hero else ""
    if hero_id == "": return 1.0
    
    var total_stats = hero_core.get_hero_total_stats(hero_id)
    if total_stats is Dictionary and total_stats.has("damage"):
        return float(total_stats.get("damage", 1.0))
    var hero_data = hero_core.get_hero(hero_id)
    return float(hero_data.get("damage", 1.0)) if hero_data is Dictionary else 1.0

func on_hit_landed(amount: float) -> void:
    total_damage_dealt += amount
