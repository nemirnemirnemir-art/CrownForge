extends RefCounted
class_name HeroOnFieldCombatFacade

var hero = null
var combat_ai = null


func setup(hero_ref, combat_ai_ref) -> void:
	hero = hero_ref
	combat_ai = combat_ai_ref


func validate_current_target() -> void:
	if hero == null:
		return
	var current_target = hero.current_target
	if current_target == null or not is_instance_valid(current_target) or (combat_ai and combat_ai.is_target_dead(current_target)):
		hero.current_target = null


func check_attack_range() -> bool:
	if combat_ai == null or hero == null:
		return false
	return combat_ai.check_attack_range(hero.current_target, 0.0)


func fire_projectile(target) -> void:
	if combat_ai:
		combat_ai.shoot_projectile(target)


func on_hit_landed(amount: float) -> void:
	if combat_ai:
		combat_ai.on_hit_landed(amount)
