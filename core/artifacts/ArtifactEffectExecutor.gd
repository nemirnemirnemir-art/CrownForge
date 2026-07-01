extends RefCounted
class_name ArtifactEffectExecutor

const BASIC_RANDOM_RESOURCE_IDS: Array[String] = ["water", "wood", "clay", "iron_ore", "wheat", "gold"]
const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

static func apply_on_pickup(artifact_id: String, state: Dictionary) -> Variant:
    var resource_core := _get_resource_core()
    var def := ArtifactCatalog.get_def(artifact_id)
    var kind := str(def.get("effect_kind", ""))
    if kind == "on_pickup_add_resource":
        if resource_core != null and resource_core.has_method("add_resource"):
            resource_core.call("add_resource", str(def.get("effect_resource_id", "")), int(def.get("effect_value", 0)))
    elif kind == "on_pickup_add_all_resources":
        if resource_core != null and resource_core.has_method("get_all_resources") and resource_core.has_method("add_resource"):
            var amount := int(def.get("effect_value", 0))
            var all_resources: Variant = resource_core.call("get_all_resources")
            var keys: Array = []
            if all_resources is Dictionary:
                keys = (all_resources as Dictionary).keys()
            for k in keys:
                resource_core.call("add_resource", str(k), amount)
    elif kind == "build_cost_refund_full_next_n":
        ArtifactState.set_int(state, artifact_id, "build_refund_remaining", int(def.get("effect_value", 0)))
    elif kind == "on_pickup_add_spell":
        var spell_id := str(def.get("effect_spell_id", ""))
        var spell_amount := int(def.get("effect_value", 0))
        if spell_id != "" and spell_amount > 0:
            var pending_spell_rewards: Array[Dictionary] = []
            for i in range(spell_amount):
                pending_spell_rewards.append({
                    "type": "spell_grant",
                    "spell_id": spell_id,
                })
            return {"pending_rewards": pending_spell_rewards}
    elif kind == "on_pickup_add_random_spells":
        ArtifactSpellRewards.add_random_spells(int(def.get("effect_value", 0)), bool(def.get("effect_include_legendary", true)))
    elif kind == "on_pickup_open_spell_choice":
        return {"queue_spell": true, "count": int(def.get("effect_value", 1)), "legendary_only": bool(def.get("effect_legendary_only", false))}
    elif kind == "on_pickup_queue_resource_choice":
        var reward_count: int = max(0, int(def.get("effect_count", 1)))
        var reward_amount: int = int(def.get("effect_value", 0))
        if reward_count > 0 and reward_amount > 0:
            var pending_rewards: Array[Dictionary] = []
            for i in range(reward_count):
                pending_rewards.append({
                    "type": "resource_choice",
                    "amount": reward_amount,
                })
            return {"pending_rewards": pending_rewards}
    elif artifact_id == "super_metal":
        add_building_recipes(["forge"], 1)
    elif artifact_id == "enchanted_totem":
        _apply_random_seals(2, int(SealConfig.SealTier.NORMAL))
    elif artifact_id == "trusty_compass":
        _apply_random_seals(3, int(SealConfig.SealTier.LEGENDARY))
    return null

static func on_enemy_spawned(mob: Node) -> void:
    if mob == null or not is_instance_valid(mob):
        return
    for artifact_id in _get_active_artifact_ids():
        if str(artifact_id) != "golden_arrow":
            continue
        var max_hp := 0.0
        if "stats" in mob and mob.stats != null and "max_hp" in mob.stats:
            max_hp = float(mob.stats.max_hp)
        elif "max_health" in mob:
            max_hp = float(mob.max_health)
        if max_hp <= 0.0:
            continue
        if mob.has_method("take_damage"):
            mob.take_damage(int(round(max_hp * 0.10)))

static func on_wine_spent(active: Dictionary, state: Dictionary, amount: int) -> bool:
    if amount <= 0 or not active.has("wine_cup"):
        return false
    var next_total := ArtifactState.get_int(state, "wine_cup", "wine_spent", 0) + amount
    ArtifactState.set_int(state, "wine_cup", "wine_spent", next_total)
    var granted := ArtifactState.get_int(state, "wine_cup", "granted_morale", 0)
    var target_granted := int(floor(float(next_total) / 30.0))
    if target_granted > granted:
        ArtifactState.set_int(state, "wine_cup", "granted_morale", target_granted)
    return true

static func apply_on_activated(artifact_id: String, state: Dictionary, runtime_applied: Dictionary, troop_core: Node) -> void:
    if ArtifactClassBonuses.is_class_bonus_effect(artifact_id) and not runtime_applied.has(artifact_id):
        ArtifactClassBonuses.apply_class_bonus(artifact_id, 1.0, troop_core)
        runtime_applied[artifact_id] = true
    _refresh_dependent_systems()

static func apply_on_deactivated(artifact_id: String, state: Dictionary, runtime_applied: Dictionary, troop_core: Node) -> void:
    if runtime_applied.has(artifact_id):
        ArtifactClassBonuses.apply_class_bonus(artifact_id, -1.0, troop_core)
        runtime_applied.erase(artifact_id)
    
    var def := ArtifactCatalog.get_def(artifact_id)
    var kind := str(def.get("effect_kind", ""))
    if kind == "periodic_random_enemy_damage":
        ArtifactState.set_float(state, artifact_id, "periodic_damage_accum", 0.0)
    elif kind == "periodic_class_regen_hp_per_sec":
        ArtifactState.set_float(state, artifact_id, "periodic_class_regen_accum", 0.0)
    
    _refresh_dependent_systems()

static func try_revive_castle(active: Dictionary, state: Dictionary) -> bool:
    var castle_core := _get_castle_core()
    for artifact_id in active.keys():
        var def := ArtifactCatalog.get_def(str(artifact_id))
        if def.get("effect_kind", "") != "on_castle_zero_hp_heal_and_stun_once":
            continue
        var used := ArtifactState.get_int(state, str(artifact_id), "used", 0)
        if used > 0:
            continue
        ArtifactState.set_int(state, str(artifact_id), "used", 1)
        if castle_core != null and castle_core.has_method("heal"):
            castle_core.call("heal", int(def.get("effect_value", 0)))
        ArtifactHealDamage.stun_all_enemies(7.0)
        return true
    return false

static func consume_full_refund_charge(active: Dictionary, state: Dictionary) -> bool:
    var artifact_id := "free_housing"
    if not active.has(artifact_id):
        return false
    var remaining := ArtifactState.get_int(state, artifact_id, "build_refund_remaining", 0)
    if remaining <= 0:
        return false
    ArtifactState.set_int(state, artifact_id, "build_refund_remaining", remaining - 1)
    return true

static func apply_build_refund(active: Dictionary, state: Dictionary, paid_costs: Array[Dictionary], base_refund_pct: float) -> void:
    var resource_core := _get_resource_core()
    if resource_core == null or not resource_core.has_method("add_resource"):
        return
    
    var full_refund := consume_full_refund_charge(active, state)
    var refund_pct := base_refund_pct
    if full_refund:
        refund_pct = 1.0
    
    if refund_pct <= 0.0:
        return
    
    for entry in paid_costs:
        var resource_id: String = str(entry.get("resource_id", ""))
        var amount: int = int(entry.get("amount", 0))
        if resource_id == "" or amount <= 0:
            continue
        var refund := int(round(float(amount) * refund_pct))
        if refund > 0:
            resource_core.call("add_resource", resource_id, refund)

static func on_spell_cast(active_or_spell_id: Variant, maybe_state: Variant = null, maybe_spell_id: Variant = null) -> bool:
    var spell_id := ""
    var active: Dictionary = {}
    var state: Dictionary = {}
    var artifact_core: Node = null
    var emit_changes_locally := false

    if active_or_spell_id is Dictionary:
        active = active_or_spell_id as Dictionary
        if maybe_state is Dictionary:
            state = maybe_state as Dictionary
        spell_id = str(maybe_spell_id)
    else:
        spell_id = str(active_or_spell_id)
        artifact_core = _get_artifact_core()
        active = _get_active_artifacts(artifact_core)
        state = _get_artifact_state(artifact_core)
        emit_changes_locally = true

    if spell_id.strip_edges() == "":
        return false

    var changed := false
    for artifact_id in active.keys():
        var aid := str(artifact_id)
        var def := ArtifactCatalog.get_def(aid)
        var kind := str(def.get("effect_kind", ""))
        if kind == "on_spell_cast_heal_castle":
            var castle_core := _get_castle_core()
            if castle_core != null and castle_core.has_method("heal"):
                castle_core.call("heal", int(def.get("effect_value", 0)))
        elif kind == "troop_all_hp_flat_per_resolved_spell_cast" or aid == "chi_fan":
            var next_total := ArtifactState.get_int(state, aid, "resolved_spell_casts", 0) + 1
            ArtifactState.set_int(state, aid, "resolved_spell_casts", next_total)
            changed = true

    if emit_changes_locally and changed:
        if artifact_core != null:
            artifact_core.set("_state", state)
        _emit_artifacts_changed(artifact_core)
        _request_save()
    return changed

static func add_building_recipes(building_ids_variant: Variant, amount_each: int) -> void:
    var building_registry := _get_building_registry()
    if building_registry == null or not building_registry.has_method("add_recipe"):
        return
    if amount_each <= 0:
        return
    if not (building_ids_variant is Array):
        return
    for raw_id in (building_ids_variant as Array):
        var building_id := str(raw_id)
        if building_id == "":
            continue
        building_registry.call("add_recipe", building_id, amount_each)

static func add_random_basic_resource(amount: int) -> void:
    var resource_core := _get_resource_core()
    if amount <= 0 or resource_core == null or not resource_core.has_method("add_resource"):
        return
    if BASIC_RANDOM_RESOURCE_IDS.is_empty():
        return
    var pick := BASIC_RANDOM_RESOURCE_IDS[randi() % BASIC_RANDOM_RESOURCE_IDS.size()]
    resource_core.call("add_resource", str(pick), amount)

static func _refresh_dependent_systems() -> void:
    var population_core := _get_population_core()
    if population_core != null and population_core.has_signal("population_limit_changed") and population_core.has_method("get_max_population"):
        population_core.emit_signal("population_limit_changed", population_core.call("get_max_population"))
    var morale_system := _get_morale_system()
    if morale_system != null and morale_system.has_method("calculate_morale"):
        morale_system.call("calculate_morale")
    var castle_core := _get_castle_core()
    if castle_core != null and castle_core.has_method("refresh_max_hp"):
        castle_core.call("refresh_max_hp")

static func _get_artifact_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    var children := tree.root.get_children()
    for i in range(children.size() - 1, -1, -1):
        var child := children[i] as Node
        if child != null and child.name == "ArtifactCore":
            return child
    return null

static func _get_artifact_state(artifact_core: Node) -> Dictionary:
    if artifact_core == null:
        return {}
    var raw_state: Variant = artifact_core.get("_state")
    if raw_state is Dictionary:
        return raw_state as Dictionary
    return {}

static func _get_active_artifacts(artifact_core: Node) -> Dictionary:
    if artifact_core == null:
        return {}
    var raw_active: Variant = artifact_core.get("_active")
    if raw_active is Dictionary:
        return raw_active as Dictionary
    if artifact_core.has_method("get_active_ids"):
        var active: Dictionary = {}
        for artifact_id in artifact_core.call("get_active_ids"):
            active[String(artifact_id)] = true
        return active
    return {}

static func _emit_artifacts_changed(artifact_core: Node) -> void:
    if artifact_core == null or not artifact_core.has_signal("artifacts_changed"):
        return
    artifact_core.emit_signal("artifacts_changed")

static func _request_save() -> void:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return
    var save_core: Node = null
    var children := tree.root.get_children()
    for i in range(children.size() - 1, -1, -1):
        var child := children[i] as Node
        if child != null and child.name == "SaveCore":
            save_core = child
            break
    if save_core != null and save_core.has_method("request_save"):
        save_core.call("request_save")

static func _get_active_artifact_ids() -> Array:
    var artifact_core := _get_artifact_core()
    if artifact_core and artifact_core.has_method("get_active_ids"):
        return artifact_core.get_active_ids()
    return []

static func _get_resource_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("ResourceCore")

static func _get_castle_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("CastleCore")

static func _get_population_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("PopulationCore")

static func _get_morale_system() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("MoraleSystem")

static func _get_building_registry() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("BuildingRegistry")

static func _apply_random_seals(count: int, min_tier: int) -> void:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return
    var seal_registry := tree.root.get_node_or_null("SealRegistry")
    if seal_registry == null or not seal_registry.has_method("get_all_seal_ids") or not seal_registry.has_method("get_seal"):
        return
    var game_scene := tree.get_first_node_in_group("game_scene")
    if game_scene == null:
        game_scene = tree.current_scene
    if game_scene == null:
        return
    var map_layout: Node = game_scene.get("map_layout_node")
    if map_layout == null:
        map_layout = game_scene.get_node_or_null("WorldYSort/MapContainer/MapLayout")
    if map_layout == null:
        return
    var raw_slots: Variant = map_layout.get("slots")
    if not (raw_slots is Array):
        return
    var seal_pool: Array[String] = []
    for seal_id in seal_registry.call("get_all_seal_ids"):
        var config: Variant = seal_registry.call("get_seal", String(seal_id))
        if config == null:
            continue
        if int(config.tier) < min_tier:
            continue
        seal_pool.append(String(seal_id))
    if seal_pool.is_empty():
        return
    var candidate_slots: Array[Node] = []
    for slot_value in (raw_slots as Array):
        var slot := slot_value as Node
        if slot == null or not slot.has_method("set_seal"):
            continue
        if String(slot.get("current_seal_id")) != "":
            continue
        candidate_slots.append(slot)
    candidate_slots.shuffle()
    var placed := 0
    for slot in candidate_slots:
        if placed >= count:
            break
        var picked := seal_pool[randi() % seal_pool.size()]
        slot.call("set_seal", picked)
        placed += 1
