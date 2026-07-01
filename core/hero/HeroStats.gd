extends RefCounted
class_name HeroStats

## Расчет статистики героев
## Базовые статы + экипировка + перки + баффы

var _hero_data: HeroData
var _hero_perks: HeroPerks
var _hero_buffs: HeroBuffs

func _init(hero_data: HeroData, hero_perks: HeroPerks, hero_buffs: HeroBuffs) -> void:
    _hero_data = hero_data
    _hero_perks = hero_perks
    _hero_buffs = hero_buffs

func get_hero_total_stats(hero_id: String) -> Dictionary:
    var stats = {
        "maxHp": 0.0,
        "damage": 0.0,
        "level": 1,
        "xp": 0,
        "xpToNext": 10
    }
    
    if not _hero_data.has_hero(hero_id):
        return stats
    
    var hero = _hero_data.get_hero(hero_id)
    var unit_id := _resolve_unit_id(hero_id)
    stats["level"] = hero.get("level", 1)
    stats["xp"] = hero.get("xp", 0)
    stats["xpToNext"] = hero.get("xpToNext", 10)
    
    # 1. Base Stats
    # CRITICAL FIX: Always use "base_*" stats as the source of truth to prevent compounding bonuses
    # when maxHp is updated and then read back as the "base" for the next calculation.
    var base_hp = hero.get("base_hp", 10.0)
    var base_damage = hero.get("base_damage", 5.0)
    
    # print("[HeroStats] Calculating for %s: base_hp=%.1f, base_damage=%.1f" % [hero_id, base_hp, base_damage])
    
    var troop_hp_mult := 1.0
    var troop_damage_mult := 1.0
    var troop_core: Object = _get_troop_bonus_core()
    if troop_core:
        troop_hp_mult = float(troop_core.call("get_unit_multiplier", unit_id, 0))
        troop_damage_mult = float(troop_core.call("get_unit_multiplier", unit_id, 1))
    if BuildingUpgradeCore:
        var unit_classes: Array = []
        if troop_core and troop_core.has_method("get_unit_classes"):
            var raw_unit_classes: Variant = troop_core.call("get_unit_classes", unit_id)
            if raw_unit_classes is Array:
                unit_classes = raw_unit_classes
        if unit_classes is Array and (unit_classes as Array).has(UnitConfig.UnitClass.CHAMPION):
            if BuildingUpgradeCore.has_method("get_kings_statue_champion_hp_multiplier"):
                troop_hp_mult *= float(BuildingUpgradeCore.get_kings_statue_champion_hp_multiplier())
            if BuildingUpgradeCore.has_method("get_kings_statue_champion_damage_multiplier"):
                troop_damage_mult *= float(BuildingUpgradeCore.get_kings_statue_champion_damage_multiplier())
        if unit_classes is Array and (unit_classes as Array).has(UnitConfig.UnitClass.ARCANE):
            if BuildingUpgradeCore.has_method("get_magic_ball_arcane_damage_multiplier"):
                troop_damage_mult *= float(BuildingUpgradeCore.get_magic_ball_arcane_damage_multiplier())
        # Building upgrade per-unit stat modifiers
        if BuildingUpgradeCore.has_method("get_unit_stat_hp_multiplier"):
            troop_hp_mult *= float(BuildingUpgradeCore.get_unit_stat_hp_multiplier(unit_id))
        if BuildingUpgradeCore.has_method("get_unit_stat_damage_multiplier"):
            troop_damage_mult *= float(BuildingUpgradeCore.get_unit_stat_damage_multiplier(unit_id))
        # Phase 2C: Hydra global damage aura (+10% per Hydra on field, cap 50%)
        if BuildingUpgradeCore.has_method("get_hydra_global_damage_multiplier"):
            troop_damage_mult *= float(BuildingUpgradeCore.get_hydra_global_damage_multiplier())
        # Phase 2C: Minotaur Flying buff (+3% dmg to Flying per Minotaur, cap 30%)
        if unit_classes is Array and (unit_classes as Array).has(UnitConfig.UnitClass.FLYING):
            if BuildingUpgradeCore.has_method("get_minotaur_flying_damage_multiplier"):
                troop_damage_mult *= float(BuildingUpgradeCore.get_minotaur_flying_damage_multiplier())
        # Phase 2C: Falcon Mentoring (+100% HP to Grunt troops when Black Swordsman present)
        if unit_classes is Array and (unit_classes as Array).has(UnitConfig.UnitClass.GRUNT):
            if BuildingUpgradeCore.has_method("get_falcon_mentoring_hp_multiplier"):
                troop_hp_mult *= float(BuildingUpgradeCore.get_falcon_mentoring_hp_multiplier())
        # Phase 2C: Lion Circus Versatility — Griffin uses best single class bonus
        if unit_id == "griffin" and BuildingUpgradeCore.has_method("is_lion_circus_versatility_active"):
            if bool(BuildingUpgradeCore.is_lion_circus_versatility_active()):
                # Override TroopBonusCore multipliers with Versatility best-of-all-classes
                if troop_core:
                    var lion_circus_script: Variant = null
                    if BuildingUpgradeCore.has_method("get_lion_circus_cost_multiplier"):
                        lion_circus_script = preload("res://core/building_upgrade/BuildingUpgradeLionCircus.gd")
                    if lion_circus_script != null:
                        troop_hp_mult = troop_hp_mult / maxf(float(troop_core.call("get_unit_multiplier", unit_id, 0)), 0.01) * float(lion_circus_script.get_versatility_hp_multiplier(troop_core))
                        troop_damage_mult = troop_damage_mult / maxf(float(troop_core.call("get_unit_multiplier", unit_id, 1)), 0.01) * float(lion_circus_script.get_versatility_damage_multiplier(troop_core))
        # Phase 2D: Troop Inspiration — +10% HP+DMG per class from production buildings
        # Note: CHAMPION already covered above via get_kings_statue_champion_hp_multiplier()
        if BuildingUpgradeCore.has_method("get_troop_inspiration_hp_multiplier"):
            for cls_int: int in unit_classes:
                if cls_int == UnitConfig.UnitClass.CHAMPION:
                    continue  # already handled via kings_statue path
                var cls_name: String = UnitConfig.UnitClass.keys()[cls_int]
                troop_hp_mult *= float(BuildingUpgradeCore.get_troop_inspiration_hp_multiplier(cls_name))
                troop_damage_mult *= float(BuildingUpgradeCore.get_troop_inspiration_damage_multiplier(cls_name))

    # 2. Equipment Stats
    var equip_hp = 0.0
    var equip_damage = 0.0
    
    var equipment = hero.get("equipment", {})
    if equipment is Dictionary:
        for slot in equipment:
            var item = equipment[slot]
            if item is Dictionary and not item.is_empty():
                equip_hp += item.get("hp_bonus", 0.0)
                
                var min_dmg = item.get("min_damage", 0.0)
                var max_dmg = item.get("max_damage", 0.0)
                if min_dmg > 0 or max_dmg > 0:
                    equip_damage += (min_dmg + max_dmg) / 2.0
                else:
                    equip_damage += item.get("damage_bonus", 0.0)
    
    # 3. Perk Modifiers & Global Bonuses
    var mods = _hero_perks.get_perk_modifiers(hero)
    var buff_mods = _hero_buffs.get_buff_modifiers(hero_id)
    
    var global_damage_percent = 0.0
    if TownCore:
        global_damage_percent = TownCore.get_global_damage_bonus()
    
    if MoraleSystem:
        global_damage_percent += MoraleSystem.get_damage_modifier()
    
    # 4. Mood Modifier
    # Mood 0..100
    # 0 -> 0.5x damage (-50%)
    # 50 -> 1.0x damage (0%)
    # 100 -> 1.5x damage (+50%)
    var mood = hero.get("mood", 50.0)
    var mood_multiplier = 0.5 + (mood / 100.0)
    
    # 5. Final Calculation
    var total_hp = (base_hp * troop_hp_mult) + equip_hp
    
    # Damage = (Base + Equip + FlatPerk) * (1 + PercentPerk + GlobalPercent + BuffPercent) * MoodMultiplier
    var flat_damage = mods["damage_bonus_flat"]
    var total_percent = mods["damage_bonus_percent"] + global_damage_percent + buff_mods["damage_bonus_percent"]
    var total_damage = ((base_damage * troop_damage_mult) + equip_damage + flat_damage) * (1.0 + total_percent) * mood_multiplier

    var until_ms := int(hero.get("temp_damage_bonus_until_ms", 0))
    if until_ms > 0 and Time.get_ticks_msec() < until_ms:
        var temp_bonus_pct := float(hero.get("temp_damage_bonus_percent", 0.0))
        if temp_bonus_pct != 0.0:
            total_damage *= (1.0 + temp_bonus_pct)

    var artifact_core: Object = _get_artifact_core()
    var artifact_flat_hp_bonus := 0.0
    var artifact_hp_multiplier := 1.0
    if artifact_core and artifact_core.has_method("get_unit_flat_hp_bonus"):
        artifact_flat_hp_bonus = float(artifact_core.call("get_unit_flat_hp_bonus"))
    if artifact_core and artifact_core.has_method("get_friendly_unit_hp_multiplier"):
        artifact_hp_multiplier = float(artifact_core.call("get_friendly_unit_hp_multiplier"))
    if artifact_core and artifact_core.has_method("get_unit_specific_hp_multiplier"):
        artifact_hp_multiplier *= float(artifact_core.call("get_unit_specific_hp_multiplier", unit_id))
    if artifact_core and artifact_core.has_method("get_friendly_unit_damage_multiplier"):
        total_damage *= float(artifact_core.call("get_friendly_unit_damage_multiplier"))
    if artifact_core and artifact_core.has_method("get_unit_specific_damage_multiplier"):
        total_damage *= float(artifact_core.call("get_unit_specific_damage_multiplier", unit_id))

    total_hp *= artifact_hp_multiplier
    total_hp += artifact_flat_hp_bonus
    stats["maxHp"] = total_hp
    stats["damage"] = total_damage
    
    return stats

func _resolve_unit_id(hero_id: String) -> String:
    var id := hero_id.to_lower()
    if id.contains("_"):
        var parts := id.rsplit("_", true, 1)
        if parts.size() == 2 and String(parts[1]).is_valid_int():
            return String(parts[0])
    return id

func _get_troop_bonus_core() -> Object:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    var root := tree.root
    if root == null:
        return null
    return root.get_node_or_null("TroopBonusCore")

func _get_artifact_core() -> Object:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    var root := tree.root
    if root == null:
        return null
    return root.get_node_or_null("ArtifactCore")

func get_hero_defense(hero_id: String) -> int:
    if not _hero_data.has_hero(hero_id):
        return 0
    
    var hero = _hero_data.get_hero(hero_id)
    var mods = _hero_perks.get_perk_modifiers(hero)
    var perk_defense = mods["armor_bonus"]
    var global_defense = 0
    
    if TownCore:
        global_defense = TownCore.get_global_defense_bonus()
    
    return int(perk_defense + global_defense)

func get_hero_xp_gain_multiplier(hero_id: String, active_hero_ids: Array[String]) -> float:
    var multiplier = 1.0
    
    # 1. Global Bonus (Academy)
    if TownCore:
        multiplier += TownCore.get_global_xp_bonus()
    
    # 2. Personal Perks (Fast Learner)
    if _hero_data.has_hero(hero_id):
        var hero = _hero_data.get_hero(hero_id)
        var mods = _hero_perks.get_perk_modifiers(hero)
        multiplier += mods["xp_bonus_percent"]
    
    # 3. Team Perks (Mentor) - check all active heroes
    for other_id in active_hero_ids:
        if other_id == hero_id:
            continue
        if _hero_data.has_hero(other_id):
            var other_hero = _hero_data.get_hero(other_id)
            var other_mods = _hero_perks.get_perk_modifiers(other_hero)
            multiplier += other_mods["team_xp_bonus_percent"]
    
    return multiplier
