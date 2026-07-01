extends Control
class_name BuildingCard

## UI Component to display a single building's status

@onready var icon_rect: TextureRect = $Panel/Content/Icon
@onready var name_label: Label = $Panel/Content/NameLabel
@onready var level_label: Label = $Panel/Content/LevelLabel
@onready var upgrade_btn: Button = $Panel/Content/UpgradeButton

var building_id: String = ""

signal upgrade_requested(building_id: String)

func _get_autoload(name: String) -> Node:
	return get_node_or_null("/root/%s" % name)

func _town_core() -> Node:
	return _get_autoload("TownCore")

func _ready() -> void:
	if upgrade_btn:
		upgrade_btn.pressed.connect(_on_upgrade_pressed)
	var town_core: Node = _town_core()
	if town_core != null and town_core.has_signal("building_upgraded"):
		town_core.connect("building_upgraded", Callable(self, "_on_building_upgraded"))

func _exit_tree() -> void:
	var town_core: Node = _town_core()
	var callback := Callable(self, "_on_building_upgraded")
	if town_core != null and town_core.has_signal("building_upgraded") and town_core.is_connected("building_upgraded", callback):
		town_core.disconnect("building_upgraded", callback)

func setup(id: String) -> void:
	building_id = id
	update_display()

func update_display() -> void:
	if building_id == "": return
	
	# Проверяем, что все узлы инициализированы
	if not level_label or not name_label or not icon_rect:
		# print("[BuildingCard] Warning: Some UI nodes are not initialized")
		return
	
	# Get data from TownCore (assuming we can access registry or helper)
	# Since registry is private, we might need a helper in TownCore or just use what we have.
	# TownCore.get_building_level(id) is public.
	# We need static data (name, icon). TownCore doesn't expose registry publicly.
	# We should add `TownCore.get_building_data(id)` or similar.
	# For now, let's assume we can get it or add the method.

	var town_core: Node = _town_core()
	if town_core == null:
		return

	var level: int = int(town_core.call("get_building_level", building_id))
	level_label.text = "Lvl %d" % level

	# For static data, we might need to load it here or ask TownCore.
	# Let's add `get_building_config(id)` to TownCore to return the Resource.
	var data: BuildingData = town_core.call("get_building_config", building_id) as BuildingData
	if data:
		name_label.text = data.display_name
		if data.icon:
			icon_rect.texture = data.icon
	else:
		name_label.text = building_id.capitalize()

func _on_upgrade_pressed() -> void:
	upgrade_requested.emit(building_id)

func _on_building_upgraded(building: String, _level: int) -> void:
	if building == building_id:
		update_display()
