extends Node
class_name HeroFieldTargeting

var _hero: Node2D
var _aggro: Node
var _hero_id: String = ""
var _current_target: Node2D = null

func setup(hero: Node2D, aggro_area: Node) -> void:
	_hero = hero
	_aggro = aggro_area

func set_hero_id(hero_id: String) -> void:
	_hero_id = hero_id.to_lower() if hero_id != null else ""

func get_target() -> Node2D:
	if _current_target == null:
		return null
	if not is_instance_valid(_current_target):
		_current_target = null
		return null
	if is_target_dead(_current_target):
		_current_target = null
		return null
	return _current_target

func set_target(t: Node2D) -> void:
	if t != null and is_instance_valid(t) and is_target_dead(t):
		_current_target = null
		return
	_current_target = t

func is_target_dead(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return true
	if target is Mob:
		return bool(target.is_dead)
	if "is_dead" in target:
		return bool(target.is_dead)
	return false

func acquire_best_target() -> Node2D:
	if not _hero:
		return null
	var hero_pos = _hero.global_position
	var candidates: Array = []
	if _aggro and _aggro.has_method("get_targets"):
		candidates = _aggro.get_targets()
	if candidates.is_empty() and _hero.get_tree():
		candidates = _hero.get_tree().get_nodes_in_group("enemy")
	candidates.sort_custom(func(a, b):
		return hero_pos.distance_squared_to(a.global_position) < hero_pos.distance_squared_to(b.global_position)
	)
	for cand in candidates:
		if cand == null or not is_instance_valid(cand):
			continue
		if is_target_dead(cand):
			continue
		if cand.has_method("reserve_slot") and _hero_id != "":
			if cand.reserve_slot(_hero_id):
				set_target(cand)
				return cand
		else:
			set_target(cand)
			return cand
	return null

func release_current_slot() -> void:
	var t := _current_target
	if t and is_instance_valid(t) and t.has_method("release_slot") and _hero_id != "":
		t.release_slot(_hero_id)
