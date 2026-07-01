extends RefCounted

# Config (mirrors @export values on VzorZone)
var cell_size: Vector2 = Vector2(80, 80)
var line_color: Color = Color(0.95, 0.95, 0.95, 1.0)
var invalid_line_color: Color = Color(1.0, 0.35, 0.35, 1.0)
var line_width: float = 2.0

var _gaze_tiles: Array[AnimatedSprite2D] = []
# Stored for future _draw() delegate support
var _zone: Node2D = null

func setup(zone: Node2D, tiles: Array) -> void:
	_zone = zone
	_gaze_tiles.clear()
	for t in tiles:
		if t is AnimatedSprite2D:
			_gaze_tiles.append(t as AnimatedSprite2D)

func update_gaze_tiles(offsets: Array, preview_valid: bool) -> void:
	if _gaze_tiles.is_empty():
		return
	var draw_color := line_color if preview_valid else invalid_line_color
	for i in range(_gaze_tiles.size()):
		var tile := _gaze_tiles[i]
		if tile == null or not is_instance_valid(tile):
			continue
		if i < offsets.size():
			tile.position = Vector2(offsets[i]) * cell_size + (cell_size * 0.5)
			tile.modulate = draw_color
			tile.visible = true
			if tile.sprite_frames != null:
				tile.play()
		else:
			tile.visible = false
