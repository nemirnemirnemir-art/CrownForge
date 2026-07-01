extends RefCounted
class_name UnitDamageFlash

const FLASH_COLOR := Color(1.0, 0.3, 0.1, 1.0)
const FLASH_DURATION_SEC := 0.12
const TWEEN_META_KEY := "_unit_damage_flash_tween"

static func is_enabled() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	var game_settings := tree.root.get_node_or_null("GameSettings")
	if game_settings == null or not game_settings.has_method("is_damage_flash_enabled"):
		return false
	return bool(game_settings.is_damage_flash_enabled())

static func flash_from_node(root: Node) -> void:
	if root == null or not is_instance_valid(root):
		return
	var target := root.get_node_or_null("AnimationSprite2D") as CanvasItem
	if target == null:
		target = root.get_node_or_null("AnimWalk") as CanvasItem
	if target == null:
		target = root.get_node_or_null("AnimatedSprite2D") as CanvasItem
	if target == null:
		target = root.get_node_or_null("Sprite2D") as CanvasItem
	if target == null and root is CanvasItem:
		target = root as CanvasItem
	flash_canvas_item(target)

static func flash_canvas_item(target: CanvasItem) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not is_enabled():
		return
	var base_modulate := target.modulate
	if target.has_meta(TWEEN_META_KEY):
		var prev_tween: Variant = target.get_meta(TWEEN_META_KEY)
		if prev_tween is Tween and is_instance_valid(prev_tween as Tween):
			(prev_tween as Tween).kill()
	target.modulate = Color(FLASH_COLOR.r, FLASH_COLOR.g, FLASH_COLOR.b, base_modulate.a)
	var tween := target.create_tween()
	target.set_meta(TWEEN_META_KEY, tween)
	tween.tween_property(target, "modulate", base_modulate, FLASH_DURATION_SEC)
