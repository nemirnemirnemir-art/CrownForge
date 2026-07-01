extends Node
class_name HeroFieldCombat

var _hero: Node2D
var _hero_id: String = ""
var _attack_timer: float = 0.0
var total_damage_dealt: float = 0.0

var _attack_component: Node
var _shape_cast: ShapeCast2D

func setup(hero: Node2D, attack_component: Node, shape_cast: ShapeCast2D) -> void:
	_hero = hero
	_attack_component = attack_component
	_shape_cast = shape_cast
	if _attack_component and _attack_component.has_signal("hit_landed"):
		if not _attack_component.hit_landed.is_connected(on_hit_landed):
			_attack_component.hit_landed.connect(on_hit_landed)

func set_hero_id(hero_id: String) -> void:
	_hero_id = hero_id.to_lower() if hero_id != null else ""

func update(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer = max(0.0, _attack_timer - delta)

func get_attack_timer() -> float:
	return _attack_timer

func check_attack_range(target: Node2D, extra_buffer: float = 0.0) -> bool:
	if not _hero or target == null or not is_instance_valid(target):
		return false
	var dist = _hero.global_position.distance_to(target.global_position)
	var base_range = float(_hero.attack_range) + float(_hero.hit_buffer) + extra_buffer
	return dist <= base_range

func calculate_damage() -> float:
	if HeroCore:
		var total_stats: Dictionary = HeroCore.get_hero_total_stats(_hero_id)
		if total_stats is Dictionary and not total_stats.is_empty() and total_stats.has("damage"):
			return float(total_stats.get("damage", 1.0))
	
	# Get base damage from HeroCore stats
	var base_damage: float = 10.0  # Default fallback
	
	if _hero_id == "" or not HeroCore:
		print("[HeroFieldCombat] WARNING: %s _hero_id is empty or HeroCore null, using base_damage=10" % (_hero.name if _hero else "?"))
		return base_damage
	
	# Try to get hero data from HeroCore
	var current_hero_data: Dictionary = {}
	if HeroCore.has_method("get_hero"):
		current_hero_data = HeroCore.get_hero(_hero_id)
	if current_hero_data.is_empty() and HeroCore.heroes.has(_hero_id):
		current_hero_data = HeroCore.heroes[_hero_id]
	
	# Get base attack from hero type config
	var hero_type := _hero_id.split("_")[0] if _hero_id.contains("_") else _hero_id
	if HeroCore.has_method("get_hero_config"):
		var config = HeroCore.get_hero_config(hero_type)
		if config and config.has("base_attack"):
			base_damage = float(config["base_attack"])
	
	# Use damage from hero data, or fallback to base_damage
	var damage: float = float(current_hero_data.get("damage", base_damage))
	
	# Minimum damage = 5 to avoid the 1 damage bug
	if damage < 5.0:
		damage = base_damage
	
	# Equipment bonuses
	var equipment: Dictionary = current_hero_data.get("equipment", {})
	var weapon: Variant = equipment.get("weapon", null)
	if weapon != null and weapon is Dictionary and not weapon.is_empty():
		var weapon_min: float = float(weapon.get("min_damage", 0.0))
		var weapon_max: float = float(weapon.get("max_damage", 0.0))
		if weapon_min > 0.0 or weapon_max > 0.0:
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.randomize()
			damage = rng.randf_range(weapon_min, weapon_max)
		else:
			damage += float(weapon.get("damage_bonus", 0.0))
	var ring: Variant = equipment.get("ring", null)
	if ring != null and ring is Dictionary and not ring.is_empty():
		damage += float(ring.get("damage_bonus", 0.0))
	var helmet: Variant = equipment.get("helmet", null)
	if helmet != null and helmet is Dictionary and not helmet.is_empty():
		damage += float(helmet.get("damage_bonus", 0.0))
	var armor: Variant = equipment.get("armor", null)
	if armor != null and armor is Dictionary and not armor.is_empty():
		damage += float(armor.get("damage_bonus", 0.0))
	return damage

func on_hit_landed(amount: float) -> void:
	total_damage_dealt += amount
