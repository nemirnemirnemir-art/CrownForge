extends SceneTree

const HeroRecruitmentFlowScript := preload("res://core/hero/HeroRecruitmentFlow.gd")


class FakeService:
	extends RefCounted

	var recruit_result: Dictionary = {}
	var hire_copy_result: Dictionary = {}

	func recruit(_type: String) -> Dictionary:
		return recruit_result.duplicate(true)

	func hire_copy(_base_id: String) -> Dictionary:
		return hire_copy_result.duplicate(true)


class FakeHeroData:
	extends RefCounted

	var heroes: Dictionary = {
		"base": {"id": "base", "icon_id": "base"},
		"h1": {"id": "h1", "icon_id": "base"}
	}

	func has_hero(hero_id: String) -> bool:
		return heroes.has(hero_id)

	func get_hero(hero_id: String) -> Dictionary:
		return heroes.get(hero_id, {}).duplicate(true)


class FakeEmitter:
	extends RefCounted

	var created: Array = []
	var recruited: Array = []
	var saves: int = 0

	func emit_created(hero_id: String, hero: Dictionary) -> void:
		created.append([hero_id, hero.duplicate(true)])

	func emit_recruited(hero_id: String) -> void:
		recruited.append(hero_id)

	func request_save() -> void:
		saves += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = HeroRecruitmentFlowScript.new()
	if flow == null:
		push_error("[test_herocore_recruitment_flow] failed to instantiate helper")
		quit(1)
		return

	var service := FakeService.new()
	var hero_data := FakeHeroData.new()
	var emitter := FakeEmitter.new()
	service.hire_copy_result = {"success": true, "hero_id": "h1"}

	var copy_id: String = flow.hire_hero_copy(
		hero_data,
		service,
		"base",
		Callable(emitter, "emit_created"),
		Callable(emitter, "emit_recruited"),
		Callable(emitter, "request_save")
	)
	if copy_id != "h1":
		push_error("[test_herocore_recruitment_flow] hire copy should return new id")
		quit(1)
		return
	if emitter.created.size() != 1 or emitter.recruited != ["h1"] or emitter.saves != 1:
		push_error("[test_herocore_recruitment_flow] hire copy side effects mismatch")
		quit(1)
		return

	service.recruit_result = {"success": true, "hero_id": "h1"}
	var ok: bool = flow.try_recruit_hero(
		hero_data,
		service,
		"base",
		Callable(emitter, "emit_created"),
		Callable(emitter, "emit_recruited"),
		Callable(emitter, "request_save")
	)
	if not ok:
		push_error("[test_herocore_recruitment_flow] recruit should succeed")
		quit(1)
		return

	print("[test_herocore_recruitment_flow] PASS")
	quit(0)
