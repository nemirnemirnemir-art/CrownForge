## Hover tooltip for Ten Kings board slot details.
## Shows card name, level, units, bonuses, and special info on hover.
extends PanelContainer


# ---------------------------------------------------------------------------
# Child nodes
# ---------------------------------------------------------------------------

var _title_label: Label = null
var _body_label: Label = null


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Shows the tooltip with the provided slot details near the screen position.
func show_for_slot(details: Dictionary, screen_pos: Vector2) -> void:
	_ensure_nodes()
	_update_content(details)
	_position_near(screen_pos)
	visible = true


## Hides the tooltip.
func hide_tooltip() -> void:
	visible = false


# ---------------------------------------------------------------------------
# Node resolution
# ---------------------------------------------------------------------------

func _ensure_nodes() -> void:
	if _title_label == null:
		_title_label = get_node_or_null("Margin/VBox/TitleLabel")
	if _body_label == null:
		_body_label = get_node_or_null("Margin/VBox/BodyLabel")


# ---------------------------------------------------------------------------
# Content building
# ---------------------------------------------------------------------------

func _update_content(details: Dictionary) -> void:
	var display_name: String = String(details.get("display_name", "Unknown"))
	var level: int = int(details.get("level", 1))
	
	if _title_label != null:
		_title_label.text = display_name
	
	var lines: Array[String] = []
	lines.append("Level %d" % level)
	
	# Units (for troops)
	if details.has("units"):
		var units: int = int(details.get("units", 0))
		if units > 0:
			lines.append("Units: %d" % units)
	
	# Smith bonus
	if details.has("smith_bonus"):
		var smith: float = float(details.get("smith_bonus", 0.0))
		if smith > 0.0:
			lines.append("Smith bonus: +%d%%" % int(round(smith * 100.0)))
	
	# Steel coat stacks
	if details.has("steel_coat_stacks"):
		var stacks: int = int(details.get("steel_coat_stacks", 0))
		if stacks > 0:
			lines.append("Steel Coat: %d" % stacks)
	
	# Castle HP
	if details.get("is_castle", false) and details.has("castle_hp"):
		var hp: int = int(details.get("castle_hp", 0))
		lines.append("Castle HP: %d" % hp)
	
	if _body_label != null:
		_body_label.text = "\n".join(lines)


# ---------------------------------------------------------------------------
# Positioning
# ---------------------------------------------------------------------------

func _position_near(screen_pos: Vector2) -> void:
	var viewport_size := get_viewport_rect().size
	var tooltip_size := size
	
	# Default: position below and to the right of cursor
	var target_pos := screen_pos + Vector2(16.0, 16.0)
	
	# Clamp to viewport bounds
	target_pos = _clamp_to_viewport(target_pos, tooltip_size, viewport_size)
	
	global_position = target_pos


func _clamp_to_viewport(pos: Vector2, tooltip_size: Vector2, viewport_size: Vector2) -> Vector2:
	var margin := 8.0
	
	# Clamp right edge
	if pos.x + tooltip_size.x + margin > viewport_size.x:
		pos.x = viewport_size.x - tooltip_size.x - margin
	
	# Clamp bottom edge
	if pos.y + tooltip_size.y + margin > viewport_size.y:
		pos.y = viewport_size.y - tooltip_size.y - margin
	
	# Clamp left edge
	if pos.x < margin:
		pos.x = margin
	
	# Clamp top edge
	if pos.y < margin:
		pos.y = margin
	
	return pos
