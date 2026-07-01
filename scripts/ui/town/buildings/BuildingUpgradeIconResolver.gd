extends RefCounted
class_name BuildingUpgradeIconResolver
## Resolves upgrade icons for buildings.
## Icons are stored as PNGs under res://assets/ui/buildings/upgrade_icons/<building_id>/<index>_<slug>.png.
## The ICON_PATHS dictionary maps "building_id:index" to the resource path.
## At runtime, icons are loaded lazily via load() on first access and cached.

const ICON_BASE := "res://assets/ui/buildings/upgrade_icons"

## Canonical mapping: upgrade_id -> resource path.
## Only entries with actual icon assets are listed here.
const ICON_PATHS := {
	# --- Production buildings ---
	"clay_mine:0": "res://assets/ui/buildings/upgrade_icons/clay_mine/0_zero_waste.png",
	"clay_mine:1": "res://assets/ui/buildings/upgrade_icons/clay_mine/1_clay_mine_production.png",
	"crystal_mine:0": "res://assets/ui/buildings/upgrade_icons/crystal_mine/0_magic_aura.png",
	"gold_mine:0": "res://assets/ui/buildings/upgrade_icons/gold_mine/0_rich_veins.png",
	"gold_mine:1": "res://assets/ui/buildings/upgrade_icons/gold_mine/1_gold_mine_production.png",
	"iron_mine:0": "res://assets/ui/buildings/upgrade_icons/iron_mine/0_troop_inspiration.png",
	"iron_mine:1": "res://assets/ui/buildings/upgrade_icons/iron_mine/1_iron_mine_production.png",
	"sawmill:0": "res://assets/ui/buildings/upgrade_icons/sawmill/0_sawmill_production.png",
	"sawmill:1": "res://assets/ui/buildings/upgrade_icons/sawmill/1_friendly_lumberjacks.png",
	"vineyard:0": "res://assets/ui/buildings/upgrade_icons/vineyard/0_grape_varieties.png",
	"vineyard:1": "res://assets/ui/buildings/upgrade_icons/vineyard/1_vineyard_production.png",
	"wheat_field:0": "res://assets/ui/buildings/upgrade_icons/wheat_field/0_farm_production.png",
	"wheat_field:1": "res://assets/ui/buildings/upgrade_icons/wheat_field/1_gold_diggers.png",

	# --- Processing / special production ---
	"animal_farm:0": "res://assets/ui/buildings/upgrade_icons/animal_farm/0_production_speed.png",
	"animal_farm:1": "res://assets/ui/buildings/upgrade_icons/animal_farm/1_troop_inspiration.png",
	"fishermans_hut:0": "res://assets/ui/buildings/upgrade_icons/fishermans_hut/0_production_speed.png",
	"fishermans_hut:1": "res://assets/ui/buildings/upgrade_icons/fishermans_hut/1_quality_lure.png",
	"forge:0": "res://assets/ui/buildings/upgrade_icons/forge/0_efficient_processing.png",
	"forge:1": "res://assets/ui/buildings/upgrade_icons/forge/1_troop_inspiration.png",
	"fuel_pump:0": "res://assets/ui/buildings/upgrade_icons/fuel_pump/0_production_speed.png",
	"fuel_pump:1": "res://assets/ui/buildings/upgrade_icons/fuel_pump/1_gifts_of_the_earth.png",
	"market:0": "res://assets/ui/buildings/upgrade_icons/market/0_charismatic_traders.png",
	"market:1": "res://assets/ui/buildings/upgrade_icons/market/1_faster_trading.png",
	"mill:0": "res://assets/ui/buildings/upgrade_icons/mill/0_efficient_processing.png",
	"mill:1": "res://assets/ui/buildings/upgrade_icons/mill/1_troop_inspiration.png",
	"winery:0": "res://assets/ui/buildings/upgrade_icons/winery/0_production_speed.png",
	"winery:1": "res://assets/ui/buildings/upgrade_icons/winery/1_wine_for_all.png",

	# --- Magic academies ---
	"academy_of_fire:0": "res://assets/ui/buildings/upgrade_icons/academy_of_fire/0_combustion.png",
	"academy_of_fire:1": "res://assets/ui/buildings/upgrade_icons/academy_of_fire/1_damage_dealt_by_mages.png",
	"academy_of_fire:2": "res://assets/ui/buildings/upgrade_icons/academy_of_fire/2_fire_mages_capacity.png",
	"academy_of_lightning:0": "res://assets/ui/buildings/upgrade_icons/academy_of_lightning/0_lightning_mages_capacity.png",
	"academy_of_lightning:1": "res://assets/ui/buildings/upgrade_icons/academy_of_lightning/1_hp_and_damage.png",
	"academy_of_lightning:2": "res://assets/ui/buildings/upgrade_icons/academy_of_lightning/2_jumping_lightning.png",
}

## Runtime cache: upgrade_id -> Texture2D (or null if already attempted and missing).
static var _cache := {}


static func has_icon(building_id: String, upgrade_index: int) -> bool:
	var upgrade_id := _make_id(building_id, upgrade_index)
	return ICON_PATHS.has(upgrade_id)


static func get_icon(building_id: String, upgrade_index: int) -> Texture2D:
	var upgrade_id := _make_id(building_id, upgrade_index)

	if _cache.has(upgrade_id):
		return _cache[upgrade_id] as Texture2D

	if not ICON_PATHS.has(upgrade_id):
		_cache[upgrade_id] = null
		return null

	var path: String = ICON_PATHS[upgrade_id]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	else:
		push_warning("BuildingUpgradeIconResolver: icon path registered but file missing: %s" % path)

	_cache[upgrade_id] = tex
	return tex


static func get_icon_or_null(building_id: String, upgrade_index: int) -> Texture2D:
	return get_icon(building_id, upgrade_index)


static func clear_cache() -> void:
	_cache.clear()


## Returns upgrade count that have icons for a given building.
static func icon_count_for_building(building_id: String) -> int:
	var count := 0
	for key: String in ICON_PATHS:
		if key.begins_with(String(building_id).strip_edges().to_lower() + ":"):
			count += 1
	return count


static func _make_id(building_id: String, upgrade_index: int) -> String:
	return "%s:%d" % [String(building_id).strip_edges().to_lower(), upgrade_index]
