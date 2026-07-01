extends RefCounted
class_name TownShopFlow


func get_townhall_hollow_bottle_price(shop, fallback_price: int) -> int:
	return shop.get_hollow_bottle_price() if shop else fallback_price


func try_buy_townhall_hollow_bottle(shop) -> bool:
	return shop.try_buy_hollow_bottle() if shop else false
