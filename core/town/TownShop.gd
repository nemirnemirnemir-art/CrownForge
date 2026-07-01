extends RefCounted
class_name TownShop

const TOWNHALL_BOTTLE_BASE_PRICE: int = 500
const TOWNHALL_BOTTLE_PRICE_INCREASE: int = 500
const TOWNHALL_BOTTLE_DECAY_PER_MIN: int = 60
const TOWNHALL_BOTTLE_MIN_PRICE: int = 500

var _inventory: TownInventory
var _shop: Dictionary = {}

func initialize(inventory: TownInventory) -> void:
	_inventory = inventory
	_ensure_initialized()

func _ensure_initialized() -> void:
	if _shop.is_empty():
		_shop = {}

	if not _shop.has("bottle_price"):
		_shop["bottle_price"] = TOWNHALL_BOTTLE_BASE_PRICE

	if not _shop.has("last_price_update_unix"):
		_shop["last_price_update_unix"] = int(Time.get_unix_time_from_system())

func _update_bottle_price(now_unix: int) -> void:
	_ensure_initialized()

	var last_unix: int = int(_shop.get("last_price_update_unix", now_unix))
	if now_unix <= last_unix:
		return

	var elapsed_sec: int = now_unix - last_unix
	var minutes: int = int(floor(float(elapsed_sec) / 60.0))
	if minutes <= 0:
		return

	var price: int = int(_shop.get("bottle_price", TOWNHALL_BOTTLE_BASE_PRICE))
	price -= minutes * TOWNHALL_BOTTLE_DECAY_PER_MIN
	if price < TOWNHALL_BOTTLE_MIN_PRICE:
		price = TOWNHALL_BOTTLE_MIN_PRICE

	_shop["bottle_price"] = price
	_shop["last_price_update_unix"] = last_unix + (minutes * 60)

func get_hollow_bottle_price() -> int:
	var now_unix: int = int(Time.get_unix_time_from_system())
	_update_bottle_price(now_unix)
	return int(_shop.get("bottle_price", TOWNHALL_BOTTLE_BASE_PRICE))

func try_buy_hollow_bottle() -> bool:
	var price: int = get_hollow_bottle_price()

	if not is_instance_valid(EconomyCore):
		return false

	if not EconomyCore.spend_gold(float(price)):
		return false

	var item := ItemSystem.create_item(
		"ingredient_hollow_bottle",
		ItemSystem.ItemType.INGREDIENT,
		ItemSystem.Rarity.COMMON,
		"res://assets/items/ingredients/hollow_bottle.png",
		0,
		1
	)

	if _inventory:
		_inventory.add_item(item)

	_shop["bottle_price"] = price + TOWNHALL_BOTTLE_PRICE_INCREASE
	_shop["last_price_update_unix"] = int(Time.get_unix_time_from_system())

	if SaveCore:
		SaveCore.request_save()

	return true

func reset() -> void:
	_shop = {}
	_ensure_initialized()

func get_save_data() -> Dictionary:
	_ensure_initialized()
	return _shop

func load_save_data(data: Dictionary) -> void:
	if data is Dictionary:
		_shop = data
	_ensure_initialized()
