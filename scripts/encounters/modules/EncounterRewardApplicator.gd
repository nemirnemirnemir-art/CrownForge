extends RefCounted
class_name EncounterRewardApplicator

## Applies the rewards/effects of chosen encounter options

const EncounterResourcesScript := preload("res://scripts/encounters/modules/EncounterResources.gd")
const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

var _rng: RandomNumberGenerator
var _pending_ui_actions: Array[String] = []

func _init(rng: RandomNumberGenerator) -> void:
    _rng = rng

func apply_option(option: Dictionary, consume_all_callback: Callable, valid_ui_actions: Dictionary) -> bool:
    _pending_ui_actions.clear()

    if not consume_all_callback.call(option):
        return false

    var effects_var: Variant = option.get("effects", [])
    if not (effects_var is Array):
        return true

    for raw_effect in effects_var:
        if not (raw_effect is Dictionary):
            continue
        var effect: Dictionary = raw_effect
        var kind := String(effect.get("kind", ""))
        
        var applied := false
        if kind == "resource_add":
            applied = _apply_resource_add(effect)
        elif kind == "denarii_add":
            applied = _apply_denarii_add(effect)
        elif kind == "all_resources_add":
            applied = _apply_all_resources_add(effect)
        elif kind == "resource_consume":
            applied = _acknowledge_resource_spend(effect)
        elif kind == "resource_lose":
            applied = _acknowledge_resource_spend(effect)
        elif kind == "spell_add":
            applied = _apply_spell_add(effect)
        elif kind == "ui_action":
            applied = _apply_ui_action(effect, valid_ui_actions)
        elif kind == "troops_add":
            applied = _apply_troops_add(effect)
        elif kind == "morale_add":
            applied = _apply_morale_add(effect)
        elif kind == "building_add":
            applied = _apply_building_add(effect)
        elif kind == "spawn_enemy":
            applied = _apply_spawn_enemy(effect)
        elif kind == "transmute":
            applied = _apply_transmute(effect)
        elif kind == "gaze_upgrade":
            applied = _apply_gaze_upgrade()
        elif kind == "lose_troops":
            applied = _apply_lose_troops(effect)
        elif kind == "max_hp_add":
            applied = _apply_max_hp_add(effect)
            
        if not applied:
            return false

    return true

func consume_pending_ui_actions() -> Array[String]:
    var result: Array[String] = _pending_ui_actions.duplicate()
    _pending_ui_actions.clear()
    return result

func _apply_resource_add(effect: Dictionary) -> bool:
    var resource_core := _get_resource_core()
    if resource_core == null: return false
    var resource_id := EncounterResourcesScript.normalize_resource_id(String(effect.get("resource_id", "")))
    var amount := int(effect.get("amount", 0))
    if amount <= 0: return false
    resource_core.call("add_resource", resource_id, amount)
    return true

func _apply_denarii_add(effect: Dictionary) -> bool:
    var economy_core := _get_economy_core()
    if economy_core == null: return false
    var amount := int(effect.get("amount", 0))
    if amount <= 0: return false
    economy_core.call("add_gold", float(amount))
    return true

func _apply_all_resources_add(effect: Dictionary) -> bool:
    var resource_core := _get_resource_core()
    if resource_core == null: return false
    var amount := int(effect.get("amount", 0))
    if amount <= 0: return false
    for resource_id in EncounterResourcesScript.RESOURCE_IDS:
        resource_core.call("add_resource", resource_id, amount)
    return true

func _apply_resource_consume(effect: Dictionary) -> bool:
    var resource_core := _get_resource_core()
    if resource_core == null: return false
    var resource_id := EncounterResourcesScript.normalize_resource_id(String(effect.get("resource_id", "")))
    var amount := int(effect.get("amount", 0))
    if amount <= 0: return false
    return bool(resource_core.call("consume_resource", resource_id, amount))

func _acknowledge_resource_spend(effect: Dictionary) -> bool:
    var resource_id := EncounterResourcesScript.normalize_resource_id(String(effect.get("resource_id", "")))
    var amount := int(effect.get("amount", 0))
    return resource_id != "" and amount > 0

func _apply_spell_add(effect: Dictionary) -> bool:
    var spell_id := String(effect.get("spell_id", ""))
    var amount := int(effect.get("amount", 0))
    if amount <= 0 or spell_id == "": return false
    if not PathRegistryScript.spell_config_exists(spell_id): return false

    var panel_added := 0
    var spell_panel := _get_spell_panel()
    if spell_panel != null and spell_panel.has_method("add_spell"):
        var config := PathRegistryScript.load_spell_config(spell_id)
        if config != null:
            for _i in range(amount):
                if bool(spell_panel.call("add_spell", config)):
                    panel_added += 1

    if panel_added >= amount: return true
    var remaining := amount - panel_added
    var spell_core := _get_spell_core()
    if spell_core != null and spell_core.has_method("add_spell"):
        spell_core.call("add_spell", spell_id, remaining)
        return true
    return false

func _apply_ui_action(effect: Dictionary, valid_ui_actions: Dictionary) -> bool:
    var action_id := String(effect.get("action_id", ""))
    if action_id == "" or not valid_ui_actions.has(action_id): return false
    var count := maxi(1, int(effect.get("count", 1)))
    var chance_percent := clampi(int(effect.get("chance_percent", 100)), 1, 100)
    if _rng.randi_range(1, 100) > chance_percent: return true
    for _i in range(count):
        _pending_ui_actions.append(action_id)
    return true

func _apply_troops_add(effect: Dictionary) -> bool:
    var troop_id := String(effect.get("troop_id", ""))
    var amount := int(effect.get("amount", 0))
    if troop_id == "" or amount <= 0: return false

    var hero_core := _get_hero_core()
    if hero_core == null: return false

    for _i in range(amount):
        if not hero_core.has_method("ensure_hero_template"): return false
        hero_core.call("ensure_hero_template", troop_id, troop_id.capitalize(), 0.0)
        var new_id: String = str(hero_core.call("hire_hero_copy", troop_id))
        if new_id == "": continue
        if hero_core.has_method("update_hero"):
            hero_core.call("update_hero", new_id, {"is_hired": true, "isDead": false, "isActive": false})
        if hero_core.has_method("add_to_squad"):
            hero_core.call("add_to_squad", new_id)
    return true

func _apply_morale_add(effect: Dictionary) -> bool:
    var amount := int(effect.get("amount", 0))
    if amount == 0: return true
    var morale_system := _get_morale_system()
    if morale_system and morale_system.has_method("add_debug_morale"):
        morale_system.call("add_debug_morale", amount)
        return true
    return false

func _apply_building_add(effect: Dictionary) -> bool:
    var building_registry := _get_building_registry()
    if building_registry and building_registry.has_method("add_recipe"):
        var building_id := String(effect.get("building_id", ""))
        var amount := int(effect.get("amount", 0))
        if building_id != "" and amount > 0:
            building_registry.call("add_recipe", building_id, amount)
            return true
    return false

func _apply_spawn_enemy(effect: Dictionary) -> bool:
    var enemy_id := String(effect.get("enemy_id", ""))
    var amount := int(effect.get("amount", 0))
    if enemy_id == "" or amount <= 0: return false
    _pending_ui_actions.append("spawn_enemy:%s:%d" % [enemy_id, amount])
    return true

func _apply_transmute(effect: Dictionary) -> bool:
    var resource_core := _get_resource_core()
    if resource_core == null: return false
    var target_resource := EncounterResourcesScript.normalize_resource_id(String(effect.get("target_resource", "")))
    if not EncounterResourcesScript.resource_exists(target_resource): return false
    
    var total := 0
    for raw_resource_id in EncounterResourcesScript.RESOURCE_IDS:
        var resource_id := String(raw_resource_id)
        if resource_id == target_resource: continue
        var amount := int(resource_core.call("get_resource", resource_id))
        if amount > 0 and bool(resource_core.call("consume_resource", resource_id, amount)):
            total += amount
            
    if total > 0:
        resource_core.call("add_resource", target_resource, total)
    return true

func _apply_gaze_upgrade() -> bool:
    var gaze_core := _get_gaze_core()
    if gaze_core and gaze_core.has_method("try_upgrade"):
        return bool(gaze_core.call("try_upgrade"))
    return false

func _apply_lose_troops(effect: Dictionary) -> bool:
    var hero_core := _get_hero_core()
    if hero_core == null or not hero_core.has_method("remove_hero"):
        return false
    var amount := int(effect.get("amount", 0))
    if amount <= 0:
        return true

    var active_ids: Array[String] = []
    var active_ids_var: Variant = hero_core.get("active_hero_ids")
    if active_ids_var is Array:
        for raw_id in active_ids_var:
            active_ids.append(String(raw_id))
    if active_ids.is_empty():
        return true

    var random_pick := bool(effect.get("random", true))
    var removed := 0
    while removed < amount and not active_ids.is_empty():
        var index := active_ids.size() - 1
        if random_pick:
            index = _rng.randi_range(0, active_ids.size() - 1)
        var hero_id := String(active_ids[index])
        active_ids.remove_at(index)
        hero_core.call("remove_hero", hero_id)
        removed += 1
    return true

func _apply_max_hp_add(effect: Dictionary) -> bool:
    var castle_core := _get_castle_core()
    if castle_core == null or not castle_core.has_method("add_bonus_max_hp"):
        return false
    var amount := int(effect.get("amount", 0))
    if amount == 0:
        return true
    castle_core.call("add_bonus_max_hp", amount)
    return true

# --- Core Getters ---
func _get_resource_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    return tree.root.get_node_or_null("ResourceCore") if tree and tree.root else null

func _get_economy_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    return tree.root.get_node_or_null("EconomyCore") if tree and tree.root else null

func _get_spell_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    return tree.root.get_node_or_null("SpellCore") if tree and tree.root else null

func _get_hero_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    return tree.root.get_node_or_null("HeroCore") if tree and tree.root else null

func _get_morale_system() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    return tree.root.get_node_or_null("MoraleSystem") if tree and tree.root else null

func _get_building_registry() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    return tree.root.get_node_or_null("BuildingRegistry") if tree and tree.root else null

func _get_spell_panel() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    return tree.get_first_node_in_group("spell_panel") if tree else null

func _get_gaze_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    return tree.root.get_node_or_null("GazeCore") if tree and tree.root else null

func _get_castle_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    return tree.root.get_node_or_null("CastleCore") if tree and tree.root else null