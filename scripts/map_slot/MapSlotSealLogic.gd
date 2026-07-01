extends RefCounted
class_name MapSlotSealLogic

var _seal_sprite: Sprite2D = null
var _current_seal_id: String = ""
var _production: RefCounted = null

func _seal_registry() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("SealRegistry")

func initialize(parent: Node2D, production: RefCounted) -> Sprite2D:
	_production = production
	_seal_sprite = Sprite2D.new()
	_seal_sprite.name = "SealSprite"
	_seal_sprite.z_index = 0
	parent.add_child(_seal_sprite)
	parent.move_child(_seal_sprite, 0)
	return _seal_sprite

func set_seal(seal_id: String) -> void:
	_current_seal_id = seal_id
	_update_seal_visual()
	_update_seal_modifier()

func get_seal_id() -> String:
	return _current_seal_id

func _update_seal_visual() -> void:
	if not _seal_sprite:
		return
	
	if _current_seal_id == "":
		_seal_sprite.texture = null
		_seal_sprite.visible = false
		_seal_sprite.rotation = 0.0
		return
	
	var seal_registry := _seal_registry()
	var config = seal_registry.get_seal(_current_seal_id) if seal_registry else null
	if config:
		if config.icon:
			_seal_sprite.texture = config.icon
			_seal_sprite.visible = true
			_seal_sprite.rotation = 0.0
			var tint := Color.WHITE
			if config.icon is GradientTexture2D:
				tint = config.color
			_seal_sprite.modulate = tint
			_seal_sprite.scale = Vector2(0.75, 0.75)
		else:
			_seal_sprite.texture = null
			_seal_sprite.visible = false
			_seal_sprite.rotation = 0.0

func _update_seal_modifier() -> void:
	if _production == null:
		return
	var mod := 0.0
	if _current_seal_id != "":
		var seal_registry := _seal_registry()
		var config = seal_registry.get_seal(_current_seal_id) if seal_registry else null
		if config:
			mod = config.production_modifier
	if _production.has_method("set_seal_modifier"):
		_production.call("set_seal_modifier", mod)
