extends Node2D

## Popup showing damage numbers using sprite-based digits (like Buss project)
## Each digit is a separate Sprite2D for better visual control

@export var debug_logs: bool = false
@export var digit_textures: Array[Texture2D] = []
@export var spacing_px: float = 8.0
@export var scale_digits: float = 1.0
@export var start_offset: Vector2 = Vector2(0, -24)

@export_group("Animation")
@export var rise_px: float = 40.0
@export var duration_sec: float = 1.0
@export var fade_from: float = 1.0
@export var fade_to: float = 0.0

@export_group("Scale Animation")
@export var start_scale: float = 0.6
@export var peak_scale: float = 1.2
@export var end_scale: float = 0.4
@export var scale_up_duration: float = 0.15
@export var scale_down_duration: float = 0.85

var _auto_free: bool = true
var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	# Get base scale from node scale (allows scaling in editor)
	_base_scale = Vector2(absf(scale.x), absf(scale.y))
	if _base_scale.x < 0.0001:
		_base_scale.x = 0.0001
	if _base_scale.y < 0.0001:
		_base_scale.y = 0.0001
	scale = Vector2.ONE
	
	if debug_logs:
		print("[DamagePopup] _ready -> digits=%d base_scale=%s" % [digit_textures.size(), str(_base_scale)])


func set_auto_free(value: bool) -> void:
	_auto_free = value


## Show damage amount using sprite digits
## amount: damage value to display
## is_crit: optional flag for critical hit (can use different color/effect)
func show_amount(amount: int, is_crit: bool = false, tint: Color = Color.WHITE) -> void:
	# Convert number to array of digits
	var n: int = abs(amount)
	var digits: Array[int] = []
	if n == 0:
		digits.append(0)
	else:
		while n > 0:
			digits.push_front(n % 10)
			@warning_ignore("integer_division")
			n = n / 10
	
	# Calculate scales
	var base_scale_vec: Vector2 = Vector2(scale_digits * _base_scale.x, scale_digits * _base_scale.y)
	var digit_scale_x: float = max(base_scale_vec.x * max(peak_scale, 1.0), 0.0001)
	var spacing_scaled: float = spacing_px * digit_scale_x
	
	# Calculate total width for centering
	var digit_widths: Array[float] = []
	var total_w: float = 0.0
	for digit in digits:
		var tex: Texture2D = null
		if digit >= 0 and digit < digit_textures.size():
			tex = digit_textures[digit]
		var tex_width: float = 0.0
		if tex != null:
			tex_width = tex.get_width() * digit_scale_x
		var width: float = max(tex_width, digit_scale_x * 0.5)
		digit_widths.append(width)
		total_w += width
	
	if digits.size() > 1:
		total_w += spacing_scaled * float(digits.size() - 1)
	
	# Create holder node for all digit sprites
	var holder := Node2D.new()
	add_child(holder)
	var offset := Vector2(start_offset.x * _base_scale.x, start_offset.y * _base_scale.y)
	holder.position = offset
	
	# Create sprite for each digit
	var current_x := -total_w * 0.5
	for i in range(digits.size()):
		var digit: int = digits[i]
		var tex: Texture2D = null
		if digit >= 0 and digit < digit_textures.size():
			tex = digit_textures[digit]
		
		var spr := Sprite2D.new()
		holder.add_child(spr)
		spr.texture = tex
		spr.position = Vector2(current_x + digit_widths[i] * 0.5, 0.0)
		spr.scale = base_scale_vec * start_scale
		
		# Set color for crit hits (red/orange)
		if is_crit:
			spr.modulate = Color(1.0, 0.3, 0.1, fade_from)
		else:
			spr.modulate = Color(tint.r, tint.g, tint.b, fade_from)
		
		current_x += digit_widths[i]
		if i < digits.size() - 1:
			current_x += spacing_scaled
		
		# Scale animation: pop in then shrink
		var tw_scale := create_tween()
		tw_scale.tween_property(spr, "scale", base_scale_vec * peak_scale, scale_up_duration)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_scale.tween_property(spr, "scale", base_scale_vec * end_scale, scale_down_duration)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Move holder upward
	var tw_move := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var rise_target := offset + Vector2(0.0, -rise_px * _base_scale.y)
	tw_move.tween_property(holder, "position", rise_target, duration_sec)
	
	# Fade out each digit sprite
	for child in holder.get_children():
		var sprite := child as Sprite2D
		if sprite != null:
			var tw_fade := create_tween()
			tw_fade.tween_property(sprite, "modulate:a", fade_to, duration_sec)
	
	# Auto cleanup
	if _auto_free:
		var tw_cleanup := create_tween()
		tw_cleanup.tween_interval(duration_sec)
		tw_cleanup.tween_callback(Callable(self, "queue_free"))
	
	if debug_logs:
		print("[DamagePopup] show_amount(%d) -> %d digits" % [amount, digits.size()])


func get_popup_duration() -> float:
	return duration_sec
