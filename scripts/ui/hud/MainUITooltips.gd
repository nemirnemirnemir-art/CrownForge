extends RefCounted
class_name MainUITooltips

var _main_ui: Control
var _popup_layer: Control

var _enemy_hp_tooltip: PanelContainer
var _enemy_hp_label: Label
var _enemy_dmg_label: Label
var _enemy_hp_target: Node
var _enemy_hp_offset: Vector2 = Vector2(16, 16)

var _hero_hp_tooltip: PanelContainer
var _hero_hp_label: Label
var _hero_dmg_label: Label
var _hero_hp_target: Node

func initialize(main_ui: Control, popup_layer: Control) -> void:
	_main_ui = main_ui
	_popup_layer = popup_layer if popup_layer else main_ui
	_ensure_enemy_hp_tooltip()
	_ensure_hero_hp_tooltip()

func set_popup_layer(popup_layer: Control) -> void:
	_popup_layer = popup_layer if popup_layer else _main_ui

func process() -> void:
	if _main_ui == null:
		return

	if _enemy_hp_tooltip and _enemy_hp_tooltip.visible:
		if _enemy_hp_target == null:
			_enemy_hp_tooltip.visible = false
		else:
			_update_enemy_hp_tooltip()
			_enemy_hp_tooltip.position = _main_ui.get_viewport().get_mouse_position() + _enemy_hp_offset

	if _hero_hp_tooltip and _hero_hp_tooltip.visible:
		if _hero_hp_target == null:
			_hero_hp_tooltip.visible = false
		else:
			_update_hero_hp_tooltip()
			_hero_hp_tooltip.position = _main_ui.get_viewport().get_mouse_position() + _enemy_hp_offset

func show_enemy_hp_tooltip(mob: Node) -> void:
	_enemy_hp_target = mob
	if mob and is_instance_valid(mob):
		var cb := Callable(self, "_on_enemy_hp_target_tree_exited").bind(mob)
		if not mob.tree_exited.is_connected(cb):
			mob.tree_exited.connect(cb, Object.CONNECT_ONE_SHOT)

		var health_node: Node = null
		if mob.has_node("Components/Health"):
			health_node = mob.get_node_or_null("Components/Health")
		if health_node and health_node.has_signal("died"):
			var cb_died := Callable(self, "_on_enemy_hp_target_died").bind(mob)
			if not health_node.died.is_connected(cb_died):
				health_node.died.connect(cb_died, Object.CONNECT_ONE_SHOT)

	if _enemy_hp_tooltip:
		_enemy_hp_tooltip.visible = true
		_update_enemy_hp_tooltip()

func hide_enemy_hp_tooltip(mob: Node) -> void:
	if _enemy_hp_target != null and _enemy_hp_target != mob:
		return
	_enemy_hp_target = null
	if _enemy_hp_tooltip:
		_enemy_hp_tooltip.visible = false

func show_hero_hp_tooltip(hero: Node) -> void:
	_hero_hp_target = hero
	if hero and is_instance_valid(hero):
		var cb := Callable(self, "_on_hero_hp_target_tree_exited").bind(hero)
		if not hero.tree_exited.is_connected(cb):
			hero.tree_exited.connect(cb, Object.CONNECT_ONE_SHOT)
	if _hero_hp_tooltip:
		_hero_hp_tooltip.visible = true
		_update_hero_hp_tooltip()

func hide_hero_hp_tooltip(hero: Node) -> void:
	if _hero_hp_target != null and _hero_hp_target != hero:
		return
	_hero_hp_target = null
	if _hero_hp_tooltip:
		_hero_hp_tooltip.visible = false

func _ensure_enemy_hp_tooltip() -> void:
	if _enemy_hp_tooltip != null and is_instance_valid(_enemy_hp_tooltip):
		return

	var panel := PanelContainer.new()
	panel.name = "EnemyHpTooltip"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(90, 42)
	if _popup_layer:
		_popup_layer.add_child(panel)
	else:
		_main_ui.add_child(panel)
	_enemy_hp_tooltip = panel

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var row1 := PanelContainer.new()
	row1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row1.custom_minimum_size = Vector2(90, 20)
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color(0, 0, 0, 0.45)
	row_style.set_corner_radius_all(4)
	row1.add_theme_stylebox_override("panel", row_style)
	vbox.add_child(row1)

	var heart_row := HBoxContainer.new()
	heart_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart_row.add_theme_constant_override("separation", 6)
	row1.add_child(heart_row)

	var heart_icon := TextureRect.new()
	heart_icon.custom_minimum_size = Vector2(20, 20)
	heart_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	heart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var heart_path := "res://assets/ui/status_icons/heart.png"
	if ResourceLoader.exists(heart_path):
		heart_icon.texture = load(heart_path)
	heart_row.add_child(heart_icon)

	var hp_lbl := Label.new()
	hp_lbl.name = "HpLabel"
	hp_lbl.text = ""
	hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart_row.add_child(hp_lbl)
	_enemy_hp_label = hp_lbl

	var row2 := PanelContainer.new()
	row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row2.custom_minimum_size = Vector2(90, 20)
	var row_style2 := StyleBoxFlat.new()
	row_style2.bg_color = Color(0, 0, 0, 0.45)
	row_style2.set_corner_radius_all(4)
	row2.add_theme_stylebox_override("panel", row_style2)
	vbox.add_child(row2)

	var sword_row := HBoxContainer.new()
	sword_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sword_row.add_theme_constant_override("separation", 6)
	row2.add_child(sword_row)

	var sword_icon := TextureRect.new()
	sword_icon.custom_minimum_size = Vector2(20, 20)
	sword_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sword_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var sword_path := "res://assets/ui/status_icons/attack.png"
	if ResourceLoader.exists(sword_path):
		sword_icon.texture = load(sword_path)
	sword_row.add_child(sword_icon)

	var dmg_lbl := Label.new()
	dmg_lbl.name = "DmgLabel"
	dmg_lbl.text = ""
	dmg_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sword_row.add_child(dmg_lbl)
	_enemy_dmg_label = dmg_lbl

func _ensure_hero_hp_tooltip() -> void:
	if _hero_hp_tooltip != null and is_instance_valid(_hero_hp_tooltip):
		return

	var panel := PanelContainer.new()
	panel.name = "HeroHpTooltip"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(90, 42)
	if _popup_layer:
		_popup_layer.add_child(panel)
	else:
		_main_ui.add_child(panel)
	_hero_hp_tooltip = panel

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var row1 := PanelContainer.new()
	row1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row1.custom_minimum_size = Vector2(90, 20)
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color(0, 0, 0, 0.45)
	row_style.set_corner_radius_all(4)
	row1.add_theme_stylebox_override("panel", row_style)
	vbox.add_child(row1)

	var heart_row := HBoxContainer.new()
	heart_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart_row.add_theme_constant_override("separation", 6)
	row1.add_child(heart_row)

	var heart_icon := TextureRect.new()
	heart_icon.custom_minimum_size = Vector2(20, 20)
	heart_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	heart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var heart_path := "res://assets/ui/status_icons/heart.png"
	if ResourceLoader.exists(heart_path):
		heart_icon.texture = load(heart_path)
	heart_row.add_child(heart_icon)

	var hp_lbl := Label.new()
	hp_lbl.name = "HpLabel"
	hp_lbl.text = ""
	hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart_row.add_child(hp_lbl)
	_hero_hp_label = hp_lbl

	var row2 := PanelContainer.new()
	row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row2.custom_minimum_size = Vector2(90, 20)
	var row_style2 := StyleBoxFlat.new()
	row_style2.bg_color = Color(0, 0, 0, 0.45)
	row_style2.set_corner_radius_all(4)
	row2.add_theme_stylebox_override("panel", row_style2)
	vbox.add_child(row2)

	var sword_row := HBoxContainer.new()
	sword_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sword_row.add_theme_constant_override("separation", 6)
	row2.add_child(sword_row)

	var sword_icon := TextureRect.new()
	sword_icon.custom_minimum_size = Vector2(20, 20)
	sword_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sword_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var sword_path := "res://assets/ui/status_icons/attack.png"
	if ResourceLoader.exists(sword_path):
		sword_icon.texture = load(sword_path)
	sword_row.add_child(sword_icon)

	var dmg_lbl := Label.new()
	dmg_lbl.name = "DmgLabel"
	dmg_lbl.text = ""
	dmg_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sword_row.add_child(dmg_lbl)
	_hero_dmg_label = dmg_lbl

func _update_enemy_hp_tooltip() -> void:
	if _enemy_hp_tooltip == null or _enemy_hp_target == null:
		return
	if not is_instance_valid(_enemy_hp_target):
		_enemy_hp_tooltip.visible = false
		_enemy_hp_target = null
		return

	if "is_dead" in _enemy_hp_target and bool(_enemy_hp_target.is_dead):
		_enemy_hp_tooltip.visible = false
		_enemy_hp_target = null
		return

	var cur := 0.0
	var _mx := 1.0
	var dmg := 0.0
	if "current_health" in _enemy_hp_target:
		cur = float(_enemy_hp_target.current_health)
	if "max_health" in _enemy_hp_target:
		_mx = max(1.0, float(_enemy_hp_target.max_health))
	if "mob_damage" in _enemy_hp_target:
		dmg = float(_enemy_hp_target.mob_damage)

	if _enemy_hp_label:
		_enemy_hp_label.text = "%d" % int(round(cur))
	if _enemy_dmg_label:
		_enemy_dmg_label.text = "%d" % int(round(dmg))

	if cur <= 0.0:
		_enemy_hp_tooltip.visible = false
		_enemy_hp_target = null

func _update_hero_hp_tooltip() -> void:
	if _hero_hp_tooltip == null or _hero_hp_target == null:
		return
	if not is_instance_valid(_hero_hp_target):
		_hero_hp_tooltip.visible = false
		_hero_hp_target = null
		return

	if "is_dead" in _hero_hp_target and bool(_hero_hp_target.is_dead):
		_hero_hp_tooltip.visible = false
		_hero_hp_target = null
		return

	var cur := 0.0
	var _mx := 1.0
	var dmg := 0.0

	if _hero_hp_target.has_method("get_current_hp"):
		cur = float(_hero_hp_target.call("get_current_hp"))
	elif "current_health" in _hero_hp_target:
		cur = float(_hero_hp_target.current_health)

	if _hero_hp_target.has_method("get_max_hp"):
		_mx = max(1.0, float(_hero_hp_target.call("get_max_hp")))
	elif "max_health" in _hero_hp_target:
		_mx = max(1.0, float(_hero_hp_target.max_health))
	if _hero_hp_target.has_method("get_attack_damage"):
		dmg = float(_hero_hp_target.call("get_attack_damage"))
	elif "damage" in _hero_hp_target:
		dmg = float(_hero_hp_target.damage)

	if _hero_hp_label:
		_hero_hp_label.text = "%d" % int(round(cur))
	if _hero_dmg_label:
		_hero_dmg_label.text = "%d" % int(round(dmg))

	if cur <= 0.0:
		_hero_hp_tooltip.visible = false
		_hero_hp_target = null

func _on_enemy_hp_target_tree_exited(mob: Node) -> void:
	hide_enemy_hp_tooltip(mob)

func _on_enemy_hp_target_died(mob: Node) -> void:
	hide_enemy_hp_tooltip(mob)

func _on_hero_hp_target_tree_exited(hero: Node) -> void:
	hide_hero_hp_tooltip(hero)
