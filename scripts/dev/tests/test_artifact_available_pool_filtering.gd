extends SceneTree

const RewardMenuArtifactsScript := preload("res://scripts/ui/rewards/RewardMenuArtifacts.gd")
const TraderOfferGeneratorScript := preload("res://scripts/ui/rewards/modules/TraderOfferGenerator.gd")

var _failed: bool = false


class FakeArtifactCore:
	extends RefCounted

	var _owned: Dictionary = {}

	func has_artifact(artifact_id: String) -> bool:
		return _owned.has(artifact_id)


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_artifact_available_pool_filtering] %s" % message)
	quit(1)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail(message)


func _run_test() -> void:
	var host := Node.new()
	get_root().add_child(host)

	var reward_menu: Control = RewardMenuArtifactsScript.new()
	host.add_child(reward_menu)
	await process_frame

	var trader_offer_generator = TraderOfferGeneratorScript.new()
	var artifact_core := FakeArtifactCore.new()

	var reward_pool: Array[String] = []
	for raw_id in reward_menu.call("_get_pool_ids"):
		reward_pool.append(String(raw_id))

	var trader_pool: Array[String] = trader_offer_generator.roll_artifact_ids(ArtifactCatalog, artifact_core)

	_assert_true(reward_pool.has("ancestral_power"), "implemented artifacts must remain available in reward pool")
	if _failed:
		return
	_assert_true(trader_pool.has("ancestral_power"), "implemented artifacts must remain available in trader pool")
	if _failed:
		return

	_assert_true(reward_pool.has("iron_helmet"), "reward pool must include iron_helmet once it is fully implemented")
	if _failed:
		return
	_assert_true(trader_pool.has("iron_helmet"), "trader pool must include iron_helmet once it is fully implemented")
	if _failed:
		return
	_assert_true(reward_pool.has("medal"), "reward pool must include medal once it is fully implemented")
	if _failed:
		return
	_assert_true(trader_pool.has("medal"), "trader pool must include medal once it is fully implemented")
	if _failed:
		return

	_assert_true(reward_pool.has("chi_fan"), "reward pool must include chi_fan once it is fully implemented")
	if _failed:
		return
	_assert_true(trader_pool.has("chi_fan"), "trader pool must include chi_fan once it is fully implemented")
	if _failed:
		return

	_assert_false(reward_pool.has("boiling_rage"), "reward pool must not expose infernal artifact slated for removal")
	if _failed:
		return
	_assert_false(trader_pool.has("boiling_rage"), "trader pool must not expose infernal artifact slated for removal")
	if _failed:
		return

	_assert_false(reward_pool.has("demon_wings"), "reward pool must not expose infernal damage artifact slated for removal")
	if _failed:
		return
	_assert_false(trader_pool.has("demon_wings"), "trader pool must not expose infernal damage artifact slated for removal")
	if _failed:
		return

	_assert_false(reward_pool.has("extra_103"), "reward pool must not expose placeholder artifacts")
	if _failed:
		return
	_assert_false(trader_pool.has("extra_109"), "trader pool must not expose placeholder artifacts")
	if _failed:
		return

	print("[test_artifact_available_pool_filtering] PASS")
	quit(0)
