# Quick test to verify module imports work
extends Node

func _ready() -> void:
	var debug_module = load("res://scripts/ui/debug/modules/DebugBuildingUpgradesModule.gd")
	if debug_module:
		print("[Test] ✓ DebugBuildingUpgradesModule loads successfully")
	else:
		print("[Test] ✗ DebugBuildingUpgradesModule FAILED to load")
	
	var building_pres = load("res://scripts/ui/town/buildings/BuildingPresentationData.gd")
	if building_pres:
		print("[Test] ✓ BuildingPresentationData loads successfully")
	else:
		print("[Test] ✗ BuildingPresentationData FAILED to load")
	
	print("[Test] Module loading check complete")
	get_tree().quit()
