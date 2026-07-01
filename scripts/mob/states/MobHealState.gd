extends MobState
class_name MobHealState

## State for Goblin Shaman - heals melee allies or attacks if none present

const HEAL_RANGE: float = 200.0
const HEAL_COOLDOWN: float = 2.0
const HEAL_EFFECT_SCENE = preload("res://scenes/effects/HealEffect.tscn")

func _get_heal_amount() -> float:
	return mob.heal_amount if mob and "heal_amount" in mob else 19.0

var _heal_cooldown_timer: float = 0.0
var _current_heal_target: Node2D = null

func enter() -> void:
	mob.play_attack()  # Shaman uses attack animation for healing
	_heal_cooldown_timer = 0.0
	# print("[MobHealState] %s entered heal state" % mob.name)

func update(delta: float) -> void:
	# Update cooldown
	if _heal_cooldown_timer > 0.0:
		_heal_cooldown_timer -= delta
		return
	
	# Find melee allies that need healing
	var heal_target = _find_heal_target()
	
	if heal_target:
		_perform_heal(heal_target)
	else:
		_perform_ranged_attack()

func _find_heal_target() -> Node2D:
	# Get all mobs in group
	var all_mobs = get_tree().get_nodes_in_group("enemy")
	var valid_targets: Array[Node2D] = []
	
	for potential_target in all_mobs:
		if not is_instance_valid(potential_target): continue
		if potential_target == mob: continue  # Don't heal self
		
		# Check if it's a melee mob (no projectile_scene export)
		if potential_target.has_method("get") and potential_target.get("projectile_scene") != null:
			continue  # Skip ranged mobs
		
		# Check if damaged
		if potential_target.has_method("get"):
			var current_hp = potential_target.current_health
			var max_hp = potential_target.max_health
			if current_hp >= max_hp: continue
		
		# Check distance
		var distance = mob.global_position.distance_to(potential_target.global_position)
		if distance > HEAL_RANGE: continue
		
		valid_targets.append(potential_target)
	
	# Return most damaged target
	if valid_targets.is_empty(): return null
	
	valid_targets.sort_custom(func(a, b): 
		return a.current_health < b.current_health
	)
	return valid_targets[0]

func _perform_heal(target: Node2D) -> void:
	var heal_amt = _get_heal_amount()
	# print("[MobHealState] %s healing %s for %.1f HP" % [mob.name, target.name, heal_amt])
	
	# Play heal animation
	mob.play_attack()  # Using attack anim as heal anim placeholder
	
	# Apply healing
	if target.has_method("heal"):
		target.heal(heal_amt)
	elif target.health and target.health.has_method("heal"):
		target.health.heal(heal_amt)
	
	# Spawn visual effect
	if HEAL_EFFECT_SCENE:
		var effect = HEAL_EFFECT_SCENE.instantiate()
		target.add_child(effect)
	
	# Set cooldown
	_heal_cooldown_timer = HEAL_COOLDOWN

func _perform_ranged_attack() -> void:
	# No allies to heal, perform ranged attack instead
	# Find enemy target (heroes or wall)
	var targets = get_tree().get_nodes_in_group("hero")
	if targets.is_empty():
		# Target wall (avoid hardcoded absolute paths)
		var walls = get_tree().get_nodes_in_group("wall")
		if walls.size() > 0 and is_instance_valid(walls[0]):
			_fire_at_target(walls[0].global_position)
			return
		# Fallback: target wall marker position (if no wall node exists)
		var fallback_target: Vector2 = mob.get_wall_contact_position() if mob and mob.has_method("get_wall_contact_position") else Vector2.ZERO
		_fire_at_target(fallback_target)
	else:
		# Target nearest hero
		var nearest = targets[0]
		for hero in targets:
			if mob.global_position.distance_to(hero.global_position) < mob.global_position.distance_to(nearest.global_position):
				nearest = hero
		_fire_at_target(nearest.global_position)

func _fire_at_target(target_pos: Vector2) -> void:
	mob.play_attack()
	if mob.has_method("fire_projectile"):
		mob.fire_projectile(target_pos)
	_heal_cooldown_timer = HEAL_COOLDOWN  # Use same cooldown for attacks

func exit() -> void:
	_current_heal_target = null
