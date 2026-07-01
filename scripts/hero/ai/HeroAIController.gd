extends Node
class_name HeroAIController

## Simple hero AI: patrol near castle, engage enemies when waves spawn
## Replaces complex targeting logic with straightforward behavior

signal state_changed(new_state: String)

enum State { PATROL, ENGAGE, ATTACK }

var current_state: State = State.PATROL
var hero: Node2D

# Patrol configuration
var patrol_center: Vector2 = Vector2.ZERO
var patrol_radius: float = 100.0
var patrol_box_size: Vector2 = Vector2(150.0, 300.0)
var patrol_target: Vector2 = Vector2.ZERO
var patrol_timer: float = 0.0
const PATROL_INTERVAL: float = 2.0

# Combat configuration
var current_target: Node2D = null
var attack_range: float = 50.0

# References
var navigation: Node
var animations: Node
var attack_component: Node

func setup(hero_node: Node2D, nav: Node, anim: Node, attack_comp: Node) -> void:
	hero = hero_node
	navigation = nav
	animations = anim
	attack_component = attack_comp
	
	# Get attack range from hero's exported variable first, then fallback to attack_component
	if hero and "attack_range" in hero:
		attack_range = hero.attack_range
	elif attack_component and "attack_range" in attack_component:
		attack_range = attack_component.attack_range
	
	print("[HeroAI] %s initialized, attack_range=%.1f" % [hero.name, attack_range])

func set_patrol_zone(center: Vector2, radius: float) -> void:
	patrol_center = center
	patrol_radius = radius
	patrol_box_size = Vector2(radius * 2.0, radius * 2.0)
	_pick_new_patrol_target()
	print("[HeroAI] %s patrol zone set: center=%s, radius=%.1f" % [hero.name, center, radius])

func engage_enemies() -> void:
	"""Called by GameScene when wave spawns (after 5 sec delay)"""
	if current_state == State.PATROL:
		_transition_to(State.ENGAGE)

func return_to_patrol() -> void:
	"""Called by GameScene when all enemies are cleared"""
	if current_state != State.PATROL:
		_transition_to(State.PATROL)

func update(delta: float) -> void:
	match current_state:
		State.PATROL:
			_update_patrol(delta)
		State.ENGAGE:
			_update_engage(delta)
		State.ATTACK:
			_update_attack(delta)

# ============================================================================
# PATROL STATE
# ============================================================================

func _update_patrol(delta: float) -> void:
	patrol_timer -= delta
	
	# Pick new patrol target periodically
	if patrol_timer <= 0.0:
		_pick_new_patrol_target()
		patrol_timer = PATROL_INTERVAL
	
	# Move toward patrol target
	if navigation and navigation.has_method("move_to"):
		navigation.move_to(patrol_target)
	
	# Play walk animation
	if animations and animations.has_method("play_walk"):
		animations.play_walk()

func _pick_new_patrol_target() -> void:
	var half_w: float = maxf(10.0, patrol_box_size.x * 0.5)
	var half_h: float = maxf(10.0, patrol_box_size.y * 0.5)
	patrol_target = patrol_center + Vector2(randf_range(-half_w, half_w), randf_range(-half_h, half_h))

# ============================================================================
# ENGAGE STATE
# ============================================================================

func _update_engage(_delta: float) -> void:
	# Find nearest mob
	var nearest_mob = _find_nearest_mob()
	
	if not nearest_mob:
		# No mobs left, return to patrol
		_transition_to(State.PATROL)
		return
	
	current_target = nearest_mob
	
	# Move toward mob
	if navigation and navigation.has_method("move_to"):
		navigation.move_to(nearest_mob.global_position)
	
	# Check if in attack range
	var distance = hero.global_position.distance_to(nearest_mob.global_position)
	if distance <= attack_range:
		_transition_to(State.ATTACK)
	else:
		# Play walk animation while moving
		if animations and animations.has_method("play_walk"):
			animations.play_walk()

# ============================================================================
# ATTACK STATE
# ============================================================================

func _update_attack(_delta: float) -> void:
	# Validate target
	if not current_target or not is_instance_valid(current_target):
		_transition_to(State.ENGAGE)
		return
	
	if "is_dead" in current_target and current_target.is_dead:
		_transition_to(State.ENGAGE)
		return
	
	# Check if still in range
	var distance = hero.global_position.distance_to(current_target.global_position)
	if distance > attack_range * 1.2:
		# Target moved away, re-engage
		_transition_to(State.ENGAGE)
		return
	
	# Stop movement
	if navigation and navigation.has_method("stop"):
		navigation.stop()
	
	# Attack target
	if attack_component and attack_component.has_method("start_attack"):
		if not attack_component.is_attacking():
			attack_component.start_attack(current_target, 1.0)  # Damage handled by component
	
	# Play attack animation
	if animations and animations.has_method("play_attack"):
		animations.play_attack()

# ============================================================================
# UTILITIES
# ============================================================================

func _find_nearest_mob() -> Node2D:
	var mobs = get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var nearest_dist: float = INF
	
	for mob in mobs:
		if not is_instance_valid(mob): continue
		if "is_dead" in mob and mob.is_dead: continue
		
		var dist = hero.global_position.distance_to(mob.global_position)
		if dist < nearest_dist:
			nearest = mob
			nearest_dist = dist
	
	return nearest

func _transition_to(new_state: State) -> void:
	if current_state == new_state: return
	
	var old_state_name = State.keys()[current_state]
	var new_state_name = State.keys()[new_state]
	
	print("[HeroAI] %s: %s -> %s" % [hero.name, old_state_name, new_state_name])
	
	current_state = new_state
	state_changed.emit(new_state_name)
	
	# Reset state-specific data
	if new_state == State.PATROL:
		current_target = null
		_pick_new_patrol_target()
		patrol_timer = PATROL_INTERVAL
	elif new_state == State.ENGAGE:
		current_target = null
