extends RefCounted
class_name GameSceneViewport

## Viewport / content-scale management for GameScene.
## Extracted from GameScene._apply_content_scale_settings() and set_runtime_content_scale_override().

## Apply content-scale settings to a window.
## Pass runtime_content_scale_override from GameScene so we avoid a circular class dependency.
static func apply_settings(window: Window, force: bool, factor: float, scale_override: float) -> void:
	if window == null:
		return
	if scale_override > 0.0:
		window.content_scale_factor = clampf(scale_override, 0.5, 1.5)
		return
	if not force:
		return
	window.content_scale_factor = clampf(factor, 0.5, 1.5)


## Clamp and apply a new runtime override.  Returns the clamped value so the
## caller can store it back to its static field without a circular reference.
static func set_runtime_override(window: Window, factor: float) -> float:
	var clamped := clampf(factor, 0.5, 1.5)
	if window:
		window.content_scale_factor = clamped
	return clamped
