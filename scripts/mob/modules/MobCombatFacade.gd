extends RefCounted
class_name MobCombatFacade


func start_attack(combat) -> void:
	if combat:
		combat.start_attack()


func attack_finished(combat) -> bool:
	return combat.attack_finished() if combat else true


func end_attack(combat) -> void:
	if combat:
		combat.end_attack()


func play_walk(animations) -> void:
	if animations:
		animations.play_walk()


func play_attack(animations) -> void:
	if animations:
		animations.play_attack()


func play_death(animations) -> void:
	if animations:
		animations.play_death()


func heal(health, amount: float) -> float:
	if health == null:
		return 0.0
	var old_hp: float = health.current_health
	health.current_health = min(health.max_health, health.current_health + amount)
	return health.current_health - old_hp
