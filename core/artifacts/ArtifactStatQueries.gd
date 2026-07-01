extends RefCounted
class_name ArtifactStatQueries

static func get_unit_limit_bonus(active: Dictionary) -> int:
	var bonus := 0
	for artifact_id in active.keys():
		var def := ArtifactCatalog.get_def(str(artifact_id))
		if def.get("effect_kind", "") == "unit_limit_bonus":
			bonus += int(def.get("effect_value", 0))
	return bonus

static func get_castle_max_hp_bonus(active: Dictionary) -> int:
	var bonus := 0
	for artifact_id in active.keys():
		var def := ArtifactCatalog.get_def(str(artifact_id))
		if str(def.get("effect_kind", "")) == "castle_max_hp_bonus":
			bonus += int(def.get("effect_value", 0))
	return max(0, bonus)

static func get_unit_flat_hp_bonus(active: Dictionary, state: Dictionary = {}) -> int:
	var bonus := 0
	for artifact_id in active.keys():
		var aid := str(artifact_id)
		var def := ArtifactCatalog.get_def(aid)
		var kind := str(def.get("effect_kind", ""))
		if kind == "troop_all_hp_flat":
			bonus += int(def.get("effect_value", 0))
		elif kind == "troop_all_hp_flat_per_resolved_spell_cast" or aid == "chi_fan":
			var per_cast := int(def.get("effect_value", 0))
			if aid == "chi_fan" and per_cast <= 0:
				per_cast = 5
			bonus += ArtifactState.get_int(state, aid, "resolved_spell_casts", 0) * per_cast
	return max(0, bonus)

static func get_friendly_unit_hp_multiplier(active: Dictionary, state: Dictionary) -> float:
	var pct := 0.0
	for artifact_id in active.keys():
		var aid := str(artifact_id)
		var def := ArtifactCatalog.get_def(aid)
		var kind := str(def.get("effect_kind", ""))
		if kind == "troop_all_hp_percent":
			pct += float(def.get("effect_value", 0.0))
		elif aid == "flour_deity":
			pct += float(ArtifactState.get_int(state, aid, "flour_produced", 0)) * 0.0005
	return maxf(0.0, 1.0 + pct)

static func get_unit_specific_hp_multiplier(active: Dictionary, _state: Dictionary, unit_id: String) -> float:
	var normalized_unit_id := unit_id.strip_edges().to_lower()
	if normalized_unit_id == "":
		return 1.0
	var classes := _get_unit_classes(normalized_unit_id)
	if not classes.has(int(UnitConfig.UnitClass.GRUNT)):
		return 1.0
	var grunt_count := _count_active_class_units("grunt")
	if grunt_count <= 1:
		return 1.0
	if not active.has("poor_mans_relic"):
		return 1.0
	return maxf(0.0, 1.0 + float(grunt_count - 1) * 0.02)

static func get_build_cost_multiplier(active: Dictionary) -> float:
	var mult := 1.0
	for artifact_id in active.keys():
		var def := ArtifactCatalog.get_def(str(artifact_id))
		if def.get("effect_kind", "") == "build_cost_multiplier":
			mult *= float(def.get("effect_value", 1.0))
	return mult

static func get_build_refund_percent(active: Dictionary) -> float:
	var pct := 0.0
	for artifact_id in active.keys():
		var def := ArtifactCatalog.get_def(str(artifact_id))
		if def.get("effect_kind", "") == "build_cost_refund_percent":
			pct += float(def.get("effect_value", 0.0))
	return clamp(pct, 0.0, 1.0)

static func get_resource_production_speed_multiplier(active: Dictionary) -> float:
	var pct := 0.0
	for artifact_id in active.keys():
		var def := ArtifactCatalog.get_def(str(artifact_id))
		var kind := str(def.get("effect_kind", ""))
		if kind == "resource_production_speed_percent" or kind == "all_production_speed_percent":
			pct += float(def.get("effect_value", 0.0))
	return max(0.0, 1.0 + pct)

static func get_unit_production_speed_multiplier(active: Dictionary) -> float:
	var pct := 0.0
	for artifact_id in active.keys():
		var def := ArtifactCatalog.get_def(str(artifact_id))
		var kind := str(def.get("effect_kind", ""))
		if kind == "unit_production_speed_percent" or kind == "all_production_speed_percent":
			pct += float(def.get("effect_value", 0.0))
	return max(0.0, 1.0 + pct)

static func get_friendly_evasion_chance(active: Dictionary) -> float:
	var chance := 0.0
	for artifact_id in active.keys():
		var def := ArtifactCatalog.get_def(str(artifact_id))
		if def.get("effect_kind", "") == "friendly_evasion_chance":
			chance += float(def.get("effect_value", 0.0))
	return clamp(chance, 0.0, 1.0)

static func get_friendly_full_damage_block_chance(active: Dictionary) -> float:
	var chance := 0.0
	for artifact_id in active.keys():
		var def := ArtifactCatalog.get_def(str(artifact_id))
		if str(def.get("effect_kind", "")) == "friendly_full_damage_block_chance":
			chance += float(def.get("effect_value", 0.0))
	return clampf(chance, 0.0, 1.0)

static func get_friendly_unit_damage_multiplier(active: Dictionary, state: Dictionary) -> float:
	var pct := 0.0
	for artifact_id in active.keys():
		var aid := str(artifact_id)
		var def := ArtifactCatalog.get_def(aid)
		if str(def.get("effect_kind", "")) == "friendly_unit_damage_percent":
			pct += float(def.get("effect_value", 0.0))
		elif aid == "super_metal":
			pct += float(ArtifactState.get_int(state, aid, "metal_produced", 0)) * 0.001
	return max(0.0, 1.0 + pct)

static func get_attacking_building_damage_multiplier(active: Dictionary) -> float:
	var pct := 0.0
	for artifact_id in active.keys():
		var aid := str(artifact_id)
		var def := ArtifactCatalog.get_def(aid)
		var kind := str(def.get("effect_kind", ""))
		if kind == "attacking_building_damage_percent":
			pct += float(def.get("effect_value", 0.0))
	return maxf(0.0, 1.0 + pct)

static func get_unit_specific_damage_multiplier(active: Dictionary, _state: Dictionary, unit_id: String) -> float:
	var normalized_unit_id := unit_id.strip_edges().to_lower()
	if normalized_unit_id == "":
		return 1.0
	var classes := _get_unit_classes(normalized_unit_id)
	if not classes.has(int(UnitConfig.UnitClass.GRUNT)):
		return 1.0
	var grunt_count := _count_active_class_units("grunt")
	if grunt_count <= 1:
		return 1.0
	if not active.has("poor_mans_relic"):
		return 1.0
	return maxf(0.0, 1.0 + float(grunt_count - 1) * 0.03)

static func get_unit_move_speed_multiplier(active: Dictionary, unit_id: String) -> float:
	var normalized_unit_id := unit_id.strip_edges().to_lower()
	if normalized_unit_id == "":
		return 1.0
	if not active.has("golden_wings"):
		return 1.0
	var classes := _get_unit_classes(normalized_unit_id)
	if not classes.has(int(UnitConfig.UnitClass.FLYING)):
		return 1.0
	return 1.3

static func get_bonus_projectile_chance(active: Dictionary) -> float:
	if not active.has("twin_projectiles"):
		return 0.0
	var warrior_count := _count_active_class_units("warrior")
	if warrior_count <= 0:
		return 0.0
	return maxf(0.0, float(warrior_count) * 0.04)

static func get_morale_flat_bonus(active: Dictionary, state: Dictionary) -> int:
	var bonus := 0
	for artifact_id in active.keys():
		var def := ArtifactCatalog.get_def(str(artifact_id))
		if str(def.get("effect_kind", "")) == "morale_flat_bonus":
			bonus += int(def.get("effect_value", 0))
	if active.has("wine_cup"):
		bonus += ArtifactState.get_int(state, "wine_cup", "granted_morale", 0)
	return bonus

static func get_spell_damage_multiplier(active: Dictionary, state: Dictionary) -> float:
	var pct := 0.0
	for artifact_id in active.keys():
		var aid := str(artifact_id)
		var def := ArtifactCatalog.get_def(aid)
		var kind := str(def.get("effect_kind", ""))
		if kind == "spell_damage_percent":
			pct += float(def.get("effect_value", 0.0))
		elif kind == "spell_damage_percent_per_enemy_killed":
			pct += float(ArtifactState.get_int(state, aid, "spell_damage_pct_x10000", 0)) / 10000.0
		elif kind == "spell_damage_percent_per_class_unit_on_field":
			var unit_class_name := str(def.get("effect_unit_class", ""))
			var class_count := _count_active_class_units(unit_class_name)
			pct += float(class_count) * float(def.get("effect_value", 0.0))
	return maxf(0.0, 1.0 + pct)

static func get_spell_double_cast_chance(active: Dictionary) -> float:
	var chance := 0.0
	for artifact_id in active.keys():
		var def := ArtifactCatalog.get_def(str(artifact_id))
		if str(def.get("effect_kind", "")) == "spell_double_cast_chance":
			chance += float(def.get("effect_value", 0.0))
	return clamp(chance, 0.0, 1.0)

static func get_spell_radius_multiplier(active: Dictionary) -> float:
	var pct := 0.0
	for artifact_id in active.keys():
		var def := ArtifactCatalog.get_def(str(artifact_id))
		if str(def.get("effect_kind", "")) == "spell_radius_percent":
			pct += float(def.get("effect_value", 0.0))
	return maxf(0.0, 1.0 + pct)

static func _count_active_class_units(unit_class_name: String) -> int:
	var hero_core := _get_hero_core()
	if hero_core == null or not hero_core.has_method("get_active_heroes"):
		return 0
	var class_id := _resolve_unit_class(unit_class_name)
	if class_id < 0:
		return 0
	
	var troop_core := _get_troop_bonus_core()
	if troop_core == null or not troop_core.has_method("get_unit_classes"):
		return 0
	
	var count := 0
	for hero in hero_core.get_active_heroes():
		if not (hero is Dictionary):
			continue
		var hero_dict := hero as Dictionary
		var hero_id := str(hero_dict.get("id", ""))
		if hero_id == "":
			continue
		var unit_id := _resolve_hero_unit_id(hero_dict, hero_id)
		var classes: Array = troop_core.call("get_unit_classes", unit_id)
		for uc in classes:
			if int(uc) == class_id:
				count += 1
				break
	return count

static func _get_unit_classes(unit_id: String) -> Array:
	var troop_core := _get_troop_bonus_core()
	if troop_core == null or not troop_core.has_method("get_unit_classes"):
		return []
	var raw_classes: Variant = troop_core.call("get_unit_classes", unit_id)
	if raw_classes is Array:
		return raw_classes
	return []

static func _resolve_unit_class(unit_class_name: String) -> int:
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

static func _resolve_hero_unit_id(hero_dict: Dictionary, hero_id: String) -> String:
	var icon_id := str(hero_dict.get("icon_id", "")).strip_edges().to_lower()
	if icon_id != "":
		return icon_id
	return _resolve_base_unit_id(hero_id)

static func _resolve_base_unit_id(hero_id: String) -> String:
	var id := hero_id.to_lower()
	if id.contains("_"):
		var parts := id.rsplit("_", true, 1)
		if parts.size() == 2 and String(parts[1]).is_valid_int():
			return String(parts[0])
	return id

static func _get_troop_bonus_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TroopBonusCore")

static func _get_hero_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HeroCore")
