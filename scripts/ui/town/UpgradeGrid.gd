extends Control
class_name UpgradeGrid

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/town/UpgradeSlot.tscn")

@onready var grid: GridContainer = $Grid

var building_id: String = ""

func _ready() -> void:
	TownCore.building_upgraded.connect(_on_building_upgraded)
	_refresh_slots()

func setup(id: String) -> void:
	building_id = id
	_refresh_slots()

func _refresh_slots() -> void:
	if building_id == "":
		return

	for child in grid.get_children():
		child.queue_free()

	var data = TownCore.get_building_config(building_id)
	if not data:
		return

	var perks = data.unlocked_perks.duplicate()
	perks.sort_custom(Callable(self, "_sort_perk_entries"))

	var level = TownCore.get_building_level(building_id)
	for entry in perks:
		var required_level = int(entry.get("level", 0))
		var perk_id = str(entry.get("perk_id", ""))
		var slot = SLOT_SCENE.instantiate() as UpgradeSlot
		if slot:
			grid.add_child(slot)
			# Вызываем setup() после добавления в дерево, чтобы @onready переменные были инициализированы
			var perk_data = HeroCore.get_perk_data(perk_id)
			slot.setup(perk_data, required_level, level >= required_level)

func _sort_perk_entries(a: Dictionary, b: Dictionary) -> int:
	return int(a.get("level", 0)) - int(b.get("level", 0))

func _on_building_upgraded(building: String, _level: int) -> void:
	if building == building_id:
		_refresh_slots()

func _exit_tree() -> void:
	TownCore.building_upgraded.disconnect(_on_building_upgraded)
