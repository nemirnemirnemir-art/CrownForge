extends SceneTree

const PENDING_REWARDS_PATH := "res://scripts/game_scene/GameScenePendingRewards.gd"
const KING_SPELL_CASTING_PATH := "res://scripts/ui/hud/KingSpellHudCasting.gd"
const ARTIFACT_CATALOG_PATH := "res://core/artifacts/artifact_catalog.gd"
const ARTIFACT_EFFECT_EXECUTOR_PATH := "res://core/artifacts/ArtifactEffectExecutor.gd"
const RESOURCE_MENU_PATH := "res://scripts/ui/rewards/RewardMenuResources.gd"

var _failed: bool = false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_reward_box_and_excavation_stone] %s" % message)
	quit(1)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		_fail("Missing file: %s" % path)
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open file: %s" % path)
		return ""
	return file.get_as_text()


func _require_contains(haystack: String, needle: String, reason: String) -> bool:
	if haystack.find(needle) == -1:
		_fail(reason)
		return false
	return true


func _require_not_contains(haystack: String, needle: String, reason: String) -> bool:
	if haystack.find(needle) != -1:
		_fail(reason)
		return false
	return true


func _init() -> void:
	var pending_rewards_text := _read_text(PENDING_REWARDS_PATH)
	if not _require_contains(pending_rewards_text, 'res://assets/ui/rewards/reward_box.png', "Pending rewards button must use runtime reward box asset"):
		return
	if not _require_not_contains(pending_rewards_text, 'takefromthis', "Pending rewards button must not reference takefromthis assets"):
		return
	if not _require_contains(pending_rewards_text, 'PendingRewardButton', "Pending rewards manager must create the reward-box button"):
		return

	var king_spell_text := _read_text(KING_SPELL_CASTING_PATH)
	if not _require_contains(king_spell_text, 'enqueue_resource_choice_reward(100)', "Forced Tax must queue a deferred 100-resource reward"):
		return
	if not _require_contains(king_spell_text, 'enqueue_established_production_reward()', "King established-production reward must be deferred"):
		return
	if not _require_contains(king_spell_text, 'enqueue_artifact_reward()', "King artifact reward must be deferred"):
		return

	var artifact_catalog_text := _read_text(ARTIFACT_CATALOG_PATH)
	if not _require_contains(artifact_catalog_text, '"excavation_stone"', "Artifact catalog must still define excavation_stone"):
		return
	if not _require_contains(artifact_catalog_text, '"implemented":true,"effect_kind":"on_pickup_queue_resource_choice","effect_value":90,"effect_count":3', "Excavation Stone must queue three deferred 90-resource choices"):
		return

	var artifact_effect_text := _read_text(ARTIFACT_EFFECT_EXECUTOR_PATH)
	if not _require_contains(artifact_effect_text, '"type": "resource_choice"', "Artifact reward executor must queue resource-choice payloads"):
		return
	if not _require_contains(artifact_effect_text, '"type": "spell_grant"', "Artifact reward executor must queue deterministic spell grants"):
		return

	var resource_menu_text := _read_text(RESOURCE_MENU_PATH)
	if not _require_not_contains(resource_menu_text, '"oil"', "Generic resource reward menu must exclude oil from random resource choices"):
		return
	if not _require_not_contains(resource_menu_text, '"meat"', "Generic resource reward menu must exclude meat from random resource choices"):
		return

	print("[test_reward_box_and_excavation_stone] PASS")
	quit(0)
