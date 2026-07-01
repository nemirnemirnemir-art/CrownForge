extends RefCounted
class_name BuildingUpgradeFamilyQaRegistry

## Registry of V1 effect families for the F11 QA panel.
## Each family has a label, slug, family_id (from AuditMatrix.EffectFamily), and priority.
## V1 includes only deterministic/runtime-backed families.
## Risky families (COMBAT_HOOK, DEATH_REWARD, PRODUCTION_BONUS, PRODUCTION_EVENT, SPECIAL, INCONCLUSIVE) are deferred to V2.

const AuditMatrixScript := preload("res://scripts/dev/audit/BuildingUpgradeAuditMatrix.gd")


## Family metadata dictionary structure:
## - label: Human-readable name shown in UI
## - slug: URL-safe identifier for report paths
## - family_id: int from AuditMatrix.EffectFamily enum
## - priority: int for UI ordering (lower = higher priority)
## - runtime_backed: bool - true if family has full runtime probe support
## - v1: bool - true if included in V1 scope

static func get_v1_families() -> Array[Dictionary]:
	return [
		_family("Spell Damage", "spell_damage", AuditMatrixScript.EffectFamily.SPELL_DAMAGE, 1, true),
		_family("Morale", "morale", AuditMatrixScript.EffectFamily.MORALE, 2, true),
		_family("Cost Modifier", "cost_modifier", AuditMatrixScript.EffectFamily.COST_MODIFIER, 3, true),
		_family("Mega Militia", "mega_militia", AuditMatrixScript.EffectFamily.MEGA_MILITIA, 4, true),
		_family("Unit Aura", "unit_aura", AuditMatrixScript.EffectFamily.UNIT_AURA, 5, true),
		_family("Troop Stat", "troop_stat", AuditMatrixScript.EffectFamily.TROOP_STAT, 6, true),
		# Logic-only families (need runtime lift in Phase 4)
		_family("Production Speed", "production_speed", AuditMatrixScript.EffectFamily.PRODUCTION_SPEED, 10, false),
		_family("Capacity", "capacity", AuditMatrixScript.EffectFamily.CAPACITY, 11, false),
		_family("Efficient Processing", "efficient_processing", AuditMatrixScript.EffectFamily.EFFICIENT_PROCESSING, 12, false),
		_family("Lion Circus", "lion_circus", AuditMatrixScript.EffectFamily.LION_CIRCUS, 13, false),
	]


static func get_runtime_backed_families() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for f: Dictionary in get_v1_families():
		if bool(f.get("runtime_backed", false)):
			result.append(f)
	return result


static func get_logic_only_families() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for f: Dictionary in get_v1_families():
		if not bool(f.get("runtime_backed", false)):
			result.append(f)
	return result


static func get_family_by_slug(slug: String) -> Dictionary:
	for f: Dictionary in get_v1_families():
		if String(f.get("slug", "")) == slug:
			return f
	return {}


static func get_family_by_id(family_id: int) -> Dictionary:
	for f: Dictionary in get_v1_families():
		if int(f.get("family_id", -1)) == family_id:
			return f
	return {}


static func _family(label: String, slug: String, family_id: int, priority: int, runtime_backed: bool) -> Dictionary:
	return {
		"label": label,
		"slug": slug,
		"family_id": family_id,
		"priority": priority,
		"runtime_backed": runtime_backed,
		"v1": true,
	}
