extends RefCounted
class_name HeroOnFieldCombat

const ProjectileSpawnHelper := preload("res://scripts/combat/ProjectileSpawnHelper.gd")

## Hero combat logic
## Attacking, damage calculation, projectiles, killing mobs

var _hero: Node2D
var _hero_id: String
var _is_melee: bool
var _attack_range: float
var _max_range: float
var _attack_cooldown: float
var _attack_timer: float = 0.0
var total_damage_dealt: float = 0.0

func _init(hero: Node2D) -> void:
	_hero = hero
	# Defaults, will be overwritten by initialize if needed, or fetched from hero properties
	_hero_id = hero.hero_id if "hero_id" in hero else ""
	_is_melee = hero.is_melee if "is_melee" in hero else true
	_attack_range = hero.attack_range if "attack_range" in hero else 35.0
	_max_range = hero.max_range if "max_range" in hero else 200.0
	_attack_cooldown = hero.attack_cooldown if "attack_cooldown" in hero else 1.0

func initialize(hero: Node2D, hero_id: String, is_melee: bool, attack_range: float, max_range: float, attack_cooldown: float) -> void:
	# Legacy initialization if still used elsewhere
	_hero = hero
	_hero_id = hero_id
	_is_melee = is_melee
	_attack_range = attack_range
	_max_range = max_range
	_attack_cooldown = attack_cooldown

func update_attack_timer(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta

func get_attack_timer() -> float:
	return _attack_timer

func check_attack_range(target: Node2D, extra_buffer: float = 0.0) -> bool:
	if target == null:
		return false
	
	var dist = _hero.global_position.distance_to(target.global_position)
	var effective_range = (_attack_range + 15.0 + extra_buffer) # 15.0 is standard hit buffer
	
	return dist <= effective_range

func can_attack() -> bool:
	return _attack_timer <= 0.0

func perform_attack(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
		
	if _is_melee:
		deal_melee_damage(target)
	else:
		# Check if Slinger (or any ranged)
		# If Slinger, spawn projectile from model center/offset
		# "Also check: Slinger should attack from range, not point-blank"
		# "Projectile should spawn from the Slinger model"
		shoot_projectile(target)

func start_attack(target: Node2D, is_attack_animation_playing: bool) -> bool:
	if _attack_timer > 0.0 or is_attack_animation_playing:
		return false
	
	if target == null or not is_instance_valid(target):
		return false
	
	_attack_timer = _attack_cooldown
	
	if _is_melee:
		deal_melee_damage(target)
	else:
		shoot_projectile(target)
	
	return true

func deal_melee_damage(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	
	var distance: float = _hero.global_position.distance_to(target.global_position)
	if distance > _attack_range * 1.5:
		return
	
	var was_alive := not _is_target_dead(target)
	var damage = calculate_damage()
	if SkillCore and SkillCore.has_method("get_global_damage_multiplier"):
		damage *= float(SkillCore.get_global_damage_multiplier())
	if target.has_method("take_damage"):
		target.take_damage(damage)
		total_damage_dealt += damage
		
		# Show damage popup (Restored functionality)
		if DamagePopupPool != null and is_instance_valid(DamagePopupPool):
			# Check for crit logic if we add it later
			DamagePopupPool.show_damage(target.global_position, int(damage), false)

	_handle_kill_reward(target, was_alive)

func shoot_projectile(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	
	var projectile_scene: PackedScene = null
	if _hero and "projectile_scene" in _hero and _hero.projectile_scene != null:
		projectile_scene = _hero.projectile_scene
	
	if not projectile_scene:
		print("[HeroCombat] ERROR: Projectile scene not found")
		return
	
	var hero_pos: Vector2 = _hero.global_position
	
	# Adjust spawn position based on hero type?
	# "Projectile should spawn from the Slinger model"
	# Usually center is fine, but maybe offset up?
	# Let's assume global_position is feet, so move up slightly (e.g. 20px)
	hero_pos.y -= 20.0
	
	var damage = calculate_damage()
	if SkillCore and SkillCore.has_method("get_global_damage_multiplier"):
		damage *= float(SkillCore.get_global_damage_multiplier())

	# Configure projectile from unit settings (type/speed/spin).
	var projectile_kind := "arrow"
	if "projectile_type" in _hero:
		projectile_kind = String(_hero.projectile_type).strip_edges().to_lower()
	if projectile_kind == "":
		projectile_kind = "arrow"

	var projectile_speed := 400.0
	if "projectile_speed" in _hero:
		projectile_speed = maxf(1.0, float(_hero.projectile_speed))

	var projectile_spin_deg := 0.0
	if "projectile_spin_speed_deg" in _hero:
		projectile_spin_deg = float(_hero.projectile_spin_speed_deg)

	var target_pos = target.global_position
	if target.has_node("Hurtbox/CollisionShape2D"):
		var shape = target.get_node("Hurtbox/CollisionShape2D")
		target_pos = shape.global_position

	var direction = (target_pos - hero_pos).normalized()

	ProjectileSpawnHelper.spawn_at(projectile_scene, _hero.get_parent(), hero_pos, target, damage, projectile_speed, projectile_spin_deg, _hero, projectile_kind)
	
	# print("[HeroCombat]  Shot projectile from hero %s" % _hero_id)

func calculate_damage() -> float:
	if HeroCore:
		var total_stats: Dictionary = HeroCore.get_hero_total_stats(_hero_id)
		if total_stats is Dictionary and not total_stats.is_empty() and total_stats.has("damage"):
			return float(total_stats.get("damage", 1.0))
	
	var current_hero_data: Dictionary = {}
	if HeroCore:
		current_hero_data = HeroCore.get_hero(_hero_id)
		if current_hero_data.is_empty() and _hero_id != "":
			current_hero_data = HeroCore.get_hero(_hero_id.to_lower())
	else:
		return 1.0
	
	if current_hero_data.is_empty():
		print("[HeroCombat] ERROR: Hero data not found for %s" % _hero_id)
		return 1.0
	
	var damage: float = current_hero_data.get("damage", 1.0)
	var equipment: Dictionary = current_hero_data.get("equipment", {})
	
	# Weapon
	var weapon: Variant = equipment.get("weapon", null)
	if weapon != null and weapon is Dictionary and not weapon.is_empty():
		var weapon_min: float = weapon.get("min_damage", 0.0)
		var weapon_max: float = weapon.get("max_damage", 0.0)
		if weapon_min > 0.0 or weapon_max > 0.0:
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.randomize()
			damage = rng.randf_range(weapon_min, weapon_max)
		else:
			damage += weapon.get("damage_bonus", 0.0)
	
	# Rings
	var ring: Variant = equipment.get("ring", null)
	if ring != null and ring is Dictionary and not ring.is_empty():
		damage += ring.get("damage_bonus", 0.0)
	
	# Helmets
	var helmet: Variant = equipment.get("helmet", null)
	if helmet != null and helmet is Dictionary and not helmet.is_empty():
		damage += helmet.get("damage_bonus", 0.0)
	
	# Armor
	var armor: Variant = equipment.get("armor", null)
	if armor != null and armor is Dictionary and not armor.is_empty():
		damage += armor.get("damage_bonus", 0.0)
	
	return damage

# OLD check_attack_range removed
#func check_attack_range(target: Node2D) -> bool:
#    if target == null or not is_instance_valid(target):
#        return false
#    
#    var distance: float = _hero.global_position.distance_to(target.global_position)
#    if _is_melee:
#        return distance <= _attack_range
#    else:
#        return distance <= _max_range

func _is_target_dead(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return true
	if target is Mob:
		return target.is_dead
	if "is_dead" in target:
		return bool(target.is_dead)
	return false

func _handle_kill_reward(target: Node2D, was_alive_before_hit: bool) -> void:
	if not was_alive_before_hit:
		return
	if not _is_target_dead(target):
		return
	if HeroCore == null or _hero_id == "":
		return
	var xp_reward := 1
	HeroCore.add_xp_to_hero(_hero_id, xp_reward)

func _set_projectile_position(projectile: Node2D, pos: Vector2) -> void:
	if projectile != null and is_instance_valid(projectile):
		projectile.global_position = pos

func take_damage(actual_damage: float) -> void:
	if HeroCore and HeroCore.mutator:
		HeroCore.mutator.modify_hero_hp(_hero_id, -actual_damage)
	
	# Visual feedback (damage popup)
	if DamagePopupPool:
		DamagePopupPool.show_damage(_hero.global_position, int(actual_damage), false)
