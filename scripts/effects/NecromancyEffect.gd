extends SpellEffect

## Necromancy spell - resurrects up to 6 corpses as Small Bones skeletons

const HeroSceneRegistryScript = preload("res://scripts/hero/HeroSceneRegistry.gd")

const MAX_SKELETONS: int = 6
const SKELETON_DURATION: float = 30.0  # 30 seconds lifetime
const DEFAULT_RADIUS: float = 200.0
const RADIUS_MULTIPLIER: float = 0.5

func execute_effect() -> void:
	var base_radius := DEFAULT_RADIUS
	if config != null and config.target_radius > 0.0:
		base_radius = config.target_radius
	var cast_radius := get_scaled_radius(base_radius * RADIUS_MULTIPLIER)

	# Get available corpses inside cast area
	var corpses: Array[Corpse] = _collect_corpses_in_radius(MAX_SKELETONS, cast_radius)
	
	if corpses.is_empty():
		print("[NecromancyEffect] No corpses available!")
		queue_free()
		return
	
	print("[NecromancyEffect] Found %d corpses, spawning skeletons" % corpses.size())

	var skeleton_scene := HeroSceneRegistryScript.load_scene("small_bones")
	if skeleton_scene == null:
		push_error("[NecromancyEffect] Hero scene not found for unit: small_bones")
		queue_free()
		return
	
	# Spawn skeleton for each corpse
	for corpse in corpses:
		if not is_instance_valid(corpse):
			continue
		
		var spawn_pos: Vector2 = corpse.global_position
		
		# Consume corpse instantly (no animation)
		corpse.consume_for_necromancy()
		
		# Spawn Small Bones skeleton
		var skeleton: Node2D = skeleton_scene.instantiate()
		
		if get_parent():
			get_parent().add_child(skeleton)
		else:
			get_tree().current_scene.add_child(skeleton)
		
		skeleton.global_position = spawn_pos
		
		# Initialize as temporary summon
		if skeleton.has_method("initialize_as_summon"):
			skeleton.initialize_as_summon(SKELETON_DURATION)
		elif "summon_duration" in skeleton:
			skeleton.summon_duration = SKELETON_DURATION
		
		print("[NecromancyEffect] Spawned Small Bones at %s" % spawn_pos)
	
	queue_free()

func _collect_corpses_in_radius(count: int, radius: float) -> Array[Corpse]:
	var result: Array[Corpse] = []
	var radius_sq := radius * radius
	var candidates: Array[Corpse] = []

	for corpse in Corpse.active_corpses:
		if corpse == null or not is_instance_valid(corpse):
			continue
		if corpse.global_position.distance_squared_to(global_position) > radius_sq:
			continue
		candidates.append(corpse)

	candidates.sort_custom(func(a: Corpse, b: Corpse):
		return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position)
	)

	for i in range(mini(count, candidates.size())):
		result.append(candidates[i])

	return result
