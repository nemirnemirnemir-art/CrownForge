extends RefCounted
class_name ArtifactClassBonuses

const TROOP_STAT_HP: int = 0
const TROOP_STAT_DAMAGE: int = 1
const TROOP_STAT_ATTACK_SPEED: int = 2

static func is_class_bonus_effect(artifact_id: String) -> bool:
    var def := ArtifactCatalog.get_def(artifact_id)
    var kind := str(def.get("effect_kind", ""))
    return (
        kind == "troop_all_hp_percent"
        or kind == "troop_all_damage_percent"
        or kind == "troop_all_attack_speed_percent"
        or kind == "troop_class_hp_percent"
        or kind == "troop_class_damage_percent"
        or kind == "troop_class_attack_speed_percent"
        or kind == "samurai_helm_bundle"
        or artifact_id == "golden_wings"
    )

static func apply_class_bonus(artifact_id: String, sign: float, troop_core: Node) -> void:
    var def := ArtifactCatalog.get_def(artifact_id)
    var kind := str(def.get("effect_kind", ""))
    var amount := float(def.get("effect_value", 0.0)) * sign
    if is_zero_approx(amount):
        return
    
    if kind == "troop_all_hp_percent":
        _apply_bonus_all_classes(troop_core, TROOP_STAT_HP, amount)
    elif kind == "troop_all_damage_percent":
        _apply_bonus_all_classes(troop_core, TROOP_STAT_DAMAGE, amount)
    elif kind == "troop_all_attack_speed_percent":
        _apply_bonus_all_classes(troop_core, TROOP_STAT_ATTACK_SPEED, amount)
    elif kind == "troop_class_hp_percent":
        _apply_bonus_single_class(troop_core, str(def.get("effect_unit_class", "")), TROOP_STAT_HP, amount)
    elif kind == "troop_class_damage_percent":
        _apply_bonus_single_class(troop_core, str(def.get("effect_unit_class", "")), TROOP_STAT_DAMAGE, amount)
    elif kind == "troop_class_attack_speed_percent":
        _apply_bonus_single_class(troop_core, str(def.get("effect_unit_class", "")), TROOP_STAT_ATTACK_SPEED, amount)
    elif kind == "samurai_helm_bundle":
        var unit_class_name := str(def.get("effect_unit_class", "warrior"))
        _apply_bonus_single_class(troop_core, unit_class_name, TROOP_STAT_HP, amount)
        _apply_bonus_single_class(troop_core, unit_class_name, TROOP_STAT_DAMAGE, amount)
        _apply_bonus_single_class(troop_core, unit_class_name, TROOP_STAT_ATTACK_SPEED, amount)
    elif artifact_id == "golden_wings":
        _apply_bonus_single_class(troop_core, "flying", TROOP_STAT_ATTACK_SPEED, 0.30 * sign)

static func reapply_all(active: Dictionary, runtime_applied: Dictionary, troop_core: Node) -> void:
    clear_all(runtime_applied, troop_core)
    for artifact_id in active.keys():
        var id := str(artifact_id)
        if is_class_bonus_effect(id):
            apply_class_bonus(id, 1.0, troop_core)
            runtime_applied[id] = true

static func clear_all(runtime_applied: Dictionary, troop_core: Node) -> void:
    for artifact_id in runtime_applied.keys():
        apply_class_bonus(str(artifact_id), -1.0, troop_core)
    runtime_applied.clear()

static func _apply_bonus_all_classes(troop_core: Node, stat_id: int, amount: float) -> void:
    if troop_core == null or not troop_core.has_method("add_bonus_percent"):
        return
    var class_count := int(UnitConfig.UnitClass.UNDEAD) + 1
    for class_id in range(class_count):
        troop_core.call("add_bonus_percent", class_id, stat_id, amount)

static func _apply_bonus_single_class(troop_core: Node, unit_class_name: String, stat_id: int, amount: float) -> void:
    var class_id := resolve_unit_class(unit_class_name)
    if class_id < 0:
        return
    if troop_core == null or not troop_core.has_method("add_bonus_percent"):
        return
    troop_core.call("add_bonus_percent", class_id, stat_id, amount)

static func resolve_unit_class(unit_class_name: String) -> int:
    match unit_class_name.strip_edges().to_lower():
        "grunt":
            return int(UnitConfig.UnitClass.GRUNT)
        "warrior":
            return int(UnitConfig.UnitClass.WARRIOR)
        "ranged":
            return int(UnitConfig.UnitClass.RANGED)
        "rider":
            return int(UnitConfig.UnitClass.RIDER)
        "champion":
            return int(UnitConfig.UnitClass.CHAMPION)
        "flying":
            return int(UnitConfig.UnitClass.FLYING)
        "arcane":
            return int(UnitConfig.UnitClass.ARCANE)
        "undead":
            return int(UnitConfig.UnitClass.UNDEAD)
        _:
            return -1
