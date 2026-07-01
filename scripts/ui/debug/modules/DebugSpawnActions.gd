extends RefCounted
class_name DebugSpawnActions

## Handles all debug action callbacks (spawn, reward menus, economy, morale, troop bonuses).
## Requires setup() to be called with the owning CanvasLayer node before use.

const HeroSceneRegistryScript = preload("res://scripts/hero/HeroSceneRegistry.gd")
const PathRegistryScript = preload("res://scripts/systems/PathRegistry.gd")
const _CatalogScript = preload("res://scripts/ui/debug/modules/DebugSpawnMenuCatalog.gd")
const ArtifactDebugPanelScene: PackedScene = preload("res://scenes/ui/artifacts/ArtifactDebugPanel.tscn")
const ItemSystemScript = preload("res://modules/inventory/item_system.gd")

var game_scene: Node2D = null
var hero_scene_map: Dictionary = {}

var _scene_holder: Node
var _artifact_debug_panel: Control = null
var _spawn_counter: int = 0

func setup(scene_holder: Node) -> void:
    _scene_holder = scene_holder

func find_game_scene() -> void:
    game_scene = _scene_holder.get_tree().get_first_node_in_group("game_scene")

func _ensure_game_scene() -> bool:
    if not game_scene:
        find_game_scene()
    if not game_scene:
        push_error("[DebugSpawnMenu] GameScene not found!")
        return false
    return true

# ---------------------------------------------------------------------------
# Hero spawning
# ---------------------------------------------------------------------------

func on_spawn_hero(hero_name: String) -> void:
    if not _ensure_game_scene():
        return
    var base_id := HeroSceneRegistryScript.resolve_unit_id(hero_name)
    if HeroCore != null and HeroCore.has_method("ensure_hero_template"):
        HeroCore.ensure_hero_template(base_id, base_id.capitalize(), 0.0)
    if HeroCore != null and HeroCore.query != null and HeroCore.query.has_method("has_hero") and bool(HeroCore.query.has_hero(base_id)):
        var new_id := ""
        if HeroCore.has_method("hire_hero_copy"):
            new_id = str(HeroCore.hire_hero_copy(base_id))
        # If economy blocks debug spawning, top-up gold once and retry.
        if new_id == "" and EconomyCore != null and EconomyCore.has_method("add_gold"):
            var tpl: Dictionary = HeroCore.get_hero(base_id)
            var cost := float(tpl.get("cost", 0.0)) if tpl is Dictionary else 0.0
            EconomyCore.add_gold(cost)
            if HeroCore.has_method("hire_hero_copy"):
                new_id = str(HeroCore.hire_hero_copy(base_id))
        if new_id != "":
            HeroCore.update_hero(new_id, {"is_hired": true, "isDead": false, "isActive": false})
            var total_stats: Dictionary = HeroCore.get_hero_total_stats(new_id)
            var mx := float(total_stats.get("maxHp", 10.0)) if total_stats is Dictionary else 10.0
            HeroCore.update_hero(new_id, {"hp": mx, "maxHp": mx})
            HeroCore.add_to_squad(new_id)
            if EventBus and EventBus.has_signal("hero_selected_for_ui"):
                EventBus.hero_selected_for_ui.emit(new_id)
            if game_scene.has_method("update_heroes_on_field"):
                game_scene.update_heroes_on_field()
            return
    var scene: PackedScene = hero_scene_map.get(base_id)
    if scene == null:
        scene = HeroSceneRegistryScript.load_scene(base_id)
    if not scene:
        push_error("[DebugSpawnMenu] Hero scene not found: %s" % base_id)
        return
    var hero = scene.instantiate()
    _spawn_counter += 1
    hero.name = "%s_debug_%d" % [base_id, _spawn_counter]
    var container = game_scene.get_node_or_null("WorldYSort/MapContainer/HeroPivot")
    if not container:
        container = game_scene.get_node_or_null("WorldYSort/MapContainer")
    if not container:
        container = game_scene
    var spawn_pos = MapMarkerService.get_bridge_position() + Vector2(randf_range(-50, 50), randf_range(-50, 50))
    container.add_child(hero)
    if not hero.is_in_group("hero"):
        hero.add_to_group("hero")
    if hero.has_method("initialize"):
        hero.initialize(base_id)
    if "is_debug_spawn" in hero:
        hero.is_debug_spawn = true
    hero.global_position = spawn_pos
    if "health" in hero and hero.health:
        hero.health.current_health = hero.health.max_health

func on_spawn_25_crossbowmen() -> void:
    for i in range(25):
        on_spawn_hero("crossbowman")
    print("[DebugSpawnMenu] Spawned 25 Crossbowmen near bridge")

func on_spawn_smallbones() -> void:
    if not _ensure_game_scene():
        return
    var skeleton_scene := HeroSceneRegistryScript.load_scene("small_bones")
    if skeleton_scene == null:
        push_error("[DebugSpawnMenu] Hero scene not found for unit: small_bones")
        return
    var skeleton = skeleton_scene.instantiate()
    var container = game_scene.get_node_or_null("WorldYSort/MapContainer")
    if not container:
        container = game_scene
    var spawn_pos = MapMarkerService.get_bridge_position() + Vector2(randf_range(-50, 50), randf_range(-50, 50))
    container.add_child(skeleton)
    skeleton.global_position = spawn_pos
    # Call initialize() to properly set up as permanent hero (same as GameSceneHeroes)
    if skeleton.has_method("initialize"):
        skeleton.initialize("small_bones")
    print("[DebugSpawnMenu] Spawned permanent SmallBones at %s" % spawn_pos)

# ---------------------------------------------------------------------------
# Hero debug (moved from HeroCard)
# ---------------------------------------------------------------------------

func _get_selected_hero_id() -> String:
    var tree := _scene_holder.get_tree()
    if tree == null:
        return ""
    var hero_card := tree.get_first_node_in_group("hero_card")
    if hero_card == null:
        return ""
    return hero_card.get("selected_hero_id") if "selected_hero_id" in hero_card else ""

func on_hero_add_xp(amount: int) -> void:
    var hero_id := _get_selected_hero_id()
    if hero_id == "":
        push_warning("[DebugSpawnMenu] No hero selected for adding XP")
        return
    if HeroCore == null or not HeroCore.heroes.has(hero_id):
        push_warning("[DebugSpawnMenu] Hero not found: %s" % hero_id)
        return
    var hero: Dictionary = HeroCore.heroes[hero_id]
    var current_xp: int = int(hero.get("xp", 0))
    var current_level: int = int(hero.get("level", 1))
    var xp_needed: int = int(hero.get("xp_to_next_level", 5))
    hero["xp"] = current_xp + amount
    # Check for level up
    while hero["xp"] >= xp_needed and xp_needed > 0:
        hero["level"] = current_level + 1
        hero["xp"] = hero["xp"] - xp_needed
        xp_needed = xp_needed + 5
        hero["xp_to_next_level"] = xp_needed
        current_level = hero["level"]
    HeroCore.update_hero(hero_id, hero)
    print("[DebugSpawnMenu] Added %d XP to %s (level=%d, xp=%d/%d)" % [amount, hero_id, hero["level"], hero["xp"], hero["xp_to_next_level"]])

func on_hero_kill() -> void:
    var hero_id := _get_selected_hero_id()
    if hero_id == "":
        push_warning("[DebugSpawnMenu] No hero selected for kill")
        return
    if HeroCore == null:
        return
    HeroCore.update_hero(hero_id, {"hp": 0, "isDead": true})
    print("[DebugSpawnMenu] Killed hero %s" % hero_id)

func on_hero_level_up() -> void:
    var hero_id := _get_selected_hero_id()
    if hero_id == "":
        push_warning("[DebugSpawnMenu] No hero selected for level up")
        return
    if HeroCore == null or not HeroCore.heroes.has(hero_id):
        push_warning("[DebugSpawnMenu] Hero not found: %s" % hero_id)
        return
    var hero: Dictionary = HeroCore.heroes[hero_id]
    var current_level: int = int(hero.get("level", 1))
    hero["level"] = current_level + 1
    HeroCore.update_hero(hero_id, hero)
    print("[DebugSpawnMenu] Leveled up hero %s to level %d" % [hero_id, hero["level"]])

func _get_equip_slot_name(item_type: int) -> String:
    match item_type:
        ItemSystemScript.ItemType.WEAPON:
            return "weapon"
        ItemSystemScript.ItemType.ARMOR:
            return "armor"
        ItemSystemScript.ItemType.HELMET:
            return "helmet"
        ItemSystemScript.ItemType.RING:
            return "ring"
    return ""

func on_equip_debug_item(cfg: Dictionary) -> void:
    var hero_id := _get_selected_hero_id()
    if hero_id == "":
        push_warning("[DebugSpawnMenu] No hero selected for equipping item")
        return
    if HeroCore == null or not HeroCore.heroes.has(hero_id):
        push_warning("[DebugSpawnMenu] Hero not found: %s" % hero_id)
        return

    var item_type: int = cfg.get("type", 0)
    var slot_name := _get_equip_slot_name(item_type)
    if slot_name == "":
        push_error("[DebugSpawnMenu] Unknown equipment slot for item type %d" % item_type)
        return

    var item := ItemSystemScript.create_item(
        cfg.get("id", "debug_item"),
        item_type,
        ItemSystemScript.Rarity.COMMON,
        cfg.get("icon", ""),
        cfg.get("hp", 0),
        cfg.get("damage", 0)
    )

    HeroCore.equip_item_to_hero(hero_id, item, slot_name)
    print("[DebugSpawnMenu] Equipped %s on hero %s (HP+%d, DMG+%d)" % [cfg.label, hero_id, cfg.hp, cfg.damage])

func on_strip_all_items() -> void:
    var hero_id := _get_selected_hero_id()
    if hero_id == "":
        push_warning("[DebugSpawnMenu] No hero selected for stripping items")
        return
    if HeroCore == null or not HeroCore.heroes.has(hero_id):
        push_warning("[DebugSpawnMenu] Hero not found: %s" % hero_id)
        return

    var slots: Array[String] = ["weapon", "armor", "helmet", "ring"]
    for slot in slots:
        HeroCore.unequip_item_from_hero(hero_id, slot)
    print("[DebugSpawnMenu] Stripped all items from hero %s" % hero_id)

# ---------------------------------------------------------------------------
# Mob spawning
# ---------------------------------------------------------------------------

func on_spawn_mob(mob_name: String) -> void:
    if not _ensure_game_scene():
        return
    
    # Map display name to enemy_id for waves manager
    var enemy_id := _map_display_name_to_enemy_id(mob_name)
    if enemy_id == "":
        push_error("[DebugSpawnMenu] Unknown mob name: %s" % mob_name)
        return
    
    # Delegate to game_scene which uses waves manager (portal spawn area, proper setup)
    # instead of direct instantiate() which caused castle spawning bug
    if game_scene.has_method("debug_spawn_enemy_id"):
        var spawned = game_scene.debug_spawn_enemy_id(enemy_id, 1)
        print("[DebugSpawnActions] Spawned %s (id=%s) via waves manager: %d mobs" % [mob_name, enemy_id, spawned])
    else:
        push_error("[DebugSpawnActions] GameScene missing debug_spawn_enemy_id method")


func _map_display_name_to_enemy_id(display_name: String) -> String:
    # Map UI display names to enemy_id snake_case
    # This ensures consistency with MobSceneRegistry IDs
    var name_map := {
        "GoblinBandit": "goblin_bandit",
        "BlueSlime": "blue_slime",
        "GoblinCrossbowman": "goblin_crossbowman",
        "GoblinSwordsman": "goblin_swordsman",
        "GoblinShaman": "goblin_shaman",
        "GoblinFireMage": "goblin_fire_mage",
        "GoblinLightningMage": "goblin_lightning_mage",
        "GoblinLizard": "goblin_lizard",
        "GoblinGiant": "goblin_giant",
        "WallBuster": "wall_buster",
        "GoblinBatRider": "goblin_bat_rider",
        "GoblinPig": "goblin_pig",
        "CrabRider": "crab_rider",
        "StoneGolem": "stone_golem",
        "Sunfaced": "sunfaced",
        "Dragon": "dragon",
        "Gnoll": "gnoll",
    }
    return name_map.get(display_name, "")

func on_spawn_homeseeker_boss() -> void:
    if not _ensure_game_scene():
        return
    if game_scene.has_method("spawn_homeseeker_boss"):
        game_scene.spawn_homeseeker_boss()

func on_spawn_minotaur_boss() -> void:
    if not _ensure_game_scene():
        return
    if game_scene.has_method("spawn_minotaur_boss"):
        game_scene.spawn_minotaur_boss()

func on_spawn_dragon() -> void:
    if not _ensure_game_scene():
        return
    if game_scene.has_method("spawn_dragon"):
        game_scene.spawn_dragon()

func on_clear_mobs() -> void:
    var mobs := _scene_holder.get_tree().get_nodes_in_group("enemy")
    for mob in mobs:
        if is_instance_valid(mob):
            mob.queue_free()

func on_jump_to_prophecy_1() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("debug_set_prophecy_level"):
        game_scene.debug_set_prophecy_level(1)

func on_jump_to_prophecy_2() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("debug_set_prophecy_level"):
        game_scene.debug_set_prophecy_level(2)

func on_jump_to_prophecy_3() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("debug_set_prophecy_level"):
        game_scene.debug_set_prophecy_level(3)

func on_jump_to_prophecy_4() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("debug_set_prophecy_level"):
        game_scene.debug_set_prophecy_level(4)

func on_force_boss_wave() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("debug_force_boss_wave"):
        game_scene.debug_force_boss_wave()

func on_skip_to_next_prophecy() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("debug_skip_to_next_prophecy_level"):
        game_scene.debug_skip_to_next_prophecy_level()

# ---------------------------------------------------------------------------
# Reward menus
# ---------------------------------------------------------------------------

func on_open_artifact_debug_grid() -> void:
    var tree := _scene_holder.get_tree()
    if tree == null:
        return
    if _artifact_debug_panel != null and is_instance_valid(_artifact_debug_panel):
        _artifact_debug_panel.queue_free()
        _artifact_debug_panel = null
        return
    _artifact_debug_panel = ArtifactDebugPanelScene.instantiate() as Control
    tree.root.add_child(_artifact_debug_panel)

func on_open_base_production_rewards() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("open_reward_menu_base_production"):
        game_scene.open_reward_menu_base_production()

func on_open_levy_barracks_rewards() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("open_reward_menu_levy_barracks"):
        game_scene.open_reward_menu_levy_barracks()

func on_open_artifact_rewards() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("open_reward_menu_artifacts"):
        game_scene.open_reward_menu_artifacts()

func on_open_troop_bonus_rewards() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("open_reward_menu_troop_bonuses"):
        game_scene.open_reward_menu_troop_bonuses()

func on_open_building_upgrade_rewards() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("open_reward_menu_building_upgrades"):
        game_scene.open_reward_menu_building_upgrades()

func on_open_resource_rewards() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("open_reward_menu_resources"):
        game_scene.open_reward_menu_resources(45)

func on_open_spells_rewards() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("open_reward_menu_spells"):
        game_scene.open_reward_menu_spells()

func on_open_legendary_spells_rewards() -> void:
    if not _ensure_game_scene(): return
    if game_scene.has_method("open_reward_menu_legendary_spells"):
        game_scene.open_reward_menu_legendary_spells()

# ---------------------------------------------------------------------------
# Spell / resources / economy / morale
# ---------------------------------------------------------------------------

func on_add_spell(spell_id: String) -> void:
    var config := PathRegistryScript.load_spell_config(spell_id) as SpellConfig
    if not config:
        var resolved_path := PathRegistryScript.resolve_spell_config_path(spell_id)
        push_error("[DebugSpawnMenu] Spell config not found for id '%s' (resolved path: %s)" % [spell_id, resolved_path])
        return
    var spell_panel = _scene_holder.get_tree().get_first_node_in_group("spell_panel")
    if spell_panel and spell_panel.has_method("add_spell"):
        spell_panel.add_spell(config)
    elif SpellCore and SpellCore.has_method("add_spell"):
        SpellCore.add_spell(spell_id, 1)
    else:
        push_warning("[DebugSpawnMenu] SpellPanel and SpellCore not available")

func on_add_all_resources() -> void:
    if not ResourceCore:
        push_error("[DebugSpawnMenu] ResourceCore not found!")
        return
    for res_id in ResourceCore.RESOURCE_IDS:
        ResourceCore.add_resource(res_id, 1000)
    print("[DebugSpawnMenu] Added 1000 of all resources")

func on_add_denarii() -> void:
    if EconomyCore:
        EconomyCore.add_gold(100.0)

func on_add_morale() -> void:
    if MoraleSystem:
        MoraleSystem.add_debug_morale(20)
        _print_morale_effects()
    else:
        push_error("[DebugSpawnMenu] MoraleSystem not available!")

func on_reset_morale() -> void:
    if MoraleSystem:
        MoraleSystem.reset_morale()
        MoraleSystem.calculate_morale()
        print("[DebugSpawnMenu] Reset Debug Morale to 0")
        _print_morale_effects()

func _print_morale_effects() -> void:
    var m = MoraleSystem.get_total_morale()
    var dmg := MoraleSystem.get_damage_modifier() * 100.0
    var prod := MoraleSystem.get_productivity_modifier() * 100.0
    print("[DebugSpawnMenu] Morale: %d => Damage Boost: +%.1f%%, Prod Boost: +%.1f%%" % [m, dmg, prod])

# ---------------------------------------------------------------------------
# Troop bonuses
# ---------------------------------------------------------------------------

func on_add_troop_bonus(class_id: int, stat_id: int) -> void:
    var troop_core: Object = _get_troop_bonus_core()
    if troop_core == null:
        push_warning("[DebugSpawnMenu] TroopBonusCore not found")
        return
    var amount := 0.15
    troop_core.call("add_bonus_percent", class_id, stat_id, amount)
    var pct := float(troop_core.call("get_bonus_percent", class_id, stat_id))
    print("[DebugSpawnMenu] Troop bonus: %s %s = %.0f%%" % [get_unit_class_name(class_id), ("HP" if stat_id == 0 else "DMG"), pct * 100.0])

func get_unit_class_name(class_id: int) -> String:
    match class_id:
        0: return "Grunt"
        1: return "Warrior"
        2: return "Ranged"
        3: return "Rider"
        4: return "Champion"
        5: return "Flying"
        6: return "Arcane"
        7: return "Undead"
    return "Unknown"

func _get_troop_bonus_core() -> Object:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    var root := tree.root
    if root == null:
        return null
    return root.get_node_or_null("TroopBonusCore")
