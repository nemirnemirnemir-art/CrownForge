extends SceneTree

const SaveRegistryFlowScript := preload("res://core/save/SaveRegistryFlow.gd")


class FakeSaveTarget:
	extends RefCounted

	func get_save_data() -> Dictionary:
		return {"ok": true}


class FakeAutoload:
	extends Node

	var save_load = null


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = SaveRegistryFlowScript.new()
	if flow == null:
		push_error("[test_savecore_registry_flow] failed to instantiate helper")
		quit(1)
		return

	var modules: Dictionary = {}
	flow.register_module(modules, "heroes", FakeSaveTarget.new())
	if not modules.has("heroes"):
		push_error("[test_savecore_registry_flow] register_module failed")
		quit(1)
		return

	if flow.derive_save_key("HeroCore") != "heroes":
		push_error("[test_savecore_registry_flow] derive_save_key mismatch")
		quit(1)
		return

	var autoload := FakeAutoload.new()
	autoload.save_load = FakeSaveTarget.new()
	flow.try_register_save_target(modules, "PlayerInventory", autoload)
	if not modules.has("inventory"):
		push_error("[test_savecore_registry_flow] save_load fallback registration failed")
		quit(1)
		return

	print("[test_savecore_registry_flow] PASS")
	quit(0)
