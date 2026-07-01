extends SpellEffect

## Summon Infernals spell - spawns a temporary infernal ally

const InfernalUnitScene = preload("res://scenes/spells/effects/InfernalUnit.tscn")

const SUMMON_DURATION: float = 30.0

func execute_effect() -> void:
	var summon_duration := SUMMON_DURATION
	if config != null and config.duration > 0.0:
		summon_duration = config.duration
	
	var infernal: Node2D = InfernalUnitScene.instantiate()
	
	# Add to world
	if get_parent():
		get_parent().add_child(infernal)
	else:
		get_tree().current_scene.add_child(infernal)
	
	infernal.global_position = target_position
	
	if infernal.has_method("setup"):
		infernal.setup(summon_duration)
	
	# print("[SummonInfernalsEffect] Spawned infernal at %s" % target_position)
	
	# Self-destruct after spawning
	queue_free()
