extends SceneTree

const START_FRAMES_PATH: String = "res://assets/vfx/spells_visuals/Armageddon/ArmageddonStartFrames.tres"

var _failed: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_assert_true(ResourceLoader.exists(START_FRAMES_PATH), "Armageddon start VFX must use a dedicated authored SpriteFrames resource")
	if _failed:
		return

	var frames := load(START_FRAMES_PATH) as SpriteFrames
	_assert_true(frames != null, "Armageddon start SpriteFrames resource must load")
	if _failed:
		return

	_assert_true(frames.has_animation(&"start"), "Armageddon start SpriteFrames must expose 'start' animation")
	if _failed:
		return

	_assert_true(frames.get_frame_count(&"start") > 0, "Armageddon start SpriteFrames must contain frames")
	if _failed:
		return

	print("[test_armageddon_start_vfx_resource] PASS")
	quit(0)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_fail(message)


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_armageddon_start_vfx_resource] %s" % message)
	quit(1)
