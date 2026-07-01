extends RefCounted
class_name KingSpellHudCasting

const GameSceneSpellsScript := preload("res://scripts/game_scene/GameSceneSpells.gd")
const CharacterCreationSpellCatalogScript := preload("res://scripts/ui/spells/CharacterCreationSpellCatalog.gd")

func try_cast_active(hud: Control, config: Resource) -> void:
    var eng := Engine.get_main_loop() as SceneTree
    var king_state = eng.root.get_node_or_null("/root/KingSpellState") if eng else null

    if king_state == null or config == null:
        return
        
    var spell_id = String(config.get("spell_id") if config.get("spell_id") else "")
    if not king_state.can_activate_active_ability(spell_id):
        return
    if king_state.get_active_cooldown(spell_id) > 0.0:
        return
        
    var success := false
    match spell_id:
        "tough_guys":
            success = _spawn_allied_units("peasant", 3 + king_state.active_upgrade_level)
        "pocket_demons":
            success = _spawn_scaled_unit("familiar", 1.0 + 0.25 * float(king_state.active_upgrade_level))
        "fast_production":
            king_state.apply_productivity_bonus(0.32 + (0.08 * float(king_state.active_upgrade_level)), 25.0)
            success = true
        "forced_tax":
            var game_scene: Node = hud._get_game_scene()
            if game_scene and game_scene.has_method("enqueue_resource_choice_reward"):
                game_scene.enqueue_resource_choice_reward(100)
                success = true
            elif game_scene and game_scene.has_method("open_reward_menu_resources"):
                game_scene.open_reward_menu_resources(100)
                success = true
        "boys_at_work":
            king_state.apply_productivity_bonus(1.0 + (0.25 * float(king_state.active_upgrade_level)), 15.0)
            success = true
        "training":
            success = _apply_training_buff(100 + 25 * king_state.active_upgrade_level)
        _:
            var game_scene_fallback: Node = hud._get_game_scene()
            if game_scene_fallback:
                var world_pos: Vector2 = game_scene_fallback.get_global_mouse_position()
                success = GameSceneSpellsScript.cast_spell(game_scene_fallback, config, world_pos)
                
    if success:
        if not king_state.spend_active_ability_cost(spell_id):
            return
        var cooldown := CharacterCreationSpellCatalogScript.get_spell_effective_cooldown(spell_id, int(king_state.active_upgrade_level))
        king_state.set_active_cooldown(spell_id, cooldown)

func try_activate_passive(hud: Control, spell_id: String) -> void:
    var eng := Engine.get_main_loop() as SceneTree
    var king_state = eng.root.get_node_or_null("/root/KingSpellState") if eng else null
    var resource_core = eng.root.get_node_or_null("/root/ResourceCore") if eng else null
    var castle_core = eng.root.get_node_or_null("/root/CastleCore") if eng else null
    var morale_sys = eng.root.get_node_or_null("/root/MoraleSystem") if eng else null

    if king_state == null or spell_id == "" or king_state.is_passive_used(spell_id):
        return
    if not king_state.can_activate_passive_ability(spell_id):
        return
        
    var success := false
    match spell_id:
        "lumberjack":
            if resource_core:
                resource_core.add_resource("wood", 300)
                success = true
        "reward":
            var gs_reward: Node = hud._get_game_scene()
            if gs_reward and gs_reward.has_method("enqueue_established_production_reward"):
                gs_reward.enqueue_established_production_reward()
                success = true
            elif gs_reward and gs_reward.has_method("open_reward_menu_established_production"):
                gs_reward.open_reward_menu_established_production()
                success = true
        "good_reward":
            var gs_art: Node = hud._get_game_scene()
            if gs_art and gs_art.has_method("enqueue_artifact_reward"):
                gs_art.enqueue_artifact_reward()
                success = true
            elif gs_art and gs_art.has_method("open_reward_menu_artifacts"):
                gs_art.open_reward_menu_artifacts()
                success = true
        "last_chance":
            if castle_core and castle_core.get_effective_max_hp() > 0 and float(castle_core.current_hp) / float(castle_core.get_effective_max_hp()) <= 0.3:
                success = _spawn_allied_units("militia", 10)
        "spells_for_work":
            var gs_spells: Node = hud._get_game_scene()
            if gs_spells and gs_spells.has_method("open_reward_menu_spells"):
                gs_spells.open_reward_menu_spells()
                success = true
        "spicy_boys":
            if morale_sys and morale_sys.get_total_morale() >= 70:
                success = _spawn_allied_units("bumblebee", 10)
                
    if success:
        king_state.mark_passive_used(spell_id)

func _spawn_allied_units(base_id: String, count: int) -> bool:
    var spawned := false
    for i in range(max(0, count)):
        if _spawn_scaled_unit(base_id, 1.0):
            spawned = true
    return spawned

func _spawn_scaled_unit(base_id: String, stat_multiplier: float) -> bool:
    var eng := Engine.get_main_loop() as SceneTree
    var hero_core = eng.root.get_node_or_null("/root/HeroCore") if eng else null

    if hero_core == null:
        return false
    hero_core.ensure_hero_template(base_id, String(base_id).capitalize().replace("_", " "), 0.0)
    var new_id: String = hero_core.hire_hero_copy(base_id)
    if new_id == "":
        return false
    var total_stats = hero_core.get_hero_total_stats(new_id)
    var max_hp := 10.0
    var damage := 1.0
    if total_stats is Dictionary:
        max_hp = float(total_stats.get("maxHp", 10.0))
        damage = float(total_stats.get("damage", 1.0))
    var updates := {
        "cost": 0.0,
        "maxHp": max_hp * stat_multiplier,
        "hp": max_hp * stat_multiplier,
        "damage": damage * stat_multiplier,
        "base_damage": damage * stat_multiplier,
        "base_hp": max_hp * stat_multiplier,
        "is_summon": true,
    }
    hero_core.update_hero(new_id, updates)
    hero_core.add_to_squad(new_id)
    return true

func _apply_training_buff(hp_bonus: int) -> bool:
    var eng := Engine.get_main_loop() as SceneTree
    var hero_core = eng.root.get_node_or_null("/root/HeroCore") if eng else null

    if hero_core == null:
        return false
    var applied := false
    for hero in hero_core.get_active_heroes():
        if not (hero is Dictionary):
            continue
        var hero_id := String(hero.get("id", ""))
        if hero_id == "":
            continue
        var current_max := float(hero.get("maxHp", 0.0))
        var current_hp := float(hero.get("hp", 0.0))
        hero_core.update_hero(hero_id, {
            "maxHp": current_max + hp_bonus,
            "hp": current_hp + hp_bonus,
            "base_hp": float(hero.get("base_hp", current_max)) + hp_bonus,
        })
        applied = true
    return applied
