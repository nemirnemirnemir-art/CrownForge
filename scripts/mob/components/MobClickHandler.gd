extends Node
class_name MobClickHandler

var _mob: Node2D
var _health: MobHealth
var _click_area: Area2D

func setup(mob: Node2D, click_area: Area2D, health: MobHealth) -> void:
	_mob = mob
	_health = health
	_click_area = click_area
	
	if _click_area:
		_click_area.input_pickable = true
		if not _click_area.input_event.is_connected(_on_click_area_input_event):
			_click_area.input_event.connect(_on_click_area_input_event)
		if _click_area.has_signal("mouse_entered") and not _click_area.mouse_entered.is_connected(_on_click_area_mouse_entered):
			_click_area.mouse_entered.connect(_on_click_area_mouse_entered)
		if _click_area.has_signal("mouse_exited") and not _click_area.mouse_exited.is_connected(_on_click_area_mouse_exited):
			_click_area.mouse_exited.connect(_on_click_area_mouse_exited)

func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _health.is_dead: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _mob and "is_invincible" in _mob and bool(_mob.is_invincible):
			return
		var dmg: float = 1.0
		var economy_core := _get_singleton("EconomyCore")
		if economy_core and economy_core.has_method("get_click_damage"):
			dmg = float(economy_core.get_click_damage())
		var is_crit := false
		var skill_core := _get_singleton("SkillCore")
		if skill_core and skill_core.has_method("roll_crit"):
			is_crit = bool(skill_core.roll_crit())
			if is_crit and skill_core.has_method("get_crit_damage_multiplier"):
				dmg *= float(skill_core.get_crit_damage_multiplier())
		_health.take_damage(dmg, is_crit)
		if _mob and not _health.is_dead and _mob.has_method("request_hit_reaction"):
			_mob.request_hit_reaction()

func _on_click_area_mouse_entered() -> void:
	if _health.is_dead:
		return
	var ui: Node = null
	var tree := get_tree()
	if tree and tree.current_scene:
		ui = tree.current_scene.get_node_or_null("UILayer/MainUI")
	if ui == null:
		ui = tree.get_first_node_in_group("main_ui")
	if ui and ui.has_method("show_enemy_hp_tooltip"):
		ui.show_enemy_hp_tooltip(_mob)

func _on_click_area_mouse_exited() -> void:
	var ui: Node = null
	var tree := get_tree()
	if tree and tree.current_scene:
		ui = tree.current_scene.get_node_or_null("UILayer/MainUI")
	if ui == null:
		ui = tree.get_first_node_in_group("main_ui")
	if ui and ui.has_method("hide_enemy_hp_tooltip"):
		ui.hide_enemy_hp_tooltip(_mob)

func _get_singleton(name: String) -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(name)


