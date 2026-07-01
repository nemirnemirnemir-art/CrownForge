extends RefCounted
class_name WaveRewardExecutor

func execute(reward_type: String, get_economy_core: Callable, open_submenu: Callable) -> bool:
	var base_type := reward_type
	var amount: float = 0.0
	if reward_type.contains(":"):
		var parts := reward_type.split(":")
		if parts.size() >= 2:
			base_type = parts[0]
			amount = float(parts[1])

	match base_type:
		"denarii":
			var economy_core: Variant = get_economy_core.call()
			if economy_core != null and economy_core.has_method("add_gold"):
				var granted_amount := amount if amount > 0.0 else 10.0
				economy_core.call("add_gold", granted_amount)
				print("[WaveRewardMenu] Added %s Denarii" % granted_amount)
			return true
		"trader":
			open_submenu.call("trader")
			return false
		"resource":
			open_submenu.call("resource", int(amount))
			return false
		"levy":
			open_submenu.call("levy")
			return false
		"production", "production_basic":
			open_submenu.call("production")
			return false
		"production_established":
			open_submenu.call("production_established")
			return false
		"infrastructure":
			open_submenu.call("infrastructure")
			return false
		"spell":
			open_submenu.call("spell")
			return false
		"legendary_spell":
			open_submenu.call("legendary_spell")
			return false
		"production_advanced":
			open_submenu.call("production_advanced")
			return false
		"veteran":
			open_submenu.call("veteran")
			return false
		"elite":
			open_submenu.call("elite")
			return false
		"artifact", "legendary_artifact":
			open_submenu.call("artifact")
			return false
		"building_upgrade":
			open_submenu.call("building_upgrade")
			return false
		"troop_training":
			open_submenu.call("troop_training")
			return false
		"prophecy":
			open_submenu.call("prophecy")
			return false
		"placeholder":
			print("[WaveRewardMenu] Placeholder reward clicked (no effect)")
		"no_reward":
			print("[WaveRewardMenu] No rewards for this wave")
	return true
