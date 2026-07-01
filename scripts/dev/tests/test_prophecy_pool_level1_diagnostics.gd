extends SceneTree

const ProphecyPatternPoolScript := preload("res://scripts/resources/ProphecyPatternPool.gd")
const ProphecyOptionGeneratorScript := preload("res://scripts/ui/prophecy/modules/ProphecyOptionGenerator.gd")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var pool := ProphecyPatternPoolScript.new() as ProphecyPatternPool
	get_root().add_child(pool)
	await process_frame

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var gen := ProphecyOptionGeneratorScript.new()
	gen.setup(rng, 1, pool)
	var options: Array = gen.generate_wave_options()

	var by_sig: Dictionary = {}
	for option in options:
		if not (option is Array) or option.is_empty():
			continue
		var p: ProphecyPattern = option[0]
		if p == null:
			continue
		var sig := "%s:%d:%s:%d|tier=%d|power=%.1f|r1=%d" % [
			String(p.mob_1_id),
			int(p.mob_1_count),
			String(p.mob_2_id),
			int(p.mob_2_count),
			int(p.difficulty_tier),
			float(p.power_rating),
			int(p.reward_1_type),
		]
		by_sig[sig] = true

	print("[test_prophecy_pool_level1_diagnostics] option_count=", options.size())
	for key in by_sig.keys():
		print("[test_prophecy_pool_level1_diagnostics] ", key)
	quit(0)
