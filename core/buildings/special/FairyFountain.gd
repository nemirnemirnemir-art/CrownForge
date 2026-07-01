extends RefCounted

const ArtifactBuildingCombatHooksScript := preload("res://core/artifacts/ArtifactBuildingCombatHooks.gd")
const RESOURCE_IDS := [
    "water", "gold", "wood", "clay", "iron_ore", "steel", "wheat", "flour", "meat", "grapes", "wine", "oil", "crystal"
]
const DUST_DAMAGE_PER_CYCLE := 15.0

var _slot: Node = null
var _config: BuildingConfig = null
var _timer: float = 0.0
var _is_producing: bool = false
var _artifact_building_combat_hooks = ArtifactBuildingCombatHooksScript.new()

func initialize(slot: Node, config: BuildingConfig) -> void:
    _slot = slot
    _config = config
    _timer = 0.0
    _is_producing = false

func tick(delta: float) -> Dictionary:
    if _config == null:
        return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0}
    var cycle: float = _get_effective_cycle_time()
    if not _is_producing:
        _is_producing = true
        _timer = 0.0
    _timer += delta
    var progress_ratio: float = max(0.0, (cycle - _timer) / cycle)
    var completed: bool = false
    if _timer >= cycle:
        _timer = 0.0
        _is_producing = false
        completed = true
        _on_cycle_completed()
    return {"progress_ratio": progress_ratio, "is_producing": _is_producing, "completed": completed, "cycle_time": cycle}

func _on_cycle_completed() -> void:
    var pool := RESOURCE_IDS.duplicate()
    pool.shuffle()
    if pool.is_empty():
        return
    var resource_id := String(pool[0])
    var resource_core := _get_resource_core()
    if resource_core != null:
        resource_core.call("add_resource", resource_id, 5)
    if _slot and _slot.has_method("show_resource_popup"):
        _slot.call("show_resource_popup", resource_id, 5, Vector2.ZERO)
    if _has_upgrade("fairy_fountain:1"):
        _damage_nearest_enemy(_artifact_building_combat_hooks.get_scaled_attacking_building_damage(DUST_DAMAGE_PER_CYCLE))

func _damage_nearest_enemy(amount: float) -> void:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return
    var best_target: Node2D = null
    var best_d2 := INF
    if not (_slot is Node2D):
        return
    var slot2d := _slot as Node2D
    for group_name in ["enemy", "enemies", "mobs"]:
        for node in tree.get_nodes_in_group(group_name):
            if not (node is Node2D) or not is_instance_valid(node):
                continue
            var enemy := node as Node2D
            var is_dead_value: Variant = enemy.get("is_dead")
            if is_dead_value != null and bool(is_dead_value):
                continue
            var d2: float = slot2d.global_position.distance_squared_to(enemy.global_position)
            if d2 < best_d2:
                best_d2 = d2
                best_target = enemy
    if best_target == null:
        return
    var hurtbox := best_target.get_node_or_null("Hurtbox")
    if hurtbox and hurtbox.has_method("apply_hit"):
        var attack_id := Time.get_ticks_msec() + best_target.get_instance_id()
        hurtbox.apply_hit(amount, slot2d, attack_id)
        return
    if best_target.has_method("take_damage"):
        best_target.take_damage(amount)

func _has_upgrade(upgrade_id: String) -> bool:
    var upgrade_core := _get_upgrade_core()
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

func _get_effective_cycle_time() -> float:
    var speed_mult := 1.0
    if _has_upgrade("fairy_fountain:0"):
        speed_mult *= 1.25
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
    if speed_mult <= 0.0:
        speed_mult = 0.0001
    return max(0.001, float(_config.cycle_time) / speed_mult)

func _get_resource_core() -> Node:
    return _get_autoload("ResourceCore")

func _get_upgrade_core() -> Node:
    return _get_autoload("BuildingUpgradeCore")

func _get_autoload(node_name: String) -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null(node_name)
