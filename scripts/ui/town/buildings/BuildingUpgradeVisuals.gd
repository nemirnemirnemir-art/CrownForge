extends RefCounted
class_name BuildingUpgradeVisuals

const STRIPE_LEVEL_1: Texture2D = preload("res://assets/ui/buildings/upgrade_stripes/stripe.png")
const STRIPE_LEVEL_2: Texture2D = preload("res://assets/ui/buildings/upgrade_stripes/stripe2.png")
const STRIPE_LEVEL_3: Texture2D = preload("res://assets/ui/buildings/upgrade_stripes/stripe3.png")

const STATUS_WORKING := "working"
const STATUS_NEEDS_TEST := "needs_test"
const STATUS_MISSING := "missing"

const SLOT_COLOR_UNLOCKED := Color(0.25, 0.8, 0.35, 1.0)
const SLOT_COLOR_LOCKED := Color(0.45, 0.45, 0.45, 1.0)
const SLOT_COLOR_EMPTY := Color(0.95, 0.95, 0.95, 1.0)

const STATUS_COLOR_WORKING := Color(0.25, 0.8, 0.35, 1.0)
const STATUS_COLOR_NEEDS_TEST := Color(0.95, 0.78, 0.25, 1.0)
const STATUS_COLOR_MISSING := Color(0.85, 0.25, 0.25, 1.0)

const EXPLICIT_WORKING_UPGRADES := {
	"archmages_university:0": true,
	"archmages_university:1": true,
	"arena:0": true,
	"arena:1": true,
	"brick_factory:0": true,
	"brick_factory:1": true,
	"buddhist_temple:0": true,
	"buddhist_temple:1": true,
	"buddhist_temple:2": true,
	"concert:0": true,
	"concert:1": true,
	"execution_ground:0": true,
	"execution_ground:1": true,
	"fairy_fountain:0": true,
	"fairy_fountain:1": true,
	"hero_statue:0": true,
	"hospital:0": true,
	"hospital:1": true,
	"kings_statue:0": true,
	"kings_statue:1": true,
	"magic_ball:0": true,
	"magic_ball:1": true,
	"magic_college:0": true,
	"magic_college:1": true,
	"stables:2": true,
	"tesla_tower:0": true,
	"tesla_tower:1": true,
	"tesla_tower:2": true,
	"wheel_of_fortune:0": true,
}

func _init() -> void:
	pass

static func _building_registry() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BuildingRegistry")

static func make_upgrade_id(building_id: String, upgrade_index: int) -> String:
	return "%s:%d" % [String(building_id).strip_edges().to_lower(), upgrade_index]

static func get_upgrade_status(building_id: String, upgrade_index: int) -> String:
	var upgrade_id := make_upgrade_id(building_id, upgrade_index)
	if EXPLICIT_WORKING_UPGRADES.has(upgrade_id):
		return STATUS_WORKING

	var building_registry := _building_registry()
	if building_registry:
		var config: BuildingConfig = building_registry.get_building(String(building_id).strip_edges().to_lower())
		if config and config.building_type == BuildingConfig.BuildingType.MILITARY:
			return STATUS_NEEDS_TEST

	return STATUS_MISSING

static func get_status_color(status: String) -> Color:
	match String(status):
		STATUS_WORKING:
			return STATUS_COLOR_WORKING
		STATUS_NEEDS_TEST:
			return STATUS_COLOR_NEEDS_TEST
		_:
			return STATUS_COLOR_MISSING

static func get_upgrade_color(building_id: String, upgrade_index: int) -> Color:
	return get_status_color(get_upgrade_status(building_id, upgrade_index))

static func get_stripe_texture(level: int) -> Texture2D:
	match int(level):
		1:
			return STRIPE_LEVEL_1
		2:
			return STRIPE_LEVEL_2
		3:
			return STRIPE_LEVEL_3
		_:
			return null
