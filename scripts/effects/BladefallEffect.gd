extends SpellEffect

## Bladefall spell - drops 15 blades in vertical line (300px height), staggered

const FallingBladeScene = preload("res://scenes/spells/effects/FallingBlade.tscn")

const BLADE_COUNT: int = 15
const DEFAULT_DAMAGE: float = 60.0
const STRIKE_HEIGHT_PX: float = 300.0
const FALL_TIME: float = 0.36
const BLADE_STAGGER: float = 0.1

func execute_effect() -> void:
	var dmg := DEFAULT_DAMAGE
	if config != null and config.damage > 0.0:
		dmg = get_scaled_damage(config.damage)
	else:
		dmg = get_scaled_damage(DEFAULT_DAMAGE)

	var half_h := STRIKE_HEIGHT_PX * 0.5
	var step := 0.0
	if BLADE_COUNT > 1:
		step = STRIKE_HEIGHT_PX / float(BLADE_COUNT - 1)

	var root: Node = get_tree().current_scene
	if get_parent() != null:
		root = get_parent()

	for i in range(BLADE_COUNT):
		var blade: Node2D = FallingBladeScene.instantiate()
		root.add_child(blade)

		var y := -half_h + step * float(i)
		blade.global_position = global_position + Vector2(0.0, y)

		if blade.has_method("setup"):
			blade.setup(dmg, FALL_TIME)

		if i < BLADE_COUNT - 1:
			await get_tree().create_timer(BLADE_STAGGER).timeout

	var total_time := FALL_TIME + float(BLADE_COUNT - 1) * BLADE_STAGGER + 1.0
	await get_tree().create_timer(total_time).timeout
	queue_free()
