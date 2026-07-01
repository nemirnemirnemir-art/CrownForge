extends RefCounted
class_name MobStats

## Handles stats, config, and modifiers for Mob

var mob: Node

# Base config
var mob_kind: String = ""
var move_speed: float = 50.0
var invert_visual_facing: bool = false
var attack_range: float = 25.0
var aggro_range: float = 200.0
var mob_damage: float = 1.0
var heal_amount: float = 19.0
var projectile_scene: PackedScene = null

const MELEE_OVER_RANGED_SPEED_RATIO: float = 1.15
const GIANT_SPEED_MULTIPLIER: float = 0.75

# Buff/Debuff modifiers (for spells)
var damage_taken_multiplier: float = 1.0  # Frailty: 1.3
var speed_multiplier: float = 1.0  # Slow Zone: 0.5, Weakness: 0.7
var spawn_speed_multiplier: float = 1.0
var spawn_speed_variance_percent: int = 0
var attack_speed_multiplier: float = 1.0  # Weakness: 0.7
var evasion_chance: float = 0.0  # Evasion spell: 0.35
var is_invincible: bool = false  # Immortality spell

func setup(mob_ref: Node, speed: float, invert: bool, atk_range: float, aggro: float, dmg: float, heal: float, proj: PackedScene) -> void:
    mob = mob_ref
    move_speed = speed
    invert_visual_facing = invert
    attack_range = atk_range
    aggro_range = aggro
    mob_damage = dmg
    heal_amount = heal
    projectile_scene = proj
    
    mob_kind = _infer_kind_from_name()
    _setup_kind_stats()

func _infer_kind_from_name() -> String:
    return "goblin"

func _setup_kind_stats() -> void:
    var base_speed: float = move_speed
    if _is_giant_mob():
        move_speed = base_speed * GIANT_SPEED_MULTIPLIER
        return
    if is_ranged_mob():
        move_speed = base_speed / MELEE_OVER_RANGED_SPEED_RATIO

func is_ranged_mob() -> bool:
    if projectile_scene != null:
        return true
    if attack_range >= 150.0:
        return true
    var n := mob.name.to_lower()
    if n.contains("crossbow") or n.contains("mage") or n.contains("shaman"):
        return true
    return false

func _is_giant_mob() -> bool:
    var n := mob.name.to_lower()
    if n.contains("giant"):
        return true
    if mob.has_method("get_scene_file_path"):
        var p := mob.get_scene_file_path().to_lower()
        if p.contains("goblingiant") or p.contains("goblin_giant"):
            return true
    return false

func is_boss_mob() -> bool:
    if mob.is_in_group("boss"):
        return true
    var n := mob.name.to_lower()
    if n.contains("boss") or n.contains("homeseeker") or n.contains("minotaur") or n.contains("dragon"):
        return true
    if mob.has_method("get_scene_file_path"):
        var p := mob.get_scene_file_path().to_lower()
        return p.contains("/bosses/") or p.contains("boss")
    return false

func get_effective_speed() -> float:
    return move_speed * speed_multiplier * spawn_speed_multiplier

func apply_spawn_speed_variance(multiplier: float) -> void:
    spawn_speed_multiplier = maxf(0.05, multiplier)
    spawn_speed_variance_percent = int(round((spawn_speed_multiplier - 1.0) * 100.0))

func get_effective_damage(amount: float) -> float:
    return amount * damage_taken_multiplier

func apply_damage_modifiers(amount: float) -> float:
    if is_invincible:
        return 0.0
    if evasion_chance > 0.0 and randf() < evasion_chance:
        return -1.0 # -1 means evaded
    return get_effective_damage(amount)
