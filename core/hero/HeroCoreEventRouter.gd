extends RefCounted
class_name HeroCoreEventRouter
## Owns all external signal connections wired during hero_core startup.


func setup(hero_core: Node) -> void:
    EventBus.wave_completed.connect(hero_core._on_wave_completed)
    _connect_troop_bonus_core(hero_core)
    _connect_building_upgrade_core(hero_core)
    _connect_artifact_core(hero_core)


func _connect_troop_bonus_core(hero_core: Node) -> void:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return
    var troop_core := tree.root.get_node_or_null("TroopBonusCore")
    if troop_core == null:
        return
    if not troop_core.bonuses_changed.is_connected(hero_core._on_troop_bonuses_changed):
        troop_core.bonuses_changed.connect(hero_core._on_troop_bonuses_changed)


func _connect_building_upgrade_core(hero_core: Node) -> void:
    # When building upgrades change (e.g. slinger HP +200%), recalculate hero stats
    if BuildingUpgradeCore == null:
        return
    if not BuildingUpgradeCore.has_signal("building_upgrades_changed"):
        return
    if not BuildingUpgradeCore.building_upgrades_changed.is_connected(hero_core._on_building_upgrades_changed):
        BuildingUpgradeCore.building_upgrades_changed.connect(hero_core._on_building_upgrades_changed)


func _connect_artifact_core(hero_core: Node) -> void:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return
    var artifact_core := tree.root.get_node_or_null("ArtifactCore")
    if artifact_core == null:
        return
    if not artifact_core.has_signal("artifacts_changed"):
        return
    if not artifact_core.artifacts_changed.is_connected(hero_core._on_troop_bonuses_changed):
        artifact_core.artifacts_changed.connect(hero_core._on_troop_bonuses_changed)
