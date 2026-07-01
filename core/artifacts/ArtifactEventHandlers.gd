extends RefCounted
class_name ArtifactEventHandlers

const ArtifactSummonFlowScript := preload("res://core/artifacts/ArtifactSummonFlow.gd")
const ArtifactDeathSummonDomainScript := preload("res://core/artifacts/ArtifactDeathSummonDomain.gd")
const ArtifactFriendlyDeathBuffDomainScript := preload("res://core/artifacts/ArtifactFriendlyDeathBuffDomain.gd")

static func _get_autoload(name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(name)

static func _get_save_core() -> Node:
	return _get_autoload("SaveCore")

static func _get_castle_core() -> Node:
	return _get_autoload("CastleCore")

static func _apply_add_resource_effect(def: Dictionary) -> void:
	var resource_core := _get_autoload("ResourceCore")
	if resource_core == null or not resource_core.has_method("add_resource"):
		return
	resource_core.call("add_resource", str(def.get("effect_resource_id", "")), int(def.get("effect_value", 0)))

static func on_enemy_killed(active: Dictionary, state: Dictionary, enemy_id: String) -> void:
	for artifact_id in active.keys():
		var aid := str(artifact_id)
		var def := ArtifactCatalog.get_def(aid)
		var kind := str(def.get("effect_kind", ""))
		if kind == "on_enemy_killed_add_resource":
			_apply_add_resource_effect(def)
		elif kind == "spell_damage_percent_per_enemy_killed":
			var add_pct := float(def.get("effect_value", 0.0))
			if add_pct > 0.0:
				var current_x10000 := ArtifactState.get_int(state, aid, "spell_damage_pct_x10000", 0)
				var add_x10000 := int(round(add_pct * 10000.0))
				ArtifactState.set_int(state, aid, "spell_damage_pct_x10000", current_x10000 + add_x10000)
				var save_core := _get_save_core()
				if save_core != null and save_core.has_method("request_save"):
					save_core.call("request_save")
		elif kind == "on_enemy_killed_heal_random_troop_percent_max":
			ArtifactHealDamage.heal_random_active_troop_percent(float(def.get("effect_value", 0.0)))

static func on_wave_started(active: Dictionary, state: Dictionary, wave_number: int) -> void:
	for artifact_id in active.keys():
		var aid := str(artifact_id)
		var def := ArtifactCatalog.get_def(aid)
		var kind := str(def.get("effect_kind", ""))
		if kind == "on_wave_started_add_resource":
			_apply_add_resource_effect(def)
		elif kind == "on_wave_started_add_random_basic_resource":
			ArtifactEffectExecutor.add_random_basic_resource(int(def.get("effect_value", 0)))
		elif kind == "on_wave_started_add_spell_every_n":
			var next_counter := ArtifactState.get_int(state, aid, "wave_counter", 0) + 1
			ArtifactState.set_int(state, aid, "wave_counter", next_counter)
			var every_n: int = max(1, int(def.get("effect_every_n_waves", 1)))
			if next_counter % every_n == 0:
				ArtifactSpellRewards.queue_fixed_spell_rewards(str(def.get("effect_spell_id", "")), int(def.get("effect_spell_amount", 1)))
		elif kind == "on_wave_started_heal_all_troops_percent_max":
			ArtifactHealDamage.heal_all_active_troops_percent(float(def.get("effect_value", 0.0)))
	if active.has("family_crossbow"):
		ArtifactSummonFlowScript.spawn_temporary_units(active, "crossbowman", 2, 30.0)
	if active.has("rusty_bell"):
		ArtifactSummonFlowScript.spawn_temporary_units(active, "goose_rider", 2, 30.0)

static func on_hero_died(active: Dictionary, state: Dictionary, hero_id: String) -> void:
	var state_changed := false
	if ArtifactSummonFlowScript.try_resummon_temporary_unit(active, hero_id):
		state_changed = true
	var death_pos := _resolve_hero_death_position(hero_id)
	for artifact_id in active.keys():
		var def := ArtifactCatalog.get_def(str(artifact_id))
		var kind := str(def.get("effect_kind", ""))
		if kind == "on_troop_died_heal_castle":
			var castle_core := _get_castle_core()
			if castle_core != null and castle_core.has_method("heal"):
				castle_core.call("heal", int(def.get("effect_value", 0)))
		elif kind == "on_troop_died_delayed_blade_strike":
			var damage := float(def.get("effect_value", 0.0))
			if damage > 0.0:
				_schedule_delayed_blade_strike(damage, 50.0)
	ArtifactFriendlyDeathBuffDomainScript.on_friendly_troop_died(active, hero_id)
	state_changed = _apply_death_summon_domain(active, state, death_pos) or state_changed
	if active.has("healing_banner") and randf() < 0.25:
		_spawn_healing_pool_at_hero_death(hero_id)
	if state_changed:
		var save_core_after := _get_save_core()
		if save_core_after != null and save_core_after.has_method("request_save"):
			save_core_after.call("request_save")

static func _schedule_delayed_blade_strike(damage: float, delay: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var artifact_core := tree.root.get_node_or_null("ArtifactCore")
	if artifact_core == null:
		return
	
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = maxf(0.0, delay)
	artifact_core.add_child(t)
	t.timeout.connect(func():
		_execute_delayed_blade_strike(damage)
		if is_instance_valid(t):
			t.queue_free()
	)
	t.start()

static func _execute_delayed_blade_strike(damage: float) -> void:
	var candidates := ArtifactHealDamage.collect_alive_enemies()
	if candidates.is_empty():
		return
	
	var target := candidates[randi_range(0, candidates.size() - 1)]
	if not is_instance_valid(target):
		return
	
	var parent := target.get_parent()
	if parent == null:
		return
	
	var blade_scene := preload("res://scenes/spells/effects/FallingBlade.tscn")
	if blade_scene:
		var blade := blade_scene.instantiate()
		parent.add_child(blade)
		if blade is Node2D:
			(blade as Node2D).global_position = target.global_position
		if blade.has_method("setup"):
			blade.setup(damage, 0.0, target)
		return
	
	var hb := target.get_node_or_null("Hurtbox")
	if hb and hb.has_method("apply_hit"):
		hb.apply_hit(damage, null, Time.get_ticks_msec())
		return
	
	if target.has_method("take_damage"):
		target.take_damage(damage)

static func _spawn_healing_pool_at_hero_death(hero_id: String) -> void:
	var game_scene := _get_game_scene()
	if game_scene == null:
		return
	var death_pos := _resolve_hero_death_position(hero_id)
	if death_pos == Vector2.INF:
		return
	var pool_scene := load("res://scenes/spells/effects/HealingPoolEffect.tscn") as PackedScene
	if pool_scene == null:
		return
	var pool := pool_scene.instantiate()
	if pool == null:
		return
	var parent := game_scene.get_node_or_null("WorldYSort/MapContainer")
	if parent == null:
		parent = game_scene
	parent.add_child(pool)
	if pool is Node2D:
		(pool as Node2D).global_position = death_pos
	if pool.has_method("execute_effect"):
		pool.execute_effect()

static func _apply_death_summon_domain(active: Dictionary, state: Dictionary, death_pos: Vector2) -> bool:
	var specs: Array = ArtifactDeathSummonDomainScript.collect_death_triggers(active, state)
	if specs.is_empty():
		return false
	for raw_spec in specs:
		if not (raw_spec is Dictionary):
			continue
		_apply_death_trigger_spec(raw_spec as Dictionary, active, death_pos)
	return true

static func _apply_death_trigger_spec(spec: Dictionary, active: Dictionary, death_pos: Vector2) -> void:
	var kind := str(spec.get("type", ""))
	if kind == "temporary_unit":
		var unit_id := str(spec.get("unit_id", ""))
		var duration := float(spec.get("duration", 0.0))
		if unit_id == "" or duration <= 0.0:
			return
		ArtifactSummonFlowScript.spawn_temporary_units(active, unit_id, 1, duration, [death_pos])
	elif kind == "recruit_unit":
		_recruit_unit_at_position(str(spec.get("unit_id", "")), death_pos)
	elif kind == "effect":
		_spawn_effect_scene_at_position(str(spec.get("scene_path", "")), death_pos)

static func _spawn_effect_scene_at_position(scene_path: String, world_position: Vector2) -> void:
	if scene_path == "":
		return
	var game_scene := _get_game_scene()
	if game_scene == null:
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return
	var effect := packed.instantiate()
	if effect == null:
		return
	var parent := game_scene.get_node_or_null("WorldYSort/MapContainer")
	if parent == null:
		parent = game_scene
	parent.add_child(effect)
	if effect is Node2D and world_position != Vector2.INF:
		(effect as Node2D).global_position = world_position
	if effect.has_method("execute_effect"):
		effect.call("execute_effect")

static func _get_game_scene() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var game_scene := tree.get_first_node_in_group("game_scene")
	if game_scene != null:
		return game_scene
	return tree.current_scene

static func _resolve_hero_death_position(hero_id: String) -> Vector2:
	var game_scene := _get_game_scene()
	if game_scene == null:
		return Vector2.INF
	var heroes_manager: Variant = game_scene.get("_heroes_manager")
	if heroes_manager != null and heroes_manager.has_method("get_hero_position"):
		var hero_pos: Vector2 = heroes_manager.call("get_hero_position", hero_id)
		if hero_pos != Vector2.INF:
			return hero_pos
	if heroes_manager != null and heroes_manager.has_method("pop_death_position"):
		return heroes_manager.call("pop_death_position", hero_id)
	return Vector2.INF

static func _recruit_unit_at_position(unit_id: String, world_position: Vector2) -> void:
	var safe_unit_id := String(unit_id).strip_edges().to_lower()
	if safe_unit_id == "":
		return
	var hero_core := _get_autoload("HeroCore")
	if hero_core == null:
		return
	if not hero_core.has_method("ensure_hero_template") or not hero_core.has_method("hire_hero_copy") or not hero_core.has_method("add_to_squad"):
		return
	var display_name := safe_unit_id.capitalize().replace("_", " ")
	hero_core.call("ensure_hero_template", safe_unit_id, display_name, 0.0)
	var new_id := String(hero_core.call("hire_hero_copy", safe_unit_id))
	if new_id == "":
		return
	if not bool(hero_core.call("add_to_squad", new_id)):
		return
	_position_active_hero(new_id, world_position)

static func _position_active_hero(hero_id: String, world_position: Vector2) -> void:
	if world_position == Vector2.INF:
		return
	var game_scene := _get_game_scene()
	if game_scene == null:
		return
	var heroes_manager: Variant = game_scene.get("_heroes_manager")
	if heroes_manager == null:
		return
	var active_nodes: Variant = heroes_manager.get("active_heroes_on_field")
	if active_nodes is Dictionary and (active_nodes as Dictionary).has(hero_id):
		var hero_node: Variant = (active_nodes as Dictionary).get(hero_id)
		if hero_node is Node2D and is_instance_valid(hero_node):
			(hero_node as Node2D).global_position = world_position
			return
	if heroes_manager.has_method("spawn_hero_on_field"):
		heroes_manager.call("spawn_hero_on_field", hero_id, world_position)
