extends "res://core/buildings/special/GenericSpecialBuilding.gd"

const ChainLightningEffectScene: PackedScene = preload("res://scenes/spells/effects/ChainLightningEffect.tscn")
const ArtifactBuildingCombatHooksScript := preload("res://core/artifacts/ArtifactBuildingCombatHooks.gd")
const SpellConfigScript := preload("res://resources/spells/SpellConfig.gd")
const CHAIN_RANGE: float = 150.0
const DEBUG_TESLA := false

var _artifact_building_combat_hooks = ArtifactBuildingCombatHooksScript.new()

func tick(delta: float) -> Dictionary:
    if _config == null:
        return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0}
    var cycle := _get_effective_cycle_time()
    if DEBUG_TESLA:
        print("[TeslaTower] tick slot=%d delta=%.3f producing=%s timer=%.3f cycle=%.3f has_enemy=%s can_produce=%s" % [
            _get_slot_index(),
            delta,
            str(_is_producing),
            _timer,
            cycle,
            str(_has_enemy_targets()),
            str(_config == null or _config.consumes.is_empty() or _config.can_produce()),
        ])
    if not _is_producing:
        if not _has_enemy_targets():
            if DEBUG_TESLA:
                print("[TeslaTower] no targets")
            return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": cycle}
        if _config.consumes.size() > 0:
            if not _config.can_produce():
                if DEBUG_TESLA:
                    print("[TeslaTower] cannot produce: missing resources")
                return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": cycle}
            _config.consume_inputs()
            if DEBUG_TESLA:
                print("[TeslaTower] consumed inputs")
        _is_producing = true
        _timer = 0.0
    _timer += delta
    var progress_ratio: float = max(0.0, (cycle - _timer) / cycle)
    var completed := false
    if _timer >= cycle:
        _timer = 0.0
        _is_producing = false
        completed = true
        if DEBUG_TESLA:
            print("[TeslaTower] cycle completed -> strike")
        _strike_targets()
    return {"progress_ratio": progress_ratio, "is_producing": _is_producing, "completed": completed, "cycle_time": cycle}

func _strike_targets() -> void:
    var targets := _collect_chain_targets()
    if DEBUG_TESLA:
        var info: Array[String] = []
        for enemy in targets:
            info.append("%s@%s" % [enemy.name, str(enemy.global_position)])
        print("[TeslaTower] targets=%s" % info)
    if targets.is_empty():
        return
    var target := targets[0]
    for enemy in targets:
        _apply_damage_to_enemy(enemy, _get_strike_damage())
    if ChainLightningEffectScene == null:
        return
    var effect := ChainLightningEffectScene.instantiate()
    if effect == null:
        return
    effect.set("max_targets_override", 3 + (1 if _has_upgrade("tesla_tower:1") else 0))
    effect.set("line_width_multiplier", 2.0)
    effect.set("start_anim_scale_multiplier", 2.0)
    effect.set("pre_chain_delay_override", 0.0)
    effect.set("deal_damage_enabled", false)
    if _slot is Node2D:
        effect.set("origin_position_override", (_slot as Node2D).global_position)
    var cfg := SpellConfigScript.new()
    cfg.spell_id = "tesla_tower_strike"
    cfg.spell_name = "Tesla Strike"
    cfg.damage = _get_strike_damage()
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.current_scene == null:
        effect.queue_free()
        return
    var parent: Node = tree.current_scene.get_node_or_null("WorldYSort")
    if parent == null:
        parent = tree.current_scene
    parent.add_child(effect)
    effect.initialize(cfg, target.global_position)

func _collect_chain_targets() -> Array[Node2D]:
    var enemies := _collect_enemy_candidates()
    if enemies.is_empty():
        return []
    var start := _find_nearest_enemy_from_candidates(enemies)
    if start == null:
        return []
    var max_targets := 3 + (1 if _has_upgrade("tesla_tower:1") else 0)
    var chain_range_sq := CHAIN_RANGE * CHAIN_RANGE
    var hit: Array[Node2D] = [start]
    var current: Node2D = start
    for _i in range(max_targets - 1):
        var next := _find_next_enemy(current.global_position, enemies, hit, chain_range_sq)
        if next == null:
            break
        hit.append(next)
        current = next
    return hit

func _apply_damage_to_enemy(enemy: Node2D, amount: float) -> void:
    if enemy == null or not is_instance_valid(enemy):
        if DEBUG_TESLA:
            print("[TeslaTower] skip damage: invalid enemy")
        return
    var hurtbox := enemy.get_node_or_null("Hurtbox")
    var damage_source: Node = _slot if _slot is Node else null
    if hurtbox != null and hurtbox.has_method("apply_hit"):
        var attack_id: int = Time.get_ticks_msec() + enemy.get_instance_id() + randi()
        if DEBUG_TESLA:
            print("[TeslaTower] apply_hit enemy=%s damage=%.2f attack_id=%d" % [enemy.name, amount, attack_id])
        hurtbox.call("apply_hit", amount, damage_source, attack_id)
        return
    if enemy.has_method("take_damage"):
        if DEBUG_TESLA:
            print("[TeslaTower] take_damage enemy=%s damage=%.2f" % [enemy.name, amount])
        enemy.call("take_damage", amount)
        return
    if DEBUG_TESLA:
        print("[TeslaTower] no damage method on enemy=%s" % enemy.name)

func _get_effective_cycle_time() -> float:
    var speed_mult := 1.0
    if _has_upgrade("tesla_tower:0"):
        speed_mult *= 1.4
    var tree := Engine.get_main_loop() as SceneTree
    if tree and tree.root:
        var artifact_core := tree.root.get_node_or_null("ArtifactCore")
        if artifact_core != null and artifact_core.has_method("get_resource_production_speed_multiplier"):
            speed_mult *= float(artifact_core.call("get_resource_production_speed_multiplier"))
    var morale_system := _get_autoload("MoraleSystem")
    if morale_system != null:
        speed_mult *= (1.0 + float(morale_system.call("get_productivity_modifier")))
    var king_spell_state := _get_autoload("KingSpellState")
    if king_spell_state != null:
        speed_mult *= (1.0 + float(king_spell_state.call("get_productivity_bonus_multiplier")))
    var upgrade_core := _get_autoload("BuildingUpgradeCore")
    if upgrade_core != null and upgrade_core.has_method("get_concert_slot_production_speed_multiplier"):
        speed_mult *= float(upgrade_core.call("get_concert_slot_production_speed_multiplier", _get_slot_index()))
    if speed_mult <= 0.0:
        speed_mult = 0.0001
    return max(0.001, float(_config.cycle_time) / speed_mult)

func _get_strike_damage() -> float:
    var damage := 100.0
    if _has_upgrade("tesla_tower:2"):
        damage *= 1.4
    return _artifact_building_combat_hooks.get_scaled_attacking_building_damage(damage)

func _has_enemy_targets() -> bool:
    return _find_nearest_enemy() != null

func _find_nearest_enemy() -> Node2D:
    return _find_nearest_enemy_from_candidates(_collect_enemy_candidates())

func _find_nearest_enemy_from_candidates(candidates: Array[Node2D]) -> Node2D:
    if not (_slot is Node2D):
        return null
    var slot2d := _slot as Node2D
    var best: Node2D = null
    var best_d2 := INF
    for enemy in candidates:
        if enemy == null or not is_instance_valid(enemy):
            continue
        var d2: float = slot2d.global_position.distance_squared_to(enemy.global_position)
        if d2 < best_d2:
            best_d2 = d2
            best = enemy
    return best

func _collect_enemy_candidates() -> Array[Node2D]:
    var result: Array[Node2D] = []
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return result
    var dedupe := {}
    for group_name in ["enemy", "enemies", "mobs"]:
        for node in tree.get_nodes_in_group(group_name):
            if not (node is Node2D) or not is_instance_valid(node):
                continue
            var enemy := node as Node2D
            var is_dead_value: Variant = enemy.get("is_dead")
            if is_dead_value != null and bool(is_dead_value):
                continue
            dedupe[enemy.get_instance_id()] = enemy
    for key in dedupe.keys():
        result.append(dedupe[key])
    if DEBUG_TESLA:
        print("[TeslaTower] collected_enemies=%d" % result.size())
    return result

func _find_next_enemy(from_position: Vector2, candidates: Array[Node2D], already_hit: Array[Node2D], max_d2: float) -> Node2D:
    var best: Node2D = null
    var best_distance := max_d2
    for enemy in candidates:
        if enemy == null or not is_instance_valid(enemy):
            continue
        if already_hit.has(enemy):
            continue
        var d2 := from_position.distance_squared_to(enemy.global_position)
        if d2 <= best_distance:
            best_distance = d2
            best = enemy
    return best

func _has_upgrade(upgrade_id: String) -> bool:
    var upgrade_core := _get_autoload("BuildingUpgradeCore")
    if upgrade_core == null or not upgrade_core.has_method("has_upgrade"):
        return false
    var slot_index := _get_slot_index()
    if slot_index < 0:
        return false
    return bool(upgrade_core.call("has_upgrade", slot_index, upgrade_id))

func _get_slot_index() -> int:
    if _slot == null or not is_instance_valid(_slot):
        return -1
    return int(_slot.get("slot_index"))
