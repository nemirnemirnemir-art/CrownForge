extends RefCounted
class_name ArtifactExternalMultiplierBridge

func apply_resource_production_speed_bridge(base_multiplier: float, building_upgrade_core) -> float:
	var mult := base_multiplier
	if building_upgrade_core and building_upgrade_core.has_method("get_buddhist_temple_production_speed_multiplier"):
		mult *= float(building_upgrade_core.get_buddhist_temple_production_speed_multiplier())
	return mult

func apply_unit_production_speed_bridge(base_multiplier: float, building_upgrade_core) -> float:
	var mult := base_multiplier
	if building_upgrade_core and building_upgrade_core.has_method("get_buddhist_temple_production_speed_multiplier"):
		mult *= float(building_upgrade_core.get_buddhist_temple_production_speed_multiplier())
	return mult

func apply_spell_damage_bridge(base_multiplier: float, building_upgrade_core) -> float:
	# All building spell damage bonuses stack ADDITIVELY from a 100% base.
	# Each source returns a multiplier like 1.5 (meaning +50%).  We extract
	# the bonus portion (source - 1.0) and sum them, then add to base_multiplier.
	# Example: base 2.0, temple 1.5, ball 1.2, tesla 1.1
	#   bonuses = 0.5 + 0.2 + 0.1 = 0.8  ->  result = 2.0 + 0.8 = 2.8
	var bonus_sum := 0.0
	if building_upgrade_core and building_upgrade_core.has_method("get_buddhist_temple_spell_damage_multiplier"):
		bonus_sum += float(building_upgrade_core.get_buddhist_temple_spell_damage_multiplier()) - 1.0
	if building_upgrade_core and building_upgrade_core.has_method("get_magic_ball_spell_damage_multiplier"):
		bonus_sum += float(building_upgrade_core.get_magic_ball_spell_damage_multiplier()) - 1.0
	if building_upgrade_core and building_upgrade_core.has_method("get_active_tesla_tower_spell_damage_multiplier"):
		bonus_sum += float(building_upgrade_core.get_active_tesla_tower_spell_damage_multiplier()) - 1.0
	if building_upgrade_core and building_upgrade_core.has_method("get_crystal_mine_spell_damage_multiplier"):
		bonus_sum += float(building_upgrade_core.get_crystal_mine_spell_damage_multiplier()) - 1.0
	# Phase 2C: Paladins Campus +10% spell damage
	if building_upgrade_core and building_upgrade_core.has_method("get_paladins_spell_damage_multiplier"):
		bonus_sum += float(building_upgrade_core.get_paladins_spell_damage_multiplier()) - 1.0
	# Phase 2C: Ram Pasture +20% spell damage per Ram on field
	if building_upgrade_core and building_upgrade_core.has_method("get_ram_spell_damage_multiplier"):
		bonus_sum += float(building_upgrade_core.get_ram_spell_damage_multiplier()) - 1.0
	# Phase 2C: White Unicorn Field +10% spell damage per Unicorn on field
	if building_upgrade_core and building_upgrade_core.has_method("get_unicorn_spell_damage_multiplier"):
		bonus_sum += float(building_upgrade_core.get_unicorn_spell_damage_multiplier()) - 1.0
	return base_multiplier + bonus_sum
