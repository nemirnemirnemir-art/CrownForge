extends "res://scripts/hero/states/HeroState.gd"
class_name HeroHealState

## Hero Heal State - heals allied heroes during battle instead of attacking
## Based on MobHealState from Goblin Shaman, adapted for heroes

const HEAL_RANGE: float = 200.0
const HEAL_COOLDOWN: float = 2.0
const HEAL_AMOUNT: float = 15.0
const HEAL_EFFECT_SCENE = preload("res://scenes/effects/HealEffect.tscn")

var _heal_cooldown_timer: float = 0.0
var _current_heal_target: Node2D = null

func enter() -> void:
	if not hero:
		if state_machine: hero = state_machine._get_hero()
		if not hero: return
	
	# Play attack/cast animation for healing
	if hero.has_method("_update_animation"):
		hero._update_animation("attack")
	if hero.has_method("set_attack_animation_playing"):
		hero.set_attack_animation_playing(true)
	
	_heal_cooldown_timer = 0.0
	# print("[HeroHealState] %s entered heal state" % hero.name)

func update(delta: float) -> void:
	if not hero or hero.is_dead:
		return
	
	# Freeze position while healing
	hero.velocity = Vector2.ZERO
	
	# Update cooldown
	if _heal_cooldown_timer > 0.0:
		_heal_cooldown_timer -= delta
		return
	
	# Find allies that need healing
	var heal_target = _find_heal_target()
	
	if heal_target:
		_perform_heal(heal_target)
	else:
		# No allies to heal, switch to combat or idle
		_find_next_target_or_exit()

func physics_update(_delta: float) -> void:
	if not hero or hero.is_dead: return
	hero.velocity = Vector2.ZERO

func exit() -> void:
	_current_heal_target = null
	if hero and hero.has_method("set_attack_animation_playing"):
		hero.set_attack_animation_playing(false)

func _find_heal_target() -> Node2D:
	## Find the most damaged allied hero within range
	var all_heroes = get_tree().get_nodes_in_group("hero")
	var valid_targets: Array[Node2D] = []
	
	for potential_target in all_heroes:
		if not is_instance_valid(potential_target): continue
		if potential_target == hero: continue  # Don't heal self
		
		# Check if it's a hero (not a building or something else)
		if not potential_target is CharacterBody2D:
			continue
		
		# Check if dead
		if "is_dead" in potential_target and bool(potential_target.is_dead):
			continue
		
		# Check if damaged
		var current_hp: float = 0.0
		var max_hp: float = 0.0
		
		if "current_health" in potential_target and "max_health" in potential_target:
			current_hp = float(potential_target.current_health)
			max_hp = float(potential_target.max_health)
		elif potential_target.has_method("get_current_hp") and potential_target.has_method("get_max_hp"):
			current_hp = float(potential_target.get_current_hp())
			max_hp = float(potential_target.get_max_hp())
		
		if max_hp <= 0.0 or current_hp >= max_hp:
			continue  # Not damaged
		
		# Check distance
		var distance = hero.global_position.distance_to(potential_target.global_position)
		if distance > HEAL_RANGE:
			continue
		
		valid_targets.append(potential_target)
	
	if valid_targets.is_empty():
		return null
	
	# Return most damaged target (lowest current HP percentage)
	valid_targets.sort_custom(func(a, b):
		var a_hp_pct = _get_hp_percent(a)
		var b_hp_pct = _get_hp_percent(b)
		return a_hp_pct < b_hp_pct
	)
	return valid_targets[0]

func _get_hp_percent(unit: Node2D) -> float:
	var current_hp: float = 0.0
	var max_hp: float = 1.0
	if "current_health" in unit and "max_health" in unit:
		current_hp = float(unit.current_health)
		max_hp = maxf(1.0, float(unit.max_health))
	return current_hp / max_hp

func _perform_heal(target: Node2D) -> void:
	var heal_amt = _get_heal_amount()
	# print("[HeroHealState] %s healing %s for %.1f HP" % [hero.name, target.name, heal_amt])
	
	# Play heal animation
	if hero.has_method("_update_animation"):
		hero._update_animation("attack")
	
	# Face target
	var direction_x = target.global_position.x - hero.global_position.x
	if abs(direction_x) > 0.3:
		var should_flip = direction_x < 0
		var walk_sprite = hero.get_node_or_null("AnimWalk")
		var attack_sprite = hero.get_node_or_null("AnimAttack")
		if walk_sprite:
			walk_sprite.flip_h = should_flip
		if attack_sprite:
			attack_sprite.flip_h = should_flip
		if hero.animation_sprite:
			hero.animation_sprite.flip_h = should_flip
	
	# Apply healing via HeroCore
	var healed := false
	if "hero_id" in target:
		var target_hero_id: String = String(target.hero_id)
		var tree := Engine.get_main_loop() as SceneTree
		if tree and tree.root:
			var hero_core := tree.root.get_node_or_null("HeroCore")
			if hero_core and hero_core.has_method("heal_hero"):
				hero_core.heal_hero(target_hero_id, int(heal_amt))
				healed = true
	
	# Fallback: direct heal if no HeroCore
	if not healed:
		if target.has_method("heal"):
			target.heal(heal_amt)
		elif "current_health" in target and "max_health" in target:
			var new_hp = minf(float(target.current_health) + heal_amt, float(target.max_health))
			target.current_health = new_hp
	
	# Spawn visual effect
	if HEAL_EFFECT_SCENE:
		var effect = HEAL_EFFECT_SCENE.instantiate()
		if effect:
			target.add_child(effect)
	
	# Set cooldown
	_heal_cooldown_timer = HEAL_COOLDOWN

func _get_heal_amount() -> float:
	## Get heal amount - could be overridden by hero config
	if hero and "heal_amount" in hero:
		return float(hero.heal_amount)
	return HEAL_AMOUNT

func _find_next_target_or_exit() -> void:
	## When no allies need healing, check for enemies or go idle
	var enemy_target = CombatTargetFinder.find_nearest(hero, "enemy", 1000.0)
	
	if enemy_target and is_instance_valid(enemy_target):
		# Enemies exist - stay in heal state, ready to heal when allies get damaged
		# (healer should not attack, just wait for allies to get damaged)
		_heal_cooldown_timer = 0.3  # Short cooldown to check again
	else:
		# No enemies - go idle
		hero.set_current_target(null)
		state_machine.change_state("HeroIdleState")

func _is_valid_target(target) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if "is_dead" in target and bool(target.is_dead):
		return false
	return true
