extends Control
class_name PerksTestPanel

## Test panel to display all available perks

@onready var close_button: Button = $Panel/VBoxContainer/Header/CloseButton
@onready var perks_container: GridContainer = $Panel/VBoxContainer/ScrollContainer/PerksGrid

func _ready() -> void:
	hide()
	if close_button:
		close_button.pressed.connect(hide)
	_load_all_perks()

func _load_all_perks() -> void:
	if not perks_container:
		return
	
	# Clear existing
	for child in perks_container.get_children():
		child.queue_free()
	
	# Load all perk files from data/perks/
	var dir = DirAccess.open("res://data/perks/")
	if not dir:
		# print("[PerksTestPanel] Failed to open data/perks/ directory")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	var perk_resources: Array[PerkData] = []
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path = "res://data/perks/" + file_name
			var resource = load(path) as PerkData
			if resource:
				perk_resources.append(resource)
		file_name = dir.get_next()
	
	# Sort by display_name
	perk_resources.sort_custom(func(a, b): return a.display_name < b.display_name)
	
	# Create UI for each perk
	# print("[PerksTestPanel] Found %d perks" % perk_resources.size())
	for perk_data in perk_resources:
		_create_perk_icon(perk_data)
	# print("[PerksTestPanel] Created %d perk icons" % perks_container.get_child_count())

func _create_perk_icon(perk_data: PerkData) -> void:
	# Panel with colored background (like in HeroCard)
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(32, 32)
	
	# Green background for positive perks
	var style = StyleBoxFlat.new()
	if perk_data.is_positive:
		style.bg_color = Color(0.2, 0.8, 0.2, 1.0)  # Green
	else:
		style.bg_color = Color(0.8, 0.2, 0.2, 1.0)  # Red
	panel.add_theme_stylebox_override("panel", style)
	
	# Icon 25x25 (same as hero stats)
	var icon = TextureRect.new()
	icon.texture = perk_data.icon
	icon.custom_minimum_size = Vector2(25, 25)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.tooltip_text = "%s\n%s" % [perk_data.display_name, perk_data.description]
	
	# Center icon in panel
	icon.anchor_left = 0.5
	icon.anchor_top = 0.5
	icon.anchor_right = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_left = -12
	icon.offset_top = -12
	icon.offset_right = 12
	icon.offset_bottom = 12
	
	panel.add_child(icon)
	perks_container.add_child(panel)

func open() -> void:
	# print("[PerksTestPanel] Opening panel...")
	show()
	# print("[PerksTestPanel] Panel visible: ", visible)

