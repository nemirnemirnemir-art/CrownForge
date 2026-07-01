extends RefCounted
class_name MapSlotUI

## UI management helper for MapSlot
## Handles progress bars, unit labels, and durability display

var _progress_bar: TextureProgressBar = null
var _radial_progress: Sprite2D = null
var _unit_count_label: Label = null
var _durability_label: Label = null

static var _radial_textures: Array[Texture2D] = []

func initialize(progress_bar: TextureProgressBar, radial_progress: Sprite2D, 
				unit_label: Label, durability_label: Label) -> void:
	_progress_bar = progress_bar
	_radial_progress = radial_progress
	_unit_count_label = unit_label
	_durability_label = durability_label

func update_progress(ratio: float, cycle_time: float) -> void:
	## Updates progress bar with given ratio (1.0 = full, 0.0 = empty)
	if _progress_bar:
		_progress_bar.visible = ratio > 0.0
		_progress_bar.max_value = cycle_time
		_progress_bar.value = max(0, cycle_time * ratio)
	
	_set_radial_progress(ratio)

func hide_progress() -> void:
	if _progress_bar:
		_progress_bar.visible = false
	if _radial_progress:
		_radial_progress.visible = false

func update_unit_count(current: int, maximum: int) -> void:
	if not _unit_count_label:
		return
	_unit_count_label.text = "%d/%d" % [current, maximum]
	_unit_count_label.visible = true

func hide_unit_count() -> void:
	if _unit_count_label:
		_unit_count_label.visible = false

func update_durability(remaining: int) -> void:
	if not _durability_label:
		return
	if remaining > 0:
		_durability_label.text = str(remaining)
		_durability_label.visible = true
	else:
		_durability_label.visible = false

func hide_durability() -> void:
	if _durability_label:
		_durability_label.visible = false

func _set_radial_progress(ratio: float) -> void:
	if not _radial_progress:
		return
	_ensure_radial_textures()
	if _radial_textures.is_empty():
		return
	var r := clampf(ratio, 0.0, 1.0)
	var idx := int(round((1.0 - r) * float(_radial_textures.size() - 1)))
	idx = clampi(idx, 0, _radial_textures.size() - 1)
	_radial_progress.texture = _radial_textures[idx]
	_radial_progress.visible = true
	if _progress_bar:
		_progress_bar.visible = false

func _ensure_radial_textures() -> void:
	if not _radial_textures.is_empty():
		return
	for i in range(1, 21):
		var path := "res://assets/ui/radialProgressBar/%d.png" % i
		var tex := load(path)
		if tex is Texture2D:
			_radial_textures.append(tex)
