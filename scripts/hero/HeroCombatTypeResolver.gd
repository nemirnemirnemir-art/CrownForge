extends RefCounted
class_name HeroCombatTypeResolver

const UnitConfigScript = preload("res://core/units/UnitConfig.gd")

const DEFAULT_ATTACK_RANGE: float = 25.0
const RANGED_ATTACK_THRESHOLD: float = 80.0

static func is_ranged_unit_config(cfg: Resource) -> bool:
	if cfg == null:
		return false

	if "unit_classes" in cfg:
		var classes: Array = cfg.unit_classes
		if not classes.is_empty():
			for cls in classes:
				if int(cls) == int(UnitConfigScript.UnitClass.RANGED):
					return true
			return false

	# Legacy fallback for configs without classification.
	var attack_range := float(_get_cfg_value(cfg, "attack_range", DEFAULT_ATTACK_RANGE))
	return attack_range >= RANGED_ATTACK_THRESHOLD

static func _get_cfg_value(cfg: Resource, prop: String, fallback: Variant) -> Variant:
	if cfg == null:
		return fallback
	if prop in cfg:
		return cfg.get(prop)
	return fallback
