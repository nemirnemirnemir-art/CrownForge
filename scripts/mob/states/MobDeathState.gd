extends "res://scripts/mob/states/MobState.gd"

func enter() -> void:
	# print("[MobDeathState] enter() called for mob: %s" % (mob.name if mob else "null"))
	if mob and mob.has_method("die"):
		# print("[MobDeathState] Calling mob.die() for %s" % mob.name)
		mob.die()
	else:
		push_error("[MobDeathState] mob.die() method not found or mob is null!")

func update(_delta: float) -> void:
	pass
