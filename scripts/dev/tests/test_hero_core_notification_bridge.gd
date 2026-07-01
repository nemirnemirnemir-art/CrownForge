extends SceneTree

const HeroCoreNotificationBridgeScript := preload("res://core/hero/HeroCoreNotificationBridge.gd")


class HeroCoreHarness:
	extends "res://core/hero_core.gd"

	var save_target: FakeSave = null

	func _get_request_save_callable() -> Callable:
		if save_target:
			return Callable(save_target, "request_save")
		return Callable()


class FakeHeroData:
	extends HeroData

	func _init() -> void:
		heroes = {
			"hero_a": {"hp": 10, "level": 2},
			"hero_b": {"hp": 4, "level": 1}
		}

	func get_hero(hero_id: String) -> Dictionary:
		return heroes.get(hero_id, {}).duplicate(true)

	func has_hero(hero_id: String) -> bool:
		return heroes.has(hero_id)

	func update_hero(hero_id: String, updates: Dictionary) -> void:
		if not heroes.has(hero_id):
			return
		var hero: Dictionary = heroes[hero_id]
		for key in updates.keys():
			hero[key] = updates[key]
		heroes[hero_id] = hero


class FakeHeroHealth:
	extends HeroHealth

	var heal_result: int = 0
	var calls: Array = []

	func _init() -> void:
		pass

	func heal_hero(hero_id: String, amount: int) -> int:
		calls.append([hero_id, amount])
		return heal_result


class FakeEmitter:
	extends RefCounted

	var payloads: Array = []

	func emit_updated(hero_id: String, hero_data: Dictionary) -> void:
		payloads.append([hero_id, hero_data.duplicate(true)])


class FakeSave:
	extends RefCounted

	var request_count: int = 0

	func request_save() -> void:
		request_count += 1


class FakeHeroUpdatedListener:
	extends RefCounted

	var payloads: Array = []

	func on_hero_updated(hero_id: String, hero_data: Dictionary) -> void:
		payloads.append([hero_id, hero_data.duplicate(true)])


class FakeHeroHealedListener:
	extends RefCounted

	var payloads: Array = []

	func on_hero_healed(hero_id: String, amount: int) -> void:
		payloads.append([hero_id, amount])


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var bridge = HeroCoreNotificationBridgeScript.new()
	if bridge == null:
		push_error("[test_hero_core_notification_bridge] failed to instantiate helper")
		quit(1)
		return

	var hero_data := FakeHeroData.new()
	var emitter := FakeEmitter.new()
	var save := FakeSave.new()

	bridge.emit_updated(hero_data, "hero_a", Callable(emitter, "emit_updated"))
	if emitter.payloads.size() != 1:
		push_error("[test_hero_core_notification_bridge] emit_updated should emit exactly once")
		quit(1)
		return
	if emitter.payloads[0][0] != "hero_a" or emitter.payloads[0][1].get("hp", -1) != 10:
		push_error("[test_hero_core_notification_bridge] emit_updated payload mismatch")
		quit(1)
		return
	if save.request_count != 0:
		push_error("[test_hero_core_notification_bridge] emit_updated should not request save")
		quit(1)
		return

	bridge.emit_updated_and_save(hero_data, "hero_b", Callable(emitter, "emit_updated"), Callable(save, "request_save"))
	if emitter.payloads.size() != 2:
		push_error("[test_hero_core_notification_bridge] emit_updated_and_save should emit exactly once")
		quit(1)
		return
	if emitter.payloads[1][0] != "hero_b" or emitter.payloads[1][1].get("hp", -1) != 4:
		push_error("[test_hero_core_notification_bridge] emit_updated_and_save payload mismatch")
		quit(1)
		return
	if save.request_count != 1:
		push_error("[test_hero_core_notification_bridge] emit_updated_and_save should request save once")
		quit(1)
		return

	bridge.emit_updated(null, "hero_a", Callable(emitter, "emit_updated"))
	bridge.emit_updated_and_save(null, "hero_a", Callable(emitter, "emit_updated"), Callable(save, "request_save"))
	if emitter.payloads.size() != 2:
		push_error("[test_hero_core_notification_bridge] null hero_data should not emit updates")
		quit(1)
		return
	if save.request_count != 1:
		push_error("[test_hero_core_notification_bridge] null hero_data should not request save")
		quit(1)
		return

	var hero_core := HeroCoreHarness.new()
	var updated_listener := FakeHeroUpdatedListener.new()
	var healed_listener := FakeHeroHealedListener.new()
	var hero_health := FakeHeroHealth.new()
	hero_core.save_target = save
	hero_core._hero_data = hero_data
	hero_core._hero_health = hero_health
	hero_core._notification_bridge = bridge
	hero_core.hero_updated.connect(Callable(updated_listener, "on_hero_updated"))
	hero_core.hero_healed.connect(Callable(healed_listener, "on_hero_healed"))

	hero_core._emit_updated_hero("hero_a")
	if updated_listener.payloads.size() != 1:
		push_error("[test_hero_core_notification_bridge] _emit_updated_hero wrapper should emit exactly once")
		quit(1)
		return
	if updated_listener.payloads[0][0] != "hero_a" or updated_listener.payloads[0][1].get("level", -1) != 2:
		push_error("[test_hero_core_notification_bridge] _emit_updated_hero wrapper payload mismatch")
		quit(1)
		return
	if save.request_count != 1:
		push_error("[test_hero_core_notification_bridge] _emit_updated_hero wrapper should not request save")
		quit(1)
		return

	hero_core._emit_updated_hero_and_request_save("hero_b")
	if updated_listener.payloads.size() != 2:
		push_error("[test_hero_core_notification_bridge] _emit_updated_hero_and_request_save wrapper should emit exactly once")
		quit(1)
		return
	if updated_listener.payloads[1][0] != "hero_b" or updated_listener.payloads[1][1].get("level", -1) != 1:
		push_error("[test_hero_core_notification_bridge] _emit_updated_hero_and_request_save wrapper payload mismatch")
		quit(1)
		return
	if save.request_count != 2:
		push_error("[test_hero_core_notification_bridge] _emit_updated_hero_and_request_save wrapper should request save once")
		quit(1)
		return

	hero_core.update_hero("hero_a", {"hp": 12})
	if updated_listener.payloads.size() != 3:
		push_error("[test_hero_core_notification_bridge] update_hero should route through facade wrapper")
		quit(1)
		return
	if updated_listener.payloads[2][1].get("hp", -1) != 12:
		push_error("[test_hero_core_notification_bridge] update_hero emitted stale hero data")
		quit(1)
		return
	if save.request_count != 2:
		push_error("[test_hero_core_notification_bridge] update_hero should not request save")
		quit(1)
		return

	hero_health.heal_result = 3
	hero_core.heal_hero("hero_b", 3)
	if updated_listener.payloads.size() != 4:
		push_error("[test_hero_core_notification_bridge] heal_hero should route through save wrapper")
		quit(1)
		return
	if save.request_count != 3:
		push_error("[test_hero_core_notification_bridge] heal_hero should request save through facade wrapper")
		quit(1)
		return
	if healed_listener.payloads.size() != 1 or healed_listener.payloads[0] != ["hero_b", 3]:
		push_error("[test_hero_core_notification_bridge] heal_hero should preserve healed signal side effect")
		quit(1)
		return

	var fallback_core := HeroCoreHarness.new()
	var fallback_updated_listener := FakeHeroUpdatedListener.new()
	var fallback_healed_listener := FakeHeroHealedListener.new()
	var fallback_health := FakeHeroHealth.new()
	var fallback_save := FakeSave.new()
	fallback_core.save_target = fallback_save
	fallback_core._hero_data = hero_data
	fallback_core._hero_health = fallback_health
	fallback_core._notification_bridge = null
	fallback_core.hero_updated.connect(Callable(fallback_updated_listener, "on_hero_updated"))
	fallback_core.hero_healed.connect(Callable(fallback_healed_listener, "on_hero_healed"))

	fallback_core._emit_updated_hero("hero_a")
	if fallback_updated_listener.payloads.size() != 1:
		push_error("[test_hero_core_notification_bridge] facade fallback should emit without bridge")
		quit(1)
		return
	if fallback_save.request_count != 0:
		push_error("[test_hero_core_notification_bridge] facade fallback emit-only path should not save")
		quit(1)
		return

	fallback_core._emit_updated_hero_and_request_save("hero_b")
	if fallback_updated_listener.payloads.size() != 2:
		push_error("[test_hero_core_notification_bridge] facade fallback save path should emit without bridge")
		quit(1)
		return
	if fallback_save.request_count != 1:
		push_error("[test_hero_core_notification_bridge] facade fallback save path should request save")
		quit(1)
		return

	fallback_health.heal_result = 2
	fallback_core.heal_hero("hero_a", 2)
	if fallback_updated_listener.payloads.size() != 3:
		push_error("[test_hero_core_notification_bridge] public API should still use fallback without bridge")
		quit(1)
		return
	if fallback_save.request_count != 2:
		push_error("[test_hero_core_notification_bridge] public API fallback should still request save")
		quit(1)
		return
	if fallback_healed_listener.payloads.size() != 1 or fallback_healed_listener.payloads[0] != ["hero_a", 2]:
		push_error("[test_hero_core_notification_bridge] public API fallback should preserve healed side effect")
		quit(1)
		return

	print("[test_hero_core_notification_bridge] PASS")
	quit(0)
