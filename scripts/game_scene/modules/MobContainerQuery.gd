extends RefCounted
class_name MobContainerQuery


func clear_mobs(mob_container: Node) -> void:
	if mob_container == null:
		return
	for child in mob_container.get_children():
		if child is Mob:
			child.queue_free()


func get_alive_mobs(mob_container: Node) -> Array:
	var alive: Array = []
	if mob_container == null:
		return alive

	for child in mob_container.get_children():
		if child is Mob and is_instance_valid(child) and not child.is_dead:
			alive.append(child)

	return alive


func set_wall_attack_stop_distance(mob_container: Node, distance: float) -> void:
	if mob_container == null:
		return
	for child in mob_container.get_children():
		if child is Mob and child.has_method("set_wall_attack_stop_distance"):
			child.set_wall_attack_stop_distance(distance)
