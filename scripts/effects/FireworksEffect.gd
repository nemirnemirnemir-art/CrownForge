extends SpellEffect

## Fireworks spell - plays looping fireworks visual for 20 seconds

@onready var fireworks_anim: AnimatedSprite2D = $FireworksAnim

const DEFAULT_DURATION: float = 20.0
const FX_ANIM_NAME: StringName = &"default"
const FX_FPS: float = 6.0
const FX_FOLDER: String = "res://assets/vfx/spells_visuals/Fireworks"

static var _cached_frames: SpriteFrames = null

func execute_effect() -> void:
	if fireworks_anim == null:
		fireworks_anim = AnimatedSprite2D.new()
		fireworks_anim.name = "FireworksAnim"
		add_child(fireworks_anim)

	fireworks_anim.sprite_frames = _get_or_create_frames()
	if fireworks_anim.sprite_frames == null:
		push_error("[FireworksEffect] Failed to build fireworks frames")
		queue_free()
		return

	if fireworks_anim.sprite_frames.has_animation(FX_ANIM_NAME):
		fireworks_anim.play(FX_ANIM_NAME)

	var duration := DEFAULT_DURATION
	if config != null and config.duration > 0.0:
		duration = config.duration

	await get_tree().create_timer(duration).timeout
	queue_free()

func _get_or_create_frames() -> SpriteFrames:
	if _cached_frames != null:
		return _cached_frames

	var frames := SpriteFrames.new()
	if not frames.has_animation(FX_ANIM_NAME):
		frames.add_animation(FX_ANIM_NAME)
	frames.set_animation_speed(FX_ANIM_NAME, FX_FPS)
	frames.set_animation_loop(FX_ANIM_NAME, true)

	for idx in range(1, 7):
		var path := "%s/%d.png" % [FX_FOLDER, idx]
		var tex := load(path) as Texture2D
		if tex != null:
			frames.add_frame(FX_ANIM_NAME, tex)

	_cached_frames = frames
	return _cached_frames
