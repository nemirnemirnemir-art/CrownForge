extends SceneTree

const CLAY_MINE := preload("res://data/buildings/established_production/clay_mine.tres")
const IRON_MINE := preload("res://data/buildings/established_production/iron_mine.tres")
const GOLD_MINE := preload("res://data/buildings/established_production/gold_mine.tres")
const CRYSTAL_MINE := preload("res://data/buildings/established_production/crystal_mine.tres")
const SAWMILL := preload("res://data/buildings/established_production/sawmill.tres")
const NETHER_RUNE_ENCHANTERY := preload("res://data/buildings/established_production/nether_rune_enchantery.tres")
const WHEAT_FIELD := preload("res://data/buildings/established_production/wheat_field.tres")
const WALL_HEALTH_UI_SCENE := preload("res://scenes/ui/hud/WallHealthUI.tscn")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var configs := {
		"clay_mine": CLAY_MINE,
		"iron_mine": IRON_MINE,
		"gold_mine": GOLD_MINE,
		"crystal_mine": CRYSTAL_MINE,
		"sawmill": SAWMILL,
		"nether_rune_enchantery": NETHER_RUNE_ENCHANTERY,
		"wheat_field": WHEAT_FIELD,
	}
	for id in configs.keys():
		var config: BuildingConfig = configs[id]
		if config == null:
			push_error("[test_established_buildings_and_wall_ui] missing config for %s" % id)
			quit(1)
			return
		if int(config.max_units) != 1000:
			push_error("[test_established_buildings_and_wall_ui] expected %s max_units=1000, got %s" % [id, str(config.max_units)])
			quit(1)
			return

	var wall_ui := WALL_HEALTH_UI_SCENE.instantiate() as WallHealthUI
	if wall_ui == null:
		push_error("[test_established_buildings_and_wall_ui] failed to instantiate WallHealthUI")
		quit(1)
		return

	get_root().add_child(wall_ui)
	await process_frame

	wall_ui.call("_update_display", 73, 100)
	await process_frame

	var value_label := wall_ui.get_node_or_null("ValueLabel") as Label
	if value_label == null:
		push_error("[test_established_buildings_and_wall_ui] ValueLabel missing")
		quit(1)
		return

	if value_label.text != "73":
		push_error("[test_established_buildings_and_wall_ui] expected current HP label 73, got %s" % value_label.text)
		quit(1)
		return

	print("[test_established_buildings_and_wall_ui] PASS")
	quit(0)
