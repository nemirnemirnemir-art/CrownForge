extends RefCounted
class_name MainUIHeroHire

const HireInfoPanelScene = preload("res://scenes/ui/hire/HireInfoPanel.tscn")

const MAX_HEROES_PER_PAGE := 6

var _parent: Control = null
var _page: int = 0
var _focus_hero_id: String = ""
var _hire_info_panel: HireInfoPanel = null

var _prev_button: TextureButton = null
var _next_button: TextureButton = null

func initialize(parent: Control, prev_button: TextureButton, next_button: TextureButton) -> void:
	_parent = parent
	_prev_button = prev_button
	_next_button = next_button
	
	if _prev_button and not _prev_button.pressed.is_connected(_on_prev_pressed):
		_prev_button.pressed.connect(_on_prev_pressed)
	if _next_button and not _next_button.pressed.is_connected(_on_next_pressed):
		_next_button.pressed.connect(_on_next_pressed)

func setup_hero_list() -> void:
	var container = _parent.find_child("UpgradeList", true, false)
	if not container:
		return
	
	for child in container.get_children():
		child.queue_free()
	
	var item_scene = load("res://scenes/ui/hire/HeroHireItem.tscn")
	if not item_scene:
		return

	var hero_ids = HeroCore.query.get_all_hero_ids()
	hero_ids.sort_custom(func(a, b): return HeroCore.query.get_hero_cost(a) < HeroCore.query.get_hero_cost(b))

	var total_pages: int = int(ceil(float(hero_ids.size()) / float(MAX_HEROES_PER_PAGE)))
	if total_pages <= 0:
		total_pages = 1

	if _page < 0:
		_page = 0
	if _page >= total_pages:
		_page = max(0, total_pages - 1)

	var start_index: int = _page * MAX_HEROES_PER_PAGE
	var end_index: int = min(start_index + MAX_HEROES_PER_PAGE, hero_ids.size())
	if start_index < hero_ids.size():
		hero_ids = hero_ids.slice(start_index, end_index)
	else:
		hero_ids = []
	
	for h_id in hero_ids:
		var item = item_scene.instantiate()
		container.add_child(item)
		
		var icon_path = HeroAssetLoader.get_hero_icon_path(h_id)
		var h_name = HeroCore.query.get_hero_name(h_id)
		var h_cost = HeroCore.query.get_hero_cost(h_id)
		
		item.setup(h_id, h_name, h_cost, icon_path)
		item.hire_requested.connect(_on_hero_hire_requested)
		var can_afford: bool = EconomyCore.get_gold() >= h_cost
		if item.has_method("update_status"):
			item.update_status(false, can_afford)

	_apply_focus_visuals()
	_update_nav_buttons(total_pages)

func update_hero_costs() -> void:
	var container = _parent.find_child("UpgradeList", true, false)
	if not container:
		return
	
	for child in container.get_children():
		if child.has_method("update_status"):
			var h_id = child._hero_id
			if HeroCore.query.has_hero(h_id):
				var hero_cost = HeroCore.query.get_hero_cost(h_id)
				var can_afford = EconomyCore.get_gold() >= hero_cost
				child.update_status(false, can_afford)
			else:
				child.update_status(false, false)

func fix_next_button_visual() -> void:
	if not _next_button:
		return
	_next_button.scale = Vector2(-1, 1)
	_next_button.call_deferred("set", "pivot_offset", Vector2(20, 20))

func _on_prev_pressed() -> void:
	if _page <= 0:
		return
	_page -= 1
	setup_hero_list()

func _on_next_pressed() -> void:
	_page += 1
	setup_hero_list()

func _on_hero_hire_requested(hero_id: String) -> void:
	if hero_id == "":
		return

	if hero_id != _focus_hero_id:
		_set_focus(hero_id)
		return

	if HeroCore.hire_hero_copy(hero_id):
		update_hero_costs()
		_set_focus("")

func _set_focus(hero_id: String) -> void:
	_focus_hero_id = hero_id
	_ensure_info_panel()

	if _hire_info_panel:
		if hero_id != "" and HeroCore and HeroCore.query.has_hero(hero_id):
			var h_name := HeroCore.query.get_hero_name(hero_id)
			var h_cost := int(HeroCore.query.get_hero_cost(hero_id))
			_hire_info_panel.set_text("%s — %d G" % [h_name, h_cost])
		else:
			_hire_info_panel.set_text("")

	_apply_focus_visuals()

func _ensure_info_panel() -> void:
	if _hire_info_panel != null and is_instance_valid(_hire_info_panel):
		return

	var hire_menu := _parent.find_child("HireMenu", true, false)
	if hire_menu == null:
		return

	var existing := hire_menu.get_node_or_null("HireInfoPanel")
	if existing:
		if existing is HireInfoPanel:
			_hire_info_panel = existing
		else:
			existing.queue_free()
			_hire_info_panel = HireInfoPanelScene.instantiate()
			hire_menu.add_child(_hire_info_panel)
	else:
		_hire_info_panel = HireInfoPanelScene.instantiate()
		hire_menu.add_child(_hire_info_panel)

func _apply_focus_visuals() -> void:
	var container = _parent.find_child("UpgradeList", true, false)
	if container == null:
		return
	for child in container.get_children():
		if not (child is TextureButton):
			continue
		var is_focused := false
		if child.has_method("get_hero_id"):
			is_focused = str(child.get_hero_id()) == _focus_hero_id
		elif child.has_meta("hero_id"):
			is_focused = str(child.get_meta("hero_id")) == _focus_hero_id
		if child.has_method("set_focused"):
			child.set_focused(is_focused)
		else:
			child.modulate = Color(1, 1, 1, 1) if not is_focused else Color(1, 1, 0.8, 1)

func _update_nav_buttons(total_pages: int) -> void:
	if _prev_button:
		_prev_button.disabled = (_page <= 0)
	if _next_button:
		_next_button.disabled = (_page >= total_pages - 1)
