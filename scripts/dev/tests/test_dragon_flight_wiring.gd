extends SceneTree

const DragonScene := preload("res://scenes/mobs/Dragon.tscn")

func _init() -> void:
	var dragon := DragonScene.instantiate()
	if dragon == null:
		push_error("[test_dragon_flight_wiring] failed to instantiate Dragon scene")
		quit(1)
		return

	if dragon.get_node_or_null("AnimWalk") == null:
		push_error("[test_dragon_flight_wiring] missing AnimWalk")
		quit(1)
		return
	if dragon.get_node_or_null("AnimAttack") == null:
		push_error("[test_dragon_flight_wiring] missing AnimAttack")
		quit(1)
		return
	if dragon.get_node_or_null("AnimUp") == null:
		push_error("[test_dragon_flight_wiring] missing AnimUp")
		quit(1)
		return
	if dragon.get_node_or_null("AnimFly") == null:
		push_error("[test_dragon_flight_wiring] missing AnimFly")
		quit(1)
		return

	if dragon.get_node_or_null("MobStateMachine/DragonFlyUpState") == null:
		push_error("[test_dragon_flight_wiring] missing DragonFlyUpState")
		quit(1)
		return
	if dragon.get_node_or_null("MobStateMachine/DragonFlyAcrossState") == null:
		push_error("[test_dragon_flight_wiring] missing DragonFlyAcrossState")
		quit(1)
		return
	if dragon.get_node_or_null("MobStateMachine/DragonFlyReturnState") == null:
		push_error("[test_dragon_flight_wiring] missing DragonFlyReturnState")
		quit(1)
		return

	if int(dragon.get("max_flights")) != 3:
		push_error("[test_dragon_flight_wiring] max_flights must be 3 by default")
		quit(1)
		return
	if not is_equal_approx(float(dragon.get("takeoff_height_px")), 300.0):
		push_error("[test_dragon_flight_wiring] takeoff_height_px must be 300")
		quit(1)
		return
	if not is_equal_approx(float(dragon.get("return_delay_sec")), 5.0):
		push_error("[test_dragon_flight_wiring] return_delay_sec must be 5")
		quit(1)
		return

	print("[test_dragon_flight_wiring] PASS")
	quit(0)
