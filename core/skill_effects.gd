class_name SkillEffects
## Handles VFX and per-tick effect logic for SkillCore.
## Reads skill state via a reference to the parent SkillCore instance.

var _core  # reference to SkillCore

func init(core) -> void:
	_core = core

func try_apply_gold_digger_on_click(target: Node) -> void:
	var frac: float = _core.get_gold_digger_fraction()
	if frac <= 0.0: return
	if target == null or not is_instance_valid(target): return
	if not ("max_health" in target): return

	var mob_gold: int = int(max(1.0, float(target.max_health)))
	var amount := int(floor(float(mob_gold) * frac))
	if amount <= 0: amount = 1

	if target is Node2D:
		var effect_scene: PackedScene = load("res://core/effects/GoldDropEffect.tscn")
		if effect_scene:
			var effect = effect_scene.instantiate()
			if effect and effect.has_method("setup"):
				effect.setup(amount)
			var parent = target.get_parent()
			if parent:
				parent.add_child(effect)
				var rng := RandomNumberGenerator.new()
				rng.randomize()
				var offset = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * 50.0
				effect.global_position = target.global_position + offset

func heal_battle_heroes_tick() -> void:
	if not HeroCore: return
	if BattleCore and BattleCore.has_method("is_wave_active"):
		if not BattleCore.is_wave_active(): return

	var active_heroes = HeroCore.get_active_heroes()
	for hero in active_heroes:
		var max_hp := float(hero.get("maxHp", 10.0))
		var mult: float = _core._skills[6].effect_multiplier if _core._skills.has(6) else 1.0
		var heal_amount := int(max_hp * _core.SKILL6_HEAL_FRACTION_PER_SEC * mult)
		if heal_amount > 0:
			HeroCore.heal_hero(hero.id, heal_amount)
