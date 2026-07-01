extends SceneTree

const TownShopFlowScript := preload("res://core/town/TownShopFlow.gd")


class FakeShop:
	extends RefCounted

	var price: int = 777
	var buy_result: bool = true
	var buy_calls: int = 0

	func get_hollow_bottle_price() -> int:
		return price

	func try_buy_hollow_bottle() -> bool:
		buy_calls += 1
		return buy_result


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = TownShopFlowScript.new()
	if flow == null:
		push_error("[test_towncore_shop_flow] failed to instantiate helper")
		quit(1)
		return

	var shop := FakeShop.new()
	if flow.get_townhall_hollow_bottle_price(shop, 500) != 777:
		push_error("[test_towncore_shop_flow] shop price must come from TownShop")
		quit(1)
		return
	if not flow.try_buy_townhall_hollow_bottle(shop):
		push_error("[test_towncore_shop_flow] expected buy to succeed")
		quit(1)
		return
	if shop.buy_calls != 1:
		push_error("[test_towncore_shop_flow] buy call not forwarded")
		quit(1)
		return

	shop.buy_result = false
	if flow.try_buy_townhall_hollow_bottle(shop):
		push_error("[test_towncore_shop_flow] failed buy must stay false")
		quit(1)
		return

	print("[test_towncore_shop_flow] PASS")
	quit(0)
