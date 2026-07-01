extends "res://scripts/mob/states/MobState.gd"

## Mob attacks the Wall
## Наносит урон стене пока она не разрушена или пока не появится герой

var _wall_target: Node2D = null
var _attack_timer: float = 0.0
const ATTACK_COOLDOWN: float = 1.5
const WALL_ATTACK_RANGE_MELEE: float = 170.0
const WALL_ATTACK_RANGE_RANGED: float = 320.0
const WALL_REENGAGE_MARGIN: float = 8.0

func _get_wall_attack_range() -> float:
    if mob and mob.has_method("get_wall_attack_trigger_distance"):
        return float(mob.get_wall_attack_trigger_distance())
    if mob and mob.has_method("get_wall_attack_range"):
        return float(mob.get_wall_attack_range())
    # Ranged mobs attack from further away
    if mob.projectile_scene:
        return WALL_ATTACK_RANGE_RANGED
    return WALL_ATTACK_RANGE_MELEE

func enter() -> void:
    if not mob:
        return
    
    var tree := mob.get_tree()
    if mob.has_method("get_wall_target_node"):
        _wall_target = mob.get_wall_target_node()
    elif tree:
        _wall_target = tree.get_first_node_in_group("wall")
    
    if not _wall_target:
        if state_machine:
            state_machine.change_state("MobMoveState")
        return
    
    _attack_timer = 0.0
    
    if mob.animations:
        mob.animations.play_attack()

func update(delta: float) -> void:
    if not mob or not state_machine:
        return
    
    if mob.is_dead:
        state_machine.change_state("MobDeathState")
        return
    
    # Стена уничтожена
    if not _wall_target or not is_instance_valid(_wall_target):
        state_machine.change_state("MobMoveState")
        return
    
    # Приоритет: если есть герой в range - атакуем его
    if mob.combat:
        var hero = mob.combat.find_nearest_hero()
        if hero and mob.combat.is_in_attack_range(hero):
            mob.combat._combat_target = hero
            state_machine.change_state("MobAttackState")
            return
    
    # Проверяем дистанцию до стены
    var distance_to_wall = mob.get_distance_to_wall() if mob.has_method("get_distance_to_wall") else mob.global_position.distance_to(_wall_target.global_position)
    if distance_to_wall > _get_wall_attack_range() + WALL_REENGAGE_MARGIN:
        state_machine.change_state("MobMovingToWallState")
        return
    
    # Атакуем стену
    _attack_timer -= delta
    if _attack_timer <= 0.0:
        _attack_wall()
        _attack_timer = ATTACK_COOLDOWN

func _attack_wall() -> void:
    if not _wall_target or not is_instance_valid(_wall_target):
        return
    
    if mob.animations:
        mob.animations.play_attack()
    
    # For ranged mobs, fire projectile at wall
    if mob.projectile_scene and mob.has_method("fire_projectile"):
        mob.fire_projectile(_wall_target.global_position)
        if mob.combat:
            mob.combat.record_damage_dealt(mob.mob_damage)
    else:
        # Melee: direct damage to wall
        if _wall_target.has_method("take_damage"):
            var damage = int(mob.mob_damage) if mob.mob_damage > 0 else 1
            _wall_target.take_damage(damage)
            # Update mob statistics to prevent watchdog reset
            if mob.combat:
                mob.combat.record_damage_dealt(float(damage))

func exit() -> void:
    _wall_target = null
