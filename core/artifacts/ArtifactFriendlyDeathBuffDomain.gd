extends RefCounted
class_name ArtifactFriendlyDeathBuffDomain

const StatusIconServiceScript := preload("res://scripts/effects/shared/StatusIconService.gd")

const HAND_OF_THE_AVENGED_ID := "hand_of_the_avenged"
const BUFF_DURATION: float = 6.0
const SPEED_MULTIPLIER: float = 1.3
const ATTACK_SPEED_MULTIPLIER: float = 1.3
const ICON_PATH: String = "res://assets/vfx/spells/Wrath.png"
const ICON_NAME: String = "HandOfTheAvengedIcon"
const ICON_OFFSET_Y: float = -55.0


static func on_friendly_troop_died(active: Dictionary, dead_hero_id: String) -> void:
	if not active.has(HAND_OF_THE_AVENGED_ID):
		return
	var candidates := _collect_living_friendlies(dead_hero_id)
	if candidates.is_empty():
		return
	var target := candidates[randi() % candidates.size()]
	_apply_hand_of_the_avenged_buff(target)


static func _collect_living_friendlies(dead_hero_id: String) -> Array[Node2D]:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return []

	var out: Array[Node2D] = []
	for node in tree.get_nodes_in_group("hero"):
		if not (node is Node2D):
			continue
		var hero := node as Node2D
		if hero == null or not is_instance_valid(hero):
			continue
		if _is_matching_dead_hero(hero, dead_hero_id):
			continue
		if _is_dead(hero):
			continue
		if not _can_receive_enrage(hero):
			continue
		out.append(hero)
	return out


static func _is_matching_dead_hero(hero: Node2D, dead_hero_id: String) -> bool:
	if dead_hero_id == "":
		return false
	if "hero_id" in hero:
		return str(hero.get("hero_id")) == dead_hero_id
	return false


static func _is_dead(hero: Node2D) -> bool:
	if "is_dead" in hero:
		return bool(hero.get("is_dead"))
	return false


static func _can_receive_enrage(hero: Node2D) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	var has_speed_stat := "speed_multiplier" in hero
	var has_attack_speed_stat := "attack_speed_multiplier" in hero
	if not has_speed_stat and not has_attack_speed_stat:
		return false
	if "hero_id" in hero and str(hero.get("hero_id")) != "":
		return true
	if hero.is_in_group("summon"):
		return true
	return hero.has_method("take_damage") or hero.has_method("apply_damage")


static func _apply_hand_of_the_avenged_buff(hero: Node2D) -> void:
	if hero == null or not is_instance_valid(hero):
		return

	var applied_speed_mult: float = 1.0
	var applied_attack_speed_mult: float = 1.0

	if "speed_multiplier" in hero:
		hero.set("speed_multiplier", float(hero.get("speed_multiplier")) * SPEED_MULTIPLIER)
		applied_speed_mult = SPEED_MULTIPLIER

	if "attack_speed_multiplier" in hero:
		hero.set("attack_speed_multiplier", float(hero.get("attack_speed_multiplier")) * ATTACK_SPEED_MULTIPLIER)
		applied_attack_speed_mult = ATTACK_SPEED_MULTIPLIER

	var icon: Sprite2D = StatusIconServiceScript.add_status_icon(hero, ICON_PATH, ICON_NAME, ICON_OFFSET_Y)
	_schedule_buff_removal(hero, icon, applied_speed_mult, applied_attack_speed_mult)


static func _schedule_buff_removal(hero: Node2D, icon: Sprite2D, applied_speed_mult: float, applied_attack_speed_mult: float) -> void:
	var tree: SceneTree = hero.get_tree()
	if tree == null:
		return
	var hero_ref: WeakRef = weakref(hero)
	var icon_ref: Variant = weakref(icon) if icon != null else null
	var timer: SceneTreeTimer = tree.create_timer(BUFF_DURATION)
	timer.timeout.connect(func() -> void:
		_remove_hand_of_the_avenged_buff(hero_ref, icon_ref, applied_speed_mult, applied_attack_speed_mult)
	)


static func _remove_hand_of_the_avenged_buff(hero_ref: WeakRef, icon_ref: Variant, applied_speed_mult: float, applied_attack_speed_mult: float) -> void:
	var hero_obj: Object = hero_ref.get_ref()
	if hero_obj != null and hero_obj is Node2D and is_instance_valid(hero_obj):
		var hero := hero_obj as Node2D
		if "speed_multiplier" in hero and applied_speed_mult > 0.001:
			hero.set("speed_multiplier", maxf(0.01, float(hero.get("speed_multiplier")) / applied_speed_mult))
		if "attack_speed_multiplier" in hero and applied_attack_speed_mult > 0.001:
			hero.set("attack_speed_multiplier", maxf(0.01, float(hero.get("attack_speed_multiplier")) / applied_attack_speed_mult))
		StatusIconServiceScript.remove_status_icon(hero, icon_ref)
		return

	var icon_obj := _resolve_node(icon_ref)
	if icon_obj != null and is_instance_valid(icon_obj):
		icon_obj.queue_free()


static func _resolve_node(value: Variant) -> Node:
	if value == null:
		return null
	if value is WeakRef:
		var obj: Object = (value as WeakRef).get_ref()
		if obj != null and obj is Node:
			return obj as Node
		return null
	if value is Node:
		return value as Node
	return null
