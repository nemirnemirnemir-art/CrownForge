extends RefCounted
class_name ArtifactHealDamage

static func heal_all_active_troops_percent(percent: float) -> void:
	var hero_core := _get_hero_core()
	if percent <= 0.0 or hero_core == null:
		return
	if not hero_core.has_method("get_active_heroes"):
		return
	
	for hero in hero_core.call("get_active_heroes"):
		if not (hero is Dictionary):
			continue
		var hero_id := str((hero as Dictionary).get("id", ""))
		if hero_id == "":
			continue
		_heal_hero_percent(hero_id, percent)

static func heal_random_active_troop_percent(percent: float) -> void:
	var hero_core := _get_hero_core()
	if percent <= 0.0 or hero_core == null:
		return
	if not hero_core.has_method("get_active_heroes"):
		return
	
	var active: Array = hero_core.call("get_active_heroes")
	if active.is_empty():
		return
	var picked: Variant = active[randi() % active.size()]
	if not (picked is Dictionary):
		return
	var hero_id := str((picked as Dictionary).get("id", ""))
	if hero_id == "":
		return
	
	_heal_hero_percent(hero_id, percent)

static func heal_active_class_units(unit_class_name: String, heal_amount: float) -> void:
	var hero_core := _get_hero_core()
	if heal_amount <= 0.0 or hero_core == null:
		return
	var class_id := ArtifactClassBonuses.resolve_unit_class(unit_class_name)
	if class_id < 0:
		return
	
	var troop_core := _get_troop_bonus_core()
	if troop_core == null or not troop_core.has_method("get_unit_classes"):
		return
	if not hero_core.has_method("get_active_heroes") or not hero_core.has_method("heal_hero"):
		return
	
	for hero in hero_core.call("get_active_heroes"):
		if not (hero is Dictionary):
			continue
		var hero_dict := hero as Dictionary
		var hero_id := str(hero_dict.get("id", ""))
		if hero_id == "":
			continue
		var unit_id := _resolve_hero_unit_id(hero_dict, hero_id)
		var classes: Array = troop_core.call("get_unit_classes", unit_id)
		var has_class := false
		for uc in classes:
			if int(uc) == class_id:
				has_class = true
				break
		if not has_class:
			continue
		hero_core.call("heal_hero", hero_id, int(round(heal_amount)))

static func damage_random_enemy(damage: float) -> void:
	if damage <= 0.0:
		return
	var enemies: Array[Node2D] = collect_alive_enemies()
	if enemies.is_empty():
		return
	
	var target: Node2D = enemies[randi() % enemies.size()]
	if not is_instance_valid(target):
		return
	var hurtbox := target.get_node_or_null("Hurtbox")
	if hurtbox and hurtbox.has_method("apply_hit"):
		hurtbox.apply_hit(damage, null, Time.get_ticks_msec())
		return
	if target.has_method("take_damage"):
		target.take_damage(damage)

static func collect_alive_enemies() -> Array[Node2D]:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return []
	var nodes: Array = []
	nodes.append_array(tree.get_nodes_in_group("enemy"))
	nodes.append_array(tree.get_nodes_in_group("mobs"))
	
	var out: Array[Node2D] = []
	var seen: Dictionary = {}
	for node in nodes:
		if node == null or not is_instance_valid(node):
			continue
		if seen.has(node):
			continue
		seen[node] = true
		if not (node is Node2D):
			continue
		var n2 := node as Node2D
		if "is_dead" in n2 and bool(n2.is_dead):
			continue
		out.append(n2)
	return out

static func stun_all_enemies(duration: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var nodes: Array = []
	nodes.append_array(tree.get_nodes_in_group("enemy"))
	nodes.append_array(tree.get_nodes_in_group("mobs"))
	var seen: Dictionary = {}
	for n in nodes:
		if n == null or not is_instance_valid(n):
			continue
		if seen.has(n):
			continue
		seen[n] = true
		var did_apply := false
		if n.has_method("apply_stun"):
			n.apply_stun(duration)
			did_apply = true
		if n is Node2D:
			var n2 := n as Node2D
			if not did_apply:
				if StunEffect:
					StunEffect.attach_to(n2, duration)
				if FloatingText and n2.get_parent():
					FloatingText.spawn_stun(n2.get_parent(), n2.global_position + Vector2(0, -30))

static func _heal_hero_percent(hero_id: String, percent: float) -> void:
	var hero_core := _get_hero_core()
	if hero_core == null:
		return
	var total_stats: Dictionary = {}
	if hero_core.has_method("get_hero_total_stats"):
		var raw_total_stats: Variant = hero_core.call("get_hero_total_stats", hero_id)
		if raw_total_stats is Dictionary:
			total_stats = raw_total_stats as Dictionary
	if total_stats.is_empty():
		return
	var max_hp := float(total_stats.get("maxHp", 0.0))
	var heal_amount := int(round(max_hp * percent))
	if heal_amount > 0 and hero_core.has_method("heal_hero"):
		hero_core.call("heal_hero", hero_id, heal_amount)

static func _resolve_hero_unit_id(hero_dict: Dictionary, hero_id: String) -> String:
	var icon_id := str(hero_dict.get("icon_id", "")).strip_edges().to_lower()
	if icon_id != "":
		return icon_id
	return _resolve_base_unit_id(hero_id)

static func _resolve_base_unit_id(hero_id: String) -> String:
	var id := hero_id.to_lower()
	if id.contains("_"):
		var parts := id.rsplit("_", true, 1)
		if parts.size() == 2 and String(parts[1]).is_valid_int():
			return String(parts[0])
	return id

static func _get_troop_bonus_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TroopBonusCore")


static func _get_hero_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HeroCore")
