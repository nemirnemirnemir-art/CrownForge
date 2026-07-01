extends RefCounted
class_name MobProjectileFlow

const ProjectileSpawnHelperScript := preload("res://scripts/combat/ProjectileSpawnHelper.gd")


func fire_projectile(mob, target_pos: Vector2, target_node: Node2D = null):
    if mob == null or mob.projectile_scene == null:
        return null
    var projectile_type := "default"
    if "projectile_type" in mob:
        projectile_type = String(mob.get("projectile_type"))
    if target_node != null and is_instance_valid(target_node):
        var target_speed: float = float(mob.projectile_speed) if "projectile_speed" in mob else 400.0
        var target_spin: float = float(mob.projectile_spin_speed_deg) if "projectile_spin_speed_deg" in mob else 0.0
        return ProjectileSpawnHelperScript.spawn(
            mob.projectile_scene,
            mob,
            target_node,
            float(mob.mob_damage),
            target_speed,
            target_spin,
            Vector2(0.0, -20.0),
            projectile_type
        )
    var wall_target: Node2D = null
    var wall = mob.get_tree().get_first_node_in_group("wall")
    if wall and is_instance_valid(wall) and wall is Node2D:
        var wall2d := wall as Node2D
        if wall2d.global_position.distance_to(target_pos) < 40.0:
            wall_target = wall2d
    var hero_target: Node2D = null
    if wall_target == null and mob.combat:
        hero_target = mob.combat.get_combat_target()
        if hero_target and not is_instance_valid(hero_target):
            hero_target = null
    var resolved_target: Node2D = wall_target if wall_target != null else hero_target
    if resolved_target == null:
        return null

    var projectile_speed: float = float(mob.projectile_speed) if "projectile_speed" in mob else 400.0
    var projectile_spin_speed_deg: float = float(mob.projectile_spin_speed_deg) if "projectile_spin_speed_deg" in mob else 0.0
    return ProjectileSpawnHelperScript.spawn(
        mob.projectile_scene,
        mob,
        resolved_target,
        float(mob.mob_damage),
        projectile_speed,
        projectile_spin_speed_deg,
        Vector2(0.0, -20.0),
        projectile_type
    )
