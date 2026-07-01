class_name DamagePopupSpawner

## Translates a "damage event" into a popup instance + positioning.
## Plain class — initialized with .new() by DamagePopupPool.

var _pool  # DamagePopupPool


func init(pool) -> void:
	_pool = pool


## Acquire a popup from the pool, configure it, and start its lifetime.
func spawn(pos: Vector2, amount: int, is_crit: bool, tint: Color) -> void:
	var popup: Node2D = _pool._get_or_create_popup()
	if popup == null:
		return
	_setup_popup(popup, pos, amount, is_crit, tint)
	_activate_popup(popup)


func _setup_popup(popup: Node2D, pos: Vector2, amount: int, is_crit: bool, tint: Color) -> void:
	popup.global_position = pos
	popup.visible = true
	popup.set_process(true)

	for child in popup.get_children():
		child.queue_free()

	if popup.has_method("show_amount"):
		popup.call("show_amount", amount, is_crit, tint)


func _activate_popup(popup: Node2D) -> void:
	if not is_instance_valid(popup):
		return
	_pool._active_popups.append(popup)

	var duration: float = 1.0
	if popup.has_method("get_popup_duration"):
		duration = popup.call("get_popup_duration")

	await _pool.get_tree().create_timer(duration + 0.1).timeout
	if is_instance_valid(popup):
		_pool._return_to_pool(popup)
