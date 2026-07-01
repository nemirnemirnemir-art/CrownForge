extends RefCounted
class_name ForgeEconomy

signal forge_cores_gained(amount: int)

func can_afford_forge_cores(amount: int) -> bool:
	if EconomyCore:
		return EconomyCore.can_afford_forge_cores(amount)
	return false

func spend_forge_cores(amount: int) -> bool:
	if EconomyCore:
		return EconomyCore.spend_forge_cores(amount)
	return false

func gain_forge_cores(amount: int) -> void:
	if EconomyCore:
		EconomyCore.add_forge_cores(amount)
	forge_cores_gained.emit(amount)
