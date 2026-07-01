extends RefCounted
class_name HeroOnFieldStats

const UnitConfigScript = preload("res://core/units/UnitConfig.gd")
const PathRegistryScript = preload("res://scripts/systems/PathRegistry.gd")

# Base Stats (defaults)
var is_melee: bool = true
var attack_range: float = 25.0
var max_range: float = 200.0
var preferred_range: float = 150.0
var min_range: float = 100.0
var attack_cooldown: float = 1.0
var projectile_speed: float = 400.0
var projectile_type: String = "arrow"
var projectile_spin_speed_deg: float = 0.0

# Resources
var projectile_scene: PackedScene = null

# Modifiers
var damage_taken_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
var evasion_chance: float = 0.0
var is_invincible: bool = false

# Effective Range Calculation
const ATTACK_TOLERANCE: float = 20.0

func get_effective_hit_range() -> float:
    return attack_range + ATTACK_TOLERANCE

func determine_combat_type(hero_id: String) -> void:
    var hero_core := _get_hero_core()
    if hero_core == null:
        return

    var hero_query: Variant = hero_core.get("query")
    if hero_query == null:
        return

    var icon_id: String = String(hero_query.call("get_hero_icon_id", hero_id))
    var unit_key := _resolve_unit_key(hero_id, icon_id)
    var unit_cfg := _load_unit_config(unit_key)
    if unit_cfg != null:
        _apply_from_unit_config(unit_cfg)
        return

    var icon_id_lower := icon_id.to_lower()
    if "slinger" in icon_id_lower:
        max_range = 250.0
        attack_range = 200.0
        is_melee = false
        projectile_type = "stone"
        projectile_speed = 400.0
        projectile_spin_speed_deg = 0.0
    elif "archer" in icon_id_lower or "crossbow" in icon_id_lower or "hunter" in icon_id_lower or "луч" in icon_id_lower: # "луч" check from original code
        max_range = 250.0
        attack_range = 200.0
        is_melee = false
        projectile_type = "arrow"
        projectile_speed = 400.0
        projectile_spin_speed_deg = 0.0
    else:
        is_melee = true
        # Default melee ranges
        attack_range = 25.0
        max_range = 200.0
        projectile_scene = null
        projectile_type = ""
        projectile_speed = 400.0
        projectile_spin_speed_deg = 0.0

func _get_hero_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("HeroCore")

func _resolve_unit_key(hero_id: String, icon_id: String) -> String:
    var key := icon_id.to_lower()
    if key == "":
        key = hero_id.to_lower()

    if key.contains("_"):
        var parts := key.rsplit("_", true, 1)
        if parts.size() == 2 and String(parts[1]).is_valid_int():
            key = String(parts[0])

    if key == "archer":
        key = "crossbowman"
    elif key == "clown":
        key = "madman"

    return key

func _load_unit_config(unit_id: String) -> Resource:
    if unit_id == "":
        return null

    return PathRegistryScript.load_unit_config(unit_id)

func _is_ranged_unit(cfg: Resource) -> bool:
    return HeroCombatTypeResolver.is_ranged_unit_config(cfg)

func _apply_from_unit_config(cfg: Resource) -> void:
    var cfg_attack := maxf(1.0, float(_get_cfg_value(cfg, "attack_range", 25.0)))
    var cfg_max := maxf(cfg_attack, float(_get_cfg_value(cfg, "max_range", 200.0)))

    attack_range = cfg_attack
    max_range = cfg_max
    preferred_range = lerpf(attack_range, max_range, 0.7)
    min_range = minf(attack_range, maxf(20.0, max_range * 0.5))

    projectile_speed = maxf(1.0, float(_get_cfg_value(cfg, "projectile_speed", 400.0)))
    projectile_type = String(_get_cfg_value(cfg, "projectile_type", "arrow")).strip_edges().to_lower()
    if projectile_type == "":
        projectile_type = "arrow"
    projectile_spin_speed_deg = float(_get_cfg_value(cfg, "projectile_spin_speed_deg", 0.0))

    if _is_ranged_unit(cfg):
        is_melee = false
        projectile_scene = null
    else:
        is_melee = true
        projectile_scene = null

func _get_cfg_value(cfg: Resource, prop: String, fallback: Variant) -> Variant:
    if cfg == null:
        return fallback
    if prop in cfg:
        return cfg.get(prop)
    return fallback

func apply_modifiers_from_core() -> void:
    # Placeholder for future integration with centralized stats
    pass
